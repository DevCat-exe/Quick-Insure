import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateChecker {
  final String githubRepo = "DevCat-exe/Quick-Insure"; // Updated GitHub repo
  String get latestReleaseUrl =>
      "https://github.com/$githubRepo/releases/latest";

  Future<bool> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(
          "https://api.github.com/repos/$githubRepo/releases/latest"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion =
            data["tag_name"].replaceAll("v", ""); // Extract version
        final apkUrl = data["assets"][0]["browser_download_url"];
        final changelog = data["body"] as String?;

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          // ignore: use_build_context_synchronously
          _showUpdateChangelogDialog(context, changelog, apkUrl);
          return true; // Update available
        }
      }
    } catch (e) {
      // debugPrint is preferred for non-production logs
      debugPrint("Update check failed: $e");
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

  void _showUpdateChangelogDialog(
      BuildContext context, String? changelog, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Update Available!"),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What's new:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (changelog != null && changelog.trim().isNotEmpty)
                  MarkdownBody(
                    data: changelog,
                    styleSheet: MarkdownStyleSheet(
                      p: Theme.of(context).textTheme.bodyMedium,
                      h2: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text("No changelog found.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
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
            child: Text("Download Update"),
          ),
        ],
      ),
    );
  }

  Future<String?> fetchLatestChangelog() async {
    try {
      final response = await http.get(Uri.parse(
          "https://api.github.com/repos/$githubRepo/releases/latest"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["body"] as String?;
      }
    } catch (e) {
      debugPrint("Changelog fetch failed: $e");
    }
    return null;
  }

  Future<String?> fetchChangelogForVersion(String version) async {
    try {
      final response = await http
          .get(Uri.parse("https://api.github.com/repos/$githubRepo/releases"));
      if (response.statusCode == 200) {
        final List<dynamic> releases = jsonDecode(response.body);
        for (final release in releases) {
          final tag = (release["tag_name"] as String?)?.replaceAll("v", "");
          if (tag == version) {
            return release["body"] as String?;
          }
        }
      }
    } catch (e) {
      debugPrint("Changelog fetch for version failed: $e");
    }
    return null;
  }
}
