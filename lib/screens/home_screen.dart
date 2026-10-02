import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_checker.dart';
import '../screens/motor_insurance_calculator.dart';
import '../screens/fire_insurance_calculator.dart';
import '../screens/overseas_mediclaim_calculator.dart';
import '../widgets/calculator_card.dart';
import '../screens/history_screen.dart';
import '../widgets/desktop_app_shell.dart';

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
      context,
      widget.scaffoldMessengerKey,
    );
    if (!updated && mounted) {
      final theme = Theme.of(context);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "You are using the latest version!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 13,
            ),
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
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  minHeight: 120,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Version: $_appVersion"),
                      const SizedBox(height: 10),
                      const Text(
                        "Quick Insure is your trusted insurance partner.",
                      ),
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
                  primary: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Version: $_appVersion"),
                      const SizedBox(height: 10),
                      const Text(
                        "Quick Insure is your trusted insurance partner.",
                      ),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (changelog != null && changelog.trim().isNotEmpty)
                        MarkdownBody(
                          data: _updateChecker.removeReleaseHeading(
                            changelog,
                            _appVersion,
                          ),
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

  // Kept for calculators that are not implemented yet, so a card can be wired
  // back to a "coming soon" dialog at any time.
  // ignore: unused_element
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
                "This calculator is currently under construction. We're working hard to bring this feature to you soon!",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it"),
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
    final mediaSize = MediaQuery.sizeOf(context);
    final platform = Theme.of(context).platform;
    final isDesktopPlatform = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
    if (isDesktopPlatform || mediaSize.shortestSide >= 600) {
      return DesktopAppShell(
        onToggleDarkMode: widget.onToggleDarkMode,
        darkMode: widget.darkMode,
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
      );
    }

    return Scaffold(
      floatingActionButton: null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) {
          final isEntering = (child.key as ValueKey<int>).value == _selectedTab;
          final direction = _selectedTab == 1 ? 1.0 : -1.0;
          final beginX = (isEntering ? direction : -direction) * 0.035;
          final slide = Tween<Offset>(
            begin: Offset(beginX, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedTab),
          child: _selectedTab == 1
              ? const HistoryScreen()
              : Scaffold(
                  appBar: AppBar(
                    title: const Text('Quick Insure'),
                    actions: [
                      IconButton(
                        tooltip: widget.darkMode ? 'Light mode' : 'Dark mode',
                        icon: Icon(
                          widget.darkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        onPressed: widget.onToggleDarkMode,
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'More options',
                        onSelected: (action) {
                          if (action == 'updates') _checkForUpdate();
                          if (action == 'about') _openAboutDialog(context);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'updates',
                            child: Text('Check for updates'),
                          ),
                          PopupMenuItem(
                            value: 'about',
                            child: Text('About Quick Insure'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 8.0,
                      ),
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
                                icon: Icons.medical_services,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OverseasMediclaimCalculator(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
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
        ],
      ),
    );
  }
}
