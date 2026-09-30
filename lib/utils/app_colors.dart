import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFF0F1923);
  static const Color surface = Color(0xFF1A2635);
  static const Color surfaceLight = Color(0xFF243447);
  static const Color cardBorder = Color(0xFF2E4057);

  // Primary
  static const Color primary = Color(0xFF00BFA5);
  static const Color primaryDark = Color(0xFF009688);
  static const Color primaryLight = Color(0xFF4DD0C4);

  // Accent
  static const Color accent = Color(0xFFFFD54F);
  static const Color accentOrange = Color(0xFFFFB74D);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textHint = Color(0xFF546E7A);

  // Status
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Dashboard card gradients
  static const List<List<Color>> dashboardGradients = [
    [Color(0xFF00BFA5), Color(0xFF00796B)], // Add Citizen - teal
    [Color(0xFF5C6BC0), Color(0xFF3949AB)], // Citizen List - indigo
    [Color(0xFF26C6DA), Color(0xFF0097A7)], // NIC Search - cyan
    [Color(0xFF66BB6A), Color(0xFF388E3C)], // Filter Search - green
    [Color(0xFFFF7043), Color(0xFFE64A19)], // Export PDF - deep orange
    [Color(0xFF8D6E63), Color(0xFF5D4037)], // Backup - brown
    [Color(0xFF26A69A), Color(0xFF00796B)], // Restore - teal variant
    [Color(0xFF9575CD), Color(0xFF7B1FA2)], // GS Profile - purple
  ];

  // Light theme
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A2635);
  static const Color lightTextSecondary = Color(0xFF546E7A);
}
