import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../screens/motor_insurance_calculator.dart';
import '../screens/fire_insurance_calculator.dart';
import '../screens/history_screen.dart';
import '../services/update_checker.dart';
import 'app_snackbar.dart';

class DesktopAppShell extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool darkMode;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const DesktopAppShell({
    super.key,
    required this.onToggleDarkMode,
    required this.darkMode,
    required this.scaffoldMessengerKey,
  });

  @override
  State<DesktopAppShell> createState() => _DesktopAppShellState();
}

class _DesktopAppShellState extends State<DesktopAppShell> {
  String _selectedSection = 'motor';
  String _appVersion = '2.1.2';
  final UpdateChecker _updateChecker = UpdateChecker();

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = info.version);
      }
    } catch (_) {}
  }

  void _showComingSoonDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome,
                  color: Theme.of(ctx).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(
          "$title module is currently under active development. You will receive an update as soon as the tariff schedule is finalized!",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  void _openAboutDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Text("About Quick Insure"),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Version: v$_appVersion",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    "Quick Insure is a modern desktop and mobile insurance premium calculation suite."),
                const SizedBox(height: 16),
                Text(
                  "Changelog:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: _updateChecker.fetchChangelogForVersion(_appVersion),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (snapshot.data != null &&
                        snapshot.data!.trim().isNotEmpty) {
                      return MarkdownBody(
                        data: _updateChecker.removeReleaseHeading(
                          snapshot.data!,
                          _appVersion,
                        ),
                      );
                    }
                    return Text(
                      "No changelog available for this version.",
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13, height: 1.5),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    bool updated = await _updateChecker.checkForUpdate(
        context, widget.scaffoldMessengerKey);
    if (!updated && mounted) {
      final messenger = widget.scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
        appSnackBar(
          context,
          content: Text("You are using the latest version!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Row(
        children: [
          // Dedicated Desktop Sidebar (~270px)
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : const Color(0xFFFAFBFC),
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withAlpha(15),
                ),
              ),
            ),
            child: Column(
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withAlpha(200)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withAlpha(60),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Quick Insure",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "v$_appVersion",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    children: [
                      _buildSidebarSectionLabel("CALCULATORS"),
                      _buildSidebarTile(
                        id: 'motor',
                        title: 'Motor Insurance',
                        icon: Icons.directions_car_outlined,
                      ),
                      _buildSidebarTile(
                        id: 'fire',
                        title: 'Fire Insurance',
                        icon: Icons.local_fire_department_outlined,
                      ),
                      _buildSidebarTile(
                        id: 'mediclaim',
                        title: 'Overseas Mediclaim',
                        icon: Icons.health_and_safety_outlined,
                        badge: 'Soon',
                        badgeColor: Colors.grey.shade600,
                        isUpcoming: true,
                      ),
                      const SizedBox(height: 20),
                      _buildSidebarSectionLabel("RECORDS & MANAGEMENT"),
                      _buildSidebarTile(
                        id: 'history',
                        title: 'Calculation History',
                        icon: Icons.history_outlined,
                      ),
                      const SizedBox(height: 20),
                      _buildSidebarSectionLabel("SYSTEM & HELP"),
                      _buildSidebarActionTile(
                        title: 'Check for updates',
                        icon: Icons.refresh,
                        onTap: _checkForUpdate,
                      ),
                      _buildSidebarActionTile(
                        title: 'About Quick Insure',
                        icon: Icons.info_outline,
                        onTap: _openAboutDialog,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),
              ],
            ),
          ),

          // Main Active Workbench Area
          Expanded(
            child: Column(
              children: [
                // Top Command & Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161E2E) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getHeaderIcon(), size: 20, color: primary),
                          const SizedBox(width: 10),
                          Text(
                            _getHeaderTitle(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: widget.darkMode ? 'Light mode' : 'Dark mode',
                        icon: Icon(widget.darkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined),
                        onPressed: widget.onToggleDarkMode,
                      ),
                    ],
                  ),
                ),

                // Body Workspace
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final isEntering =
                          (child.key as ValueKey<String>).value ==
                              _selectedSection;
                      final beginX = isEntering ? 0.05 : -0.05;
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
                      key: ValueKey(_selectedSection),
                      child: _buildActiveWorkspace(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildSidebarTile({
    required String id,
    required String title,
    required IconData icon,
    String? badge,
    Color? badgeColor,
    bool isUpcoming = false,
  }) {
    final isSelected = _selectedSection == id;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? primary.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? primary : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? primary : null,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? primary).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? primary,
                  ),
                ),
              )
            : null,
        onTap: () {
          if (isUpcoming) {
            _showComingSoonDialog(title);
          } else {
            setState(() => _selectedSection = id);
          }
        },
      ),
    );
  }

  Widget _buildSidebarActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(icon, size: 20, color: Colors.grey[600]),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getHeaderIcon() {
    switch (_selectedSection) {
      case 'motor':
        return Icons.directions_car;
      case 'fire':
        return Icons.local_fire_department;
      case 'history':
        return Icons.history;
      default:
        return Icons.calculate;
    }
  }

  String _getHeaderTitle() {
    switch (_selectedSection) {
      case 'motor':
        return 'Motor Insurance Premium Calculator';
      case 'fire':
        return 'Fire & Property Insurance Premium Calculator';
      case 'history':
        return 'Calculation History & Export Center';
      default:
        return 'Insurance Calculator';
    }
  }

  Widget _buildActiveWorkspace() {
    switch (_selectedSection) {
      case 'motor':
        return const MotorInsuranceCalculator(isEmbeddedInDesktop: true);
      case 'fire':
        return const FireInsuranceCalculator(isEmbeddedInDesktop: true);
      case 'history':
        return const HistoryScreen(isEmbeddedInDesktop: true);
      default:
        return const MotorInsuranceCalculator(isEmbeddedInDesktop: true);
    }
  }
}
