import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  final String githubRepo = "Mahir9011/Quick-Insure"; // Your GitHub repo

  Future<bool> checkForUpdate(BuildContext context) async {
    try {
      // Get the latest release info from GitHub API
      final response = await http.get(Uri.parse(
          "https://api.github.com/repos/$githubRepo/releases/latest"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion =
            data["tag_name"].replaceAll("v", ""); // Extract version
        final apkUrl = data["assets"][0]["browser_download_url"]; // Get APK URL

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          // ignore: use_build_context_synchronously
          _showUpdateDialog(context, apkUrl);
          return true; // Update available
        }
      }
    } catch (e) {
      print("Update check failed: $e");
    }
    return false; // No update available
  }

  bool _isNewerVersion(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (latestParts[i] > (i < currentParts.length ? currentParts[i] : 0)) {
        return true;
      }
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, String apkUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Available"),
          content: Text(
              "A new version of the app is available. Do you want to update now?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Later"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await launchUrl(Uri.parse(apkUrl),
                    mode: LaunchMode.externalApplication);
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }
}
