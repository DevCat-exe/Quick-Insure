import 'package:flutter/material.dart';

class CalculatorCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const CalculatorCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  _CalculatorCardState createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<CalculatorCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color iconCircleColor =
        isDark ? Colors.white.withAlpha(18) : Colors.white.withAlpha(30);
    final Color iconShadowColor =
        isDark ? Colors.black.withAlpha(40) : Colors.white.withAlpha(30);
    final Color iconColor = Colors.white;
    final List<Color> cardGradient = isDark
        ? [
            const Color(0xFFC53030).withOpacity(0.85),
            const Color(0xFFC53030).withOpacity(0.92)
          ]
        : [const Color(0xFFC53030), const Color(0xFFC53030)];
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isTapped = true);
        Feedback.forTap(context); // Haptic feedback
      },
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320), // Smoother, longer
        curve: Curves.easeOutCubic, // More natural
        transform: Matrix4.identity()..scale(_isTapped ? 0.96 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(_isTapped ? 80 : 40)
                  : theme.colorScheme.primary.withAlpha(_isTapped ? 60 : 30),
              blurRadius: _isTapped ? 22 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedScale(
          scale: _isTapped ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: iconCircleColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconShadowColor,
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(widget.icon, size: 44, color: iconColor),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white, // Always white for best contrast
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 1.05,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
