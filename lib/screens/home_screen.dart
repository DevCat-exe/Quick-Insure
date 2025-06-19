import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_checker.dart';
import '../screens/motor_insurance_calculator.dart';
import '../widgets/calculator_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool darkMode;
  const HomeScreen(
      {super.key, required this.onToggleDarkMode, required this.darkMode});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _appVersion = "1.0.0";
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  final UpdateChecker _updateChecker = UpdateChecker();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _setStatusBar();
  }

  Future<void> _setStatusBar() async {
    await FlutterStatusbarcolor.setStatusBarColor(
        Theme.of(context).colorScheme.primary);
    FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    bool updated = await _updateChecker.checkForUpdate(context);
    if (!updated && mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You are using the latest version!",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _openAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<String?>(
        future: _getCurrentVersionChangelog(),
        builder: (context, snapshot) {
          final changelog = snapshot.data;
          final theme = Theme.of(context);
          if (snapshot.hasError) {
            return AlertDialog(
              title: Text("About Quick Insure"),
              content: SizedBox(
                width: 480,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 120,
                        maxHeight: 420, // Ensures dialog never overflows
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Version: $_appVersion"),
                          SizedBox(height: 10),
                          Text(
                              "Quick Insure is your trusted insurance partner."),
                          SizedBox(height: 18),
                          Text("Changelog:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)),
                          SizedBox(height: 6),
                          Text("Error loading changelog: ",
                              style: TextStyle(color: theme.colorScheme.error)),
                          Text(snapshot.error.toString(),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            );
          }
          return AlertDialog(
            title: Text("About Quick Insure"),
            content: SizedBox(
              width: 480,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Version: $_appVersion"),
                      SizedBox(height: 10),
                      Text("Quick Insure is your trusted insurance partner."),
                      SizedBox(height: 18),
                      Text("Changelog:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary)),
                      SizedBox(height: 6),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Center(child: CircularProgressIndicator(strokeWidth: 2))
                      else if (changelog != null && changelog.trim().isNotEmpty)
                        Container(
                          constraints:
                              BoxConstraints(maxHeight: 320, minHeight: 80),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: MarkdownBody(
                                data: changelog,
                              ),
                            ),
                          ),
                        )
                      else
                        Text("No changelog found for this version.",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _getCurrentVersionChangelog() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    return await _updateChecker.fetchChangelogForVersion(currentVersion);
  }

  void _showComingSoonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.local_fire_department,
                color: Theme.of(context).colorScheme.primary, size: 32),
            SizedBox(width: 12),
            Text("Coming Soon!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Text(
                "The Fire Insurance Calculator is under development. Stay tuned for updates!"),
            SizedBox(height: 16),
            Icon(Icons.construction, color: Colors.orangeAccent, size: 48),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withAlpha(200)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(40),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.shield, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Insure',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(height: 4),
                      Text('v$_appVersion',
                          style:
                              TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.system_update_alt,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('Check Update',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              onTap: _checkForUpdate,
            ),
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('About',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              onTap: () => _openAboutDialog(context),
            ),
            SwitchListTile(
              secondary: Icon(
                widget.darkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('Dark Mode',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              value: widget.darkMode,
              onChanged: (_) => widget.onToggleDarkMode(),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Center(
                child: Text(
                  '© 2025 Quick Insure',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[500]),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Quick Insure'),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Toggle Dark Mode',
            onPressed: widget.onToggleDarkMode,
          ),
        ],
      ),
      floatingActionButton: null,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final crossAxisCount = isWide ? 3 : 2;
              return GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.0, // Make cards perfect squares
                physics: const BouncingScrollPhysics(),
                children: [
                  CalculatorCard(
                    title: 'Motor Insurance',
                    icon: Icons.directions_car,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MotorInsuranceCalculator()));
                    },
                  ),
                  CalculatorCard(
                    title: 'Fire Insurance',
                    icon: Icons.local_fire_department,
                    onTap: () {
                      _showComingSoonPopup(context);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
