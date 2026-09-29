import 'dart:math' as math;

import 'package:flutter/material.dart';

SnackBar appSnackBar(
  BuildContext context, {
  required Widget content,
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isWide = screenWidth >= 600;

  return SnackBar(
    content: content,
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    width: isWide ? math.min(420, screenWidth - 32) : null,
    margin: isWide ? null : const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: duration,
  );
}
