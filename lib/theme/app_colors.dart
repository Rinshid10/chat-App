import 'package:flutter/material.dart';

class AppColorsLight {
  static const Color background = Color(0xFFF7F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color primary = Color(0xFF128C7E);
  static const Color primaryContainer = Color(0xFFE0F5F2);
  static const Color secondary = Color(0xFF075E54);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF2C2C2C);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color sentBubble = Color(0xFFDCF8C6);
  static const Color receivedBubble = Color(0xFFFFFFFF);
  static const Color onlineGreen = Color(0xFF25D366);
  static const Color error = Color(0xFFDC3545);
  static const Color shadow = Color(0x0A000000);
  static const Color glassBackground = Color(0xB3FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
}

class AppColorsDark {
  static const Color background = Color(0xFF0B141A);
  static const Color surface = Color(0xFF1F2C34);
  static const Color surfaceVariant = Color(0xFF2A3942);
  static const Color primary = Color(0xFF00A884);
  static const Color primaryContainer = Color(0xFF0D3B30);
  static const Color secondary = Color(0xFF53BDAB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFE9EDEF);
  static const Color onSurface = Color(0xFFE9EDEF);
  static const Color onSurfaceVariant = Color(0xFF8696A0);
  static const Color outline = Color(0xFF2A3942);
  static const Color sentBubble = Color(0xFF005C4B);
  static const Color receivedBubble = Color(0xFF1F2C34);
  static const Color onlineGreen = Color(0xFF25D366);
  static const Color error = Color(0xFFFF6B6B);
  static const Color shadow = Color(0x1A000000);
  static const Color glassBackground = Color(0x991F2C34);
  static const Color glassBorder = Color(0x14FFFFFF);
}

class AppAvatarColors {
  static const List<Color> palette = [
    Color(0xFF5B72E8),
    Color(0xFF00A884),
    Color(0xFFFF6B6B),
    Color(0xFFF5A623),
    Color(0xFF9B59B6),
    Color(0xFF3498DB),
  ];
}

extension AppColorScheme on ColorScheme {
  Color get sentBubble => brightness == Brightness.dark
      ? AppColorsDark.sentBubble
      : AppColorsLight.sentBubble;

  Color get receivedBubble => brightness == Brightness.dark
      ? AppColorsDark.receivedBubble
      : AppColorsLight.receivedBubble;

  Color get onlineGreen => const Color(0xFF25D366);

  Color get glassBackground => brightness == Brightness.dark
      ? AppColorsDark.glassBackground
      : AppColorsLight.glassBackground;

  Color get glassBorder => brightness == Brightness.dark
      ? AppColorsDark.glassBorder
      : AppColorsLight.glassBorder;
}
