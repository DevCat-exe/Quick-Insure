import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

class UpdateChecker {
  final String githubRepo = "DevCat-exe/Quick-Insure";
  String get latestReleaseUrl =>
      "https://github.com/$githubRepo/releases/latest";

  Future<bool> checkForUpdate(BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) async {
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
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white, fontSize: 13),
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
        final changelog = data["body"] as String?;

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          final isAndroid =
              !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
          final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
                (asset) =>
                    asset?["name"] is String &&
                    (asset!["name"] as String).toLowerCase().endsWith('.apk'),
                orElse: () => null,
              );
          final downloadUrl = isAndroid && apkAsset != null
              ? apkAsset["browser_download_url"] as String
              : latestReleaseUrl;
          if (context.mounted) {
            _showUpdateChangelogDialog(
              context,
              changelog,
              downloadUrl,
              latestVersion,
              isAndroid && apkAsset != null ? "Download APK" : "View Release",
            );
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
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white, fontSize: 13),
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

  void _showUpdateChangelogDialog(
    BuildContext context,
    String? changelog,
    String releaseUrl,
    String newVersion,
    String actionLabel,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 700.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Update Available!"),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: screenHeight * 0.45,
          ),
          child: Scrollbar(
            thumbVisibility: true,
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
                  const SizedBox(height: 8),
                  const Text("What's new:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
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
              await launchUrl(Uri.parse(releaseUrl),
                  mode: LaunchMode.externalApplication);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String? _extractVersionSection(String markdown, String version) {
    final lines = markdown.split('\n');
    final cleanVer = version.replaceAll('v', '').trim();
    int startIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if ((line.startsWith('# ') || line.startsWith('## ')) &&
          (line.contains('[$cleanVer]') ||
              line.contains('v$cleanVer') ||
              line.contains(' $cleanVer'))) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) return null;

    final buffer = StringBuffer();
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      if (i > startIndex && (line.startsWith('# ') || line.startsWith('## '))) {
        break;
      }
      buffer.writeln(line);
    }

    return buffer.toString().trim();
  }

  Future<String?> fetchChangelogForVersion(String version) async {
    final cleanVersion = version.split("+").first.replaceAll("v", "").trim();

    // 1. Instant offline check from bundled asset
    try {
      final localMarkdown = await rootBundle.loadString('assets/CHANGELOG.md');
      final versionSection =
          _extractVersionSection(localMarkdown, cleanVersion);
      if (versionSection != null && versionSection.isNotEmpty) {
        return versionSection;
      }
      if (localMarkdown.isNotEmpty) {
        return localMarkdown;
      }
    } catch (e) {
      debugPrint("Local asset changelog error: $e");
    }

    // 2. Fallback to GitHub Release API
    try {
      final tagResponse = await http.get(Uri.parse(
          "https://api.github.com/repos/$githubRepo/releases/tags/v$cleanVersion"));
      if (tagResponse.statusCode == 200) {
        final data = jsonDecode(tagResponse.body);
        return data["body"] as String?;
      }

      final latestResponse = await http.get(Uri.parse(
          "https://api.github.com/repos/$githubRepo/releases/latest"));
      if (latestResponse.statusCode == 200) {
        final data = jsonDecode(latestResponse.body);
        final tag = (data["tag_name"] as String?)?.replaceAll("v", "") ?? "";
        if (tag == cleanVersion) {
          return data["body"] as String?;
        }
      }
    } catch (e) {
      debugPrint("GitHub changelog fetch failed: $e");
    }
    return null;
  }
}
