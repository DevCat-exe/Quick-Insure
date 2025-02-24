import 'package:flutter/material.dart';
import '../screens/motor_insurance_calculator.dart';
import '../widgets/calculator_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_checker.dart'; // Import the update checker

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _openAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About Quick Insure"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Version: $_appVersion"),
            SizedBox(height: 10),
            Text("Quick Insure is your trusted insurance partner."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) async {
    final updateChecker = UpdateChecker();
    final isUpdateAvailable = await updateChecker.checkForUpdate(context);

    if (!isUpdateAvailable) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are using the latest version.")),
      );
    }
  }

  void _showComingSoonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Coming Soon"),
        content: Text("The Fire Insurance Calculator is under development."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quick Insure"),
            Text(
              "Your trusted insurance partner",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC53030), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC53030), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                "Quick Insure",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Color(0xFFC53030)),
              title: Text("About"),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _openAboutDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.update, color: Color(0xFFC53030)),
              title: Text("Check for Updates"),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _checkForUpdates(context);
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FAFB), Color(0xFFE0E0E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    CalculatorCard(
                      title: "Motor",
                      icon: Icons.directions_car,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 300),
                            pageBuilder: (_, __, ___) =>
                                MotorInsuranceCalculator(),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                    ),
                    CalculatorCard(
                      title: "Fire",
                      icon: Icons.local_fire_department,
                      onTap: () {
                        _showComingSoonPopup(
                            context); // Show "Coming Soon" popup
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
