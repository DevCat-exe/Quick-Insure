import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/app_snackbar.dart';

/// The kind of Windows download that a release offers.
enum _WindowsUpdateKind { none, bundle, installer }

class UpdateChecker {
  static const String _testReleaseTag =
      String.fromEnvironment('QUICK_INSURE_TEST_RELEASE_TAG');

  final String githubRepo = "DevCat-exe/Quick-Insure";
  String get latestReleaseUrl =>
      "https://github.com/$githubRepo/releases/latest";

  Future<bool> checkForUpdate(BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) async {
    final theme = Theme.of(context);
    final messenger = scaffoldMessengerKey.currentState;

    if (messenger == null) return false;

    messenger.showSnackBar(
      appSnackBar(
        context,
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
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final releaseEndpoint = _testReleaseTag.isEmpty
          ? "https://api.github.com/repos/$githubRepo/releases/latest"
          : "https://api.github.com/repos/$githubRepo/releases/tags/${Uri.encodeComponent(_testReleaseTag)}";
      final response = await http.get(Uri.parse(releaseEndpoint));

      messenger.hideCurrentSnackBar();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion =
            (data["tag_name"] as String?)?.replaceFirst(RegExp(r'^v'), '') ??
                "0.0.0";
        final List<dynamic> assets = data["assets"] as List<dynamic>;
        final changelog = data["body"] as String?;

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          final isAndroid =
              !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
          final isWindows =
              !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
          final releaseAssets = assets.cast<Map<String, dynamic>?>();
          final apkAsset = releaseAssets.firstWhere(
            (asset) =>
                asset?['name'] is String &&
                (asset!['name'] as String).toLowerCase().endsWith('.apk'),
            orElse: () => null,
          );
          final windowsBundle = releaseAssets.firstWhere(
            (asset) =>
                asset?['name'] is String &&
                (asset!['name'] as String).toLowerCase() ==
                    'quick_insure_windows.zip',
            orElse: () => null,
          );
          final windowsSetup = releaseAssets.firstWhere(
            (asset) =>
                asset?['name'] is String &&
                (asset!['name'] as String).toLowerCase() ==
                    'quick_insure_windows_setup.exe',
            orElse: () => null,
          );
          final isAndroidApk = isAndroid && apkAsset != null;
          // The installer can elevate, so it is used when Quick Insure cannot
          // replace its own files. Writable installs keep the lighter bundle.
          final isWindowsSetup = isWindows &&
              windowsSetup != null &&
              (windowsBundle == null || !await _canWriteToInstallDirectory());
          final isWindowsBundle =
              isWindows && !isWindowsSetup && windowsBundle != null;
          final windowsUpdateKind = isWindowsSetup
              ? _WindowsUpdateKind.installer
              : isWindowsBundle
                  ? _WindowsUpdateKind.bundle
                  : _WindowsUpdateKind.none;
          final selectedAsset = isAndroidApk
              ? apkAsset
              : isWindowsSetup
                  ? windowsSetup
                  : isWindowsBundle
                      ? windowsBundle
                      : null;
          final downloadUrl = selectedAsset == null
              ? latestReleaseUrl
              : selectedAsset['browser_download_url'] as String;
          if (context.mounted) {
            _showUpdateChangelogDialog(
              context,
              changelog,
              downloadUrl,
              latestVersion,
              isAndroidApk
                  ? 'Download APK'
                  : windowsUpdateKind != _WindowsUpdateKind.none
                      ? 'Install Update'
                      : 'View Release',
              isAndroidApk: isAndroidApk,
              windowsUpdateKind: windowsUpdateKind,
              scaffoldMessengerKey: scaffoldMessengerKey,
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
        appSnackBar(
          context,
          content: Text(
            "Network error. Please check your connection.",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint("Update check failed: $e");
    }
    return false;
  }

  bool _isNewerVersion(String latest, String current) {
    String numericVersion(String version) =>
        version.replaceFirst(RegExp(r'^v'), '').split(RegExp(r'[-+]')).first;

    final latestParts =
        numericVersion(latest).split('.').map(int.parse).toList();
    final currentParts =
        numericVersion(current).split('.').map(int.parse).toList();

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
    String actionLabel, {
    required bool isAndroidApk,
    required _WindowsUpdateKind windowsUpdateKind,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 700.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text("Update Available!"),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: screenHeight * 0.45,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              primary: true,
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
                      data: removeReleaseHeading(changelog, newVersion),
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (isAndroidApk) {
                await _downloadAndInstallAndroidApk(
                  context,
                  releaseUrl,
                  newVersion,
                  scaffoldMessengerKey,
                );
              } else if (windowsUpdateKind == _WindowsUpdateKind.installer) {
                await _downloadAndInstallWindowsInstaller(
                  context,
                  releaseUrl,
                  newVersion,
                  scaffoldMessengerKey,
                );
              } else if (windowsUpdateKind == _WindowsUpdateKind.bundle) {
                await _downloadAndInstallWindowsBundle(
                  context,
                  releaseUrl,
                  newVersion,
                  scaffoldMessengerKey,
                );
              } else {
                await launchUrl(Uri.parse(releaseUrl),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String removeReleaseHeading(String markdown, String version) {
    final lines = markdown.split('\n');
    final firstContentIndex =
        lines.indexWhere((line) => line.trim().isNotEmpty);
    if (firstContentIndex < 0) return markdown;

    final heading = lines[firstContentIndex].trim();
    final cleanVersion =
        version.split('+').first.replaceFirst(RegExp(r'^v'), '');
    if (heading.contains(cleanVersion) &&
        (heading.startsWith('#') || heading.startsWith('['))) {
      lines.removeAt(firstContentIndex);
      if (firstContentIndex < lines.length &&
          lines[firstContentIndex].trim().isEmpty) {
        lines.removeAt(firstContentIndex);
      }
      return lines.join('\n').trim();
    }
    return markdown;
  }

  Future<void> _downloadAndInstallAndroidApk(
    BuildContext context,
    String downloadUrl,
    String version,
    GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  ) async {
    final progress = ValueNotifier<double?>(null);
    final client = http.Client();
    final dialogNavigator = Navigator.of(context, rootNavigator: true);
    var progressDialogOpen = false;

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Downloading update'),
            content: SizedBox(
              width: 320,
              child: ValueListenableBuilder<double?>(
                valueListenable: progress,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: value),
                    const SizedBox(height: 12),
                    Text(
                      value == null
                          ? 'Downloading Quick Insure v$version...'
                          : 'Downloaded ${(value * 100).round()}%',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Android will ask you to approve the installation.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      progressDialogOpen = true;

      final response = await client.send(
        http.Request('GET', Uri.parse(downloadUrl)),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('APK download failed (${response.statusCode}).');
      }

      final totalBytes = response.contentLength;
      final directory = await getApplicationSupportDirectory();
      final safeVersion = version.replaceAll(RegExp(r'[^0-9A-Za-z.-]'), '_');
      final partialFile =
          File('${directory.path}/quick_insure_$safeVersion.apk.part');
      final apkFile = File('${directory.path}/quick_insure_$safeVersion.apk');
      if (await partialFile.exists()) await partialFile.delete();

      final sink = partialFile.openWrite();
      try {
        var receivedBytes = 0;
        await for (final chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes != null && totalBytes > 0) {
            progress.value = receivedBytes / totalBytes;
          }
        }
      } finally {
        await sink.close();
      }

      if (await apkFile.exists()) await apkFile.delete();
      await partialFile.rename(apkFile.path);

      if (!dialogNavigator.mounted) return;
      dialogNavigator.pop();
      progressDialogOpen = false;
      await OpenFilex.open(apkFile.path);
    } catch (error) {
      debugPrint('APK update failed: $error');
      if (progressDialogOpen && dialogNavigator.mounted) {
        dialogNavigator.pop();
      }
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          appSnackBar(
            context,
            content: const Text(
              'Could not download the update. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      client.close();
      progress.dispose();
    }
  }

  /// Whether Quick Insure can replace the files it was started from.
  Future<bool> _canWriteToInstallDirectory() async {
    try {
      final directory = File(Platform.resolvedExecutable).parent;
      final probe = File(
        '${directory.path}/.quick-insure-update-${pid.toString()}',
      );
      await probe.writeAsString('');
      await probe.delete();
      return true;
    } catch (error) {
      debugPrint('Install directory is not writable: $error');
      return false;
    }
  }

  Future<void> _downloadAndInstallWindowsBundle(
    BuildContext context,
    String downloadUrl,
    String version,
    GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  ) async {
    final executable = File(Platform.resolvedExecutable);
    final installDirectory = executable.parent;
    final progress = ValueNotifier<double?>(null);
    final client = http.Client();
    final dialogNavigator = Navigator.of(context, rootNavigator: true);
    var progressDialogOpen = false;
    File? partialArchive;

    try {
      if (!await _canWriteToInstallDirectory()) {
        throw Exception(
          'Quick Insure cannot write to ${installDirectory.path}.',
        );
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Downloading desktop update'),
            content: SizedBox(
              width: 320,
              child: ValueListenableBuilder<double?>(
                valueListenable: progress,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: value),
                    const SizedBox(height: 12),
                    Text(
                      value == null
                          ? 'Downloading Quick Insure v$version...'
                          : 'Downloaded ${(value * 100).round()}%',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The app will close and reopen to finish installing.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      progressDialogOpen = true;

      final response = await client.send(
        http.Request('GET', Uri.parse(downloadUrl)),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
            'Windows update download failed (${response.statusCode}).');
      }

      final tempDirectory = await getTemporaryDirectory();
      final safeVersion = version.replaceAll(RegExp(r'[^0-9A-Za-z.-]'), '_');
      partialArchive = File(
        '${tempDirectory.path}/quick_insure_windows_$safeVersion.zip.part',
      );
      final archive = File(
        '${tempDirectory.path}/quick_insure_windows_$safeVersion.zip',
      );
      if (await partialArchive.exists()) await partialArchive.delete();

      final sink = partialArchive.openWrite();
      try {
        var receivedBytes = 0;
        await for (final chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (response.contentLength case final totalBytes?
              when totalBytes > 0) {
            progress.value = receivedBytes / totalBytes;
          }
        }
      } finally {
        await sink.close();
      }
      if (await archive.exists()) await archive.delete();
      await partialArchive.rename(archive.path);
      partialArchive = null;

      final script = File('${tempDirectory.path}/quick_insure_update.ps1');
      await script.writeAsString(r'''
param(
  [int]$ProcessId,
  [string]$ArchivePath,
  [string]$InstallDirectory,
  [string]$ExecutablePath,
  [string]$TempDirectory
)
$ErrorActionPreference = 'Stop'
$StageDirectory = Join-Path $TempDirectory ('quick-insure-stage-' + [guid]::NewGuid())
try {
  Wait-Process -Id $ProcessId -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Path $StageDirectory -Force | Out-Null
  Expand-Archive -LiteralPath $ArchivePath -DestinationPath $StageDirectory -Force
  $ExecutableName = [System.IO.Path]::GetFileName($ExecutablePath)
  $UpdatedExecutable = Get-ChildItem -LiteralPath $StageDirectory -Filter $ExecutableName -File -Recurse | Select-Object -First 1
  if ($null -eq $UpdatedExecutable) { throw "Update bundle does not contain $ExecutableName." }
  Get-ChildItem -LiteralPath $UpdatedExecutable.DirectoryName -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $InstallDirectory -Recurse -Force
  }
  Start-Process -FilePath $ExecutablePath -WorkingDirectory $InstallDirectory
} catch {
  $Message = "Quick Insure could not finish updating: $($_.Exception.Message)"
  try {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($Message, 'Quick Insure update failed', 'OK', 'Error') | Out-Null
  } catch {}
} finally {
  Remove-Item -LiteralPath $StageDirectory -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
}
''');

      final installDialogNavigator = dialogNavigator;
      if (!installDialogNavigator.mounted) return;
      installDialogNavigator.pop();
      progressDialogOpen = false;

      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-WindowStyle',
          'Hidden',
          '-File',
          script.path,
          pid.toString(),
          archive.path,
          installDirectory.path,
          executable.path,
          tempDirectory.path,
        ],
        mode: ProcessStartMode.detached,
      );
      await windowManager.close();
    } catch (error) {
      debugPrint('Windows update failed: $error');
      if (partialArchive != null && await partialArchive.exists()) {
        await partialArchive.delete();
      }
      if (progressDialogOpen && dialogNavigator.mounted) {
        dialogNavigator.pop();
      }
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          appSnackBar(
            context,
            content: const Text(
              'Could not update here. Move Quick Insure to a writable folder and try again.',
            ),
          ),
        );
      }
    } finally {
      client.close();
      progress.dispose();
    }
  }

  Future<void> _downloadAndInstallWindowsInstaller(
    BuildContext context,
    String downloadUrl,
    String version,
    GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  ) async {
    final executable = File(Platform.resolvedExecutable);
    final installDirectory = executable.parent;
    final progress = ValueNotifier<double?>(null);
    final client = http.Client();
    final dialogNavigator = Navigator.of(context, rootNavigator: true);
    var progressDialogOpen = false;
    File? partialInstaller;

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Downloading desktop update'),
            content: SizedBox(
              width: 320,
              child: ValueListenableBuilder<double?>(
                valueListenable: progress,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: value),
                    const SizedBox(height: 12),
                    Text(
                      value == null
                          ? 'Downloading Quick Insure v$version...'
                          : 'Downloaded ${(value * 100).round()}%',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Windows asks for permission before installing, then '
                      'Quick Insure reopens.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      progressDialogOpen = true;

      final response = await client.send(
        http.Request('GET', Uri.parse(downloadUrl)),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
            'Windows installer download failed (${response.statusCode}).');
      }

      final tempDirectory = await getTemporaryDirectory();
      partialInstaller = File(
        '${tempDirectory.path}/quick_insure_windows_setup.exe.part',
      );
      final installer = File(
        '${tempDirectory.path}/quick_insure_windows_setup.exe',
      );
      if (await partialInstaller.exists()) await partialInstaller.delete();

      final sink = partialInstaller.openWrite();
      try {
        var receivedBytes = 0;
        await for (final chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (response.contentLength case final totalBytes?
              when totalBytes > 0) {
            progress.value = receivedBytes / totalBytes;
          }
        }
      } finally {
        await sink.close();
      }
      if (await installer.exists()) await installer.delete();
      await partialInstaller.rename(installer.path);
      partialInstaller = null;

      final script = File('${tempDirectory.path}/quick_insure_update.ps1');
      await script.writeAsString(r'''
param(
  [int]$ProcessId,
  [string]$InstallerPath,
  [string]$InstallDirectory,
  [string]$ExecutablePath
)
$ErrorActionPreference = 'Stop'
$InstallerName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerPath)
$ExitCode = 1
try {
  Wait-Process -Id $ProcessId -ErrorAction SilentlyContinue
  try {
    $SetupProcess = Start-Process -FilePath $InstallerPath -ArgumentList "/SILENT /NORESTART /DIR=`"$InstallDirectory`"" -PassThru
    if ($null -ne $SetupProcess) { $SetupProcess.WaitForExit() }
    $Deadline = (Get-Date).AddMinutes(10)
    while ((Get-Process -Name $InstallerName -ErrorAction SilentlyContinue) -and ((Get-Date) -lt $Deadline)) {
      Start-Sleep -Seconds 1
    }
    if ($null -ne $SetupProcess -and $SetupProcess.HasExited) { $ExitCode = $SetupProcess.ExitCode } else { $ExitCode = 0 }
  } catch {
    $ExitCode = 1
  }
  Start-Sleep -Seconds 3
  if (-not (Get-Process -Name 'quick_insure' -ErrorAction SilentlyContinue)) {
    if (Test-Path -LiteralPath $ExecutablePath) {
      Start-Process -FilePath $ExecutablePath -WorkingDirectory $InstallDirectory
    }
  }
  if ($ExitCode -ne 0) {
    $Message = 'Quick Insure could not finish updating. Run the installer again from the release page.'
    try {
      Add-Type -AssemblyName PresentationFramework
      [System.Windows.MessageBox]::Show($Message, 'Quick Insure update failed', 'OK', 'Error') | Out-Null
    } catch {}
  }
} catch {
  $Message = "Quick Insure could not finish updating: $($_.Exception.Message)"
  try {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($Message, 'Quick Insure update failed', 'OK', 'Error') | Out-Null
  } catch {}
} finally {
  Remove-Item -LiteralPath $InstallerPath -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
}
''');

      final installDialogNavigator = dialogNavigator;
      if (!installDialogNavigator.mounted) return;
      installDialogNavigator.pop();
      progressDialogOpen = false;

      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-WindowStyle',
          'Hidden',
          '-File',
          script.path,
          pid.toString(),
          installer.path,
          installDirectory.path,
          executable.path,
        ],
        mode: ProcessStartMode.detached,
      );
      await windowManager.close();
    } catch (error) {
      debugPrint('Windows installer update failed: $error');
      if (partialInstaller != null && await partialInstaller.exists()) {
        await partialInstaller.delete();
      }
      if (progressDialogOpen && dialogNavigator.mounted) {
        dialogNavigator.pop();
      }
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          appSnackBar(
            context,
            content: const Text(
              'Could not download the update. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      client.close();
      progress.dispose();
    }
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
