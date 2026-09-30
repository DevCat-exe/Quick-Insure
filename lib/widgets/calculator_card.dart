import 'package:flutter/material.dart';
import '../constants/styles.dart';

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
  State<CalculatorCard> createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<CalculatorCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color iconCircleColor =
        isDark ? Colors.white.withAlpha(25) : Colors.white.withAlpha(40);

    final LinearGradient cardGradient = isDark
        ? const LinearGradient(
            colors: [AppStyles.primaryColor, AppStyles.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppStyles.primaryGradient;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isTapped = true);
        Feedback.forTap(context);
      },
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isTapped ? 0.94 : 1.0, _isTapped ? 0.94 : 1.0, 1.0, 1.0),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(_isTapped ? 120 : 60)
                  : AppStyles.primaryColor.withAlpha(_isTapped ? 100 : 50),
              blurRadius: _isTapped ? 20 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconCircleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(widget.icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
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
    );
  }
}
