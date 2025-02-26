import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  final String _githubRepo = "Mahir9011/Quick-Insure";

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(
          "https://api.github.com/repos/$_githubRepo/releases/latest"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data["tag_name"].replaceAll("v", "");
        final packageInfo = await PackageInfo.fromPlatform();

        if (_isNewerVersion(latestVersion, packageInfo.version)) {
          _showUpdateDialog(context, data["html_url"]);
        } else {
          _showSnackBar(context, "You're up to date!");
        }
      }
    } catch (e) {
      _showSnackBar(context, "Update check failed");
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (latestParts[i] > (i < currentParts.length ? currentParts[i] : 0)) {
        return true;
      }
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Update Available"),
        content: const Text("A newer version is available on GitHub."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          FilledButton(
            onPressed: () => launchUrl(Uri.parse(url)),
            child: const Text("View Update"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
