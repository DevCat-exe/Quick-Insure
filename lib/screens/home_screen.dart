import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_checker.dart';
import '../screens/motor_insurance_calculator.dart';
import '../screens/fire_insurance_calculator.dart';
import '../widgets/calculator_card.dart';
import '../screens/history_screen.dart';
import '../widgets/desktop_app_shell.dart';
import '../services/history_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool darkMode;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  const HomeScreen({
    super.key,
    required this.onToggleDarkMode,
    required this.darkMode,
    required this.scaffoldMessengerKey,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _appVersion = "1.0.0";
  int _selectedTab = 0;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setStatusBar();
  }

  Future<void> _setStatusBar() async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).colorScheme.primary,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    bool updated = await _updateChecker.checkForUpdate(
        context, widget.scaffoldMessengerKey);
    if (!updated && mounted) {
      final theme = Theme.of(context);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "You are using the latest version!",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.95;

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
              title: const Text("About Quick Insure"),
              content: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: dialogWidth, minHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Version: $_appVersion"),
                      const SizedBox(height: 10),
                      const Text(
                          "Quick Insure is your trusted insurance partner."),
                      const SizedBox(height: 18),
                      Text(
                        "Changelog:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Error loading changelog: ${snapshot.error}",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          }
          return AlertDialog(
            title: const Text("About Quick Insure"),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                maxHeight: screenHeight * 0.5,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Version: $_appVersion"),
                      const SizedBox(height: 10),
                      const Text(
                          "Quick Insure is your trusted insurance partner."),
                      const SizedBox(height: 18),
                      Text(
                        "Changelog:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else if (changelog != null && changelog.trim().isNotEmpty)
                        MarkdownBody(
                          data: changelog,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 13),
                            h2: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          "No changelog found for this version.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
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

  Widget _buildSettingsPanel() {
    return ListView(
      children: [
        SwitchListTile(
          secondary: Icon(
            widget.darkMode
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
          ),
          title: const Text('Dark mode'),
          value: widget.darkMode,
          onChanged: (_) => widget.onToggleDarkMode(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.system_update_alt_outlined),
          title: const Text('Check for updates'),
          onTap: _checkForUpdate,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About Quick Insure'),
          onTap: () => _openAboutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: const Text('Clear calculation history'),
          onTap: _confirmClearHistory,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Version $_appVersion',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear calculation history?'),
        content: const Text('This permanently deletes all saved calculations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService.clearHistory();
      if (mounted) {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Calculation history cleared.')),
        );
      }
    }
  }

  void _showComingSoonPopup(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: theme.dialogTheme.backgroundColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 100 : 40),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accent.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: accent, size: 56),
              ),
              const SizedBox(height: 24),
              Text(
                "Coming Soon",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "The Overseas Mediclaim Calculator is currently under construction. We're working hard to bring this feature to you soon!",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it!"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 850) {
      return DesktopAppShell(
        onToggleDarkMode: widget.onToggleDarkMode,
        darkMode: widget.darkMode,
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
      );
    }

    return Scaffold(
      appBar: _selectedTab == 1
          ? null
          : AppBar(
              title: Text(_selectedTab == 2 ? 'Settings' : 'Quick Insure'),
            ),
      floatingActionButton: null,
      body: _selectedTab == 1
          ? const HistoryScreen()
          : _selectedTab == 2
              ? _buildSettingsPanel()
              : FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isWide = constraints.maxWidth > 600;
                        final isSmallScreen = screenWidth < 380;
                        final crossAxisCount = isWide ? 3 : 2;
                        return GridView.count(
                          padding: EdgeInsets.zero,
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: isSmallScreen ? 16 : 24,
                          childAspectRatio: isSmallScreen ? 0.95 : 1.0,
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
                                        MotorInsuranceCalculator(),
                                  ),
                                );
                              },
                            ),
                            CalculatorCard(
                              title: 'Fire Insurance',
                              icon: Icons.local_fire_department,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FireInsuranceCalculator(),
                                  ),
                                );
                              },
                            ),
                            CalculatorCard(
                              title: 'Overseas Mediclaim',
                              icon: Icons.health_and_safety,
                              onTap: () => _showComingSoonPopup(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
