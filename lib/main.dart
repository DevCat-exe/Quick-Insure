import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'constants/styles.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(960, 640),
      center: true,
      title: 'Quick Insure',
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const QuickInsureApp());
}

class QuickInsureApp extends StatefulWidget {
  const QuickInsureApp({super.key});

  @override
  State<QuickInsureApp> createState() => _QuickInsureAppState();
}

class _QuickInsureAppState extends State<QuickInsureApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _darkMode = prefs.getBool('dark_mode') ?? false;
        });
      }
    } catch (_) {}
  }

  void _toggleDarkMode() async {
    setState(() {
      _darkMode = !_darkMode;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _darkMode);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Insure',
      theme: AppStyles.getTheme(isDark: _darkMode),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: HomeScreen(
        onToggleDarkMode: _toggleDarkMode,
        darkMode: _darkMode,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
