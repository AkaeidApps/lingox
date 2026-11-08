import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF8B85FF);

  // Secondary colors
  static const Color secondary = Color(0xFF00C9A7);
  static const Color secondaryDark = Color(0xFF00B396);

  // Accent colors
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentWarm = Color(0xFFFFA726);

  // Background colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F0F8);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7385);
  static const Color textHint = Color(0xFF9E9E9E);

  // Border & divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F5);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B85FF), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voiceGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00C9A7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
