import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';


class UpdateChecker {
  final String githubRepo = "DevCat-exe/Quick-Insure";
  String get latestReleaseUrl =>
      "https://github.com/$githubRepo/releases/latest";

  Future<bool> checkForUpdate(BuildContext context, GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) async {
    final theme = Theme.of(context);
    final messenger = scaffoldMessengerKey.currentState;

    if (messenger == null) return false;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 4,
              height: 20,
            ),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Checking for updates...',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final response = await http.get(Uri.parse(
          "https://api.github.com/repos/$githubRepo/releases/latest"));

      messenger.hideCurrentSnackBar();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion =
            (data["tag_name"] as String?)?.replaceAll("v", "") ?? "0.0.0";
        final List<dynamic> assets = data["assets"] as List<dynamic>;
        
        final apkAsset = assets.firstWhere(
          (asset) => (asset["name"] as String).endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset == null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                "Update available but no APK found.",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              duration: const Duration(seconds: 3),
            ),
          );
          return false;
        }
        
        final apkUrl = apkAsset["browser_download_url"] as String;
        final changelog = data["body"] as String?;

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          if (context.mounted) {
            _showUpdateChangelogDialog(context, changelog, apkUrl, latestVersion);
          }
          return true;
        }
        return false;
      }
      return false;
    } catch (e) {
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Network error. Please check your connection.",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint("Update check failed: $e");
    }
    return false;
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

  void _showUpdateChangelogDialog(BuildContext context, String? changelog,
      String apkUrl, String newVersion) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 700.0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Update Available!"),
        content: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("New Version: v$newVersion",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    )),
                SizedBox(height: 8),
                Text("What's new:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (changelog != null && changelog.trim().isNotEmpty)
                   Container(
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.5,
                      minHeight: 80.0,
                    ),
                    child: MarkdownBody(
                      data: changelog,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyMedium,
                        h2: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
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
