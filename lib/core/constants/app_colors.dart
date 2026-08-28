import 'package:flutter/material.dart';

/// Centralized color palette for the Retail Inventory AI app.
/// Premium dark dashboard theme with blue/cyan accents.
class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF16213A);
  static const Color card = Color(0xFF1B2A4A);
  static const Color cardAlt = Color(0xFF1E2E52);

  // Brand
  static const Color primary = Color(0xFF3B82F6); // Blue
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF22D3EE); // Cyan
  static const Color secondaryDark = Color(0xFF06B6D4);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Borders / dividers
  static const Color border = Color(0xFF27324A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [card, cardAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'healthy':
      case 'in stock':
        return success;
      case 'low':
      case 'warning':
        return warning;
      case 'critical':
      case 'out of stock':
        return danger;
      default:
        return textMuted;
    }
  }
}
