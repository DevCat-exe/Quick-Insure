import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onAboutPressed;
  final VoidCallback onUpdatePressed;

  const AppDrawer({
    super.key,
    required this.onAboutPressed,
    required this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: 280,
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 15),
                Text(
                  "Quick Insure",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.info_outline_rounded,
            title: "About App",
            onTap: onAboutPressed,
          ),
          _buildListTile(
            context,
            icon: Icons.update_rounded,
            title: "Check Updates",
            onTap: onUpdatePressed,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Version 1.0.0",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      horizontalTitleGap: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}