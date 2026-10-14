import 'package:flutter/material.dart';

/// Minimal palette: neutral gray surfaces with a single blue accent.
/// Sent messages use the accent; everything else stays neutral so the
/// accent carries meaning (actions, selection, your own messages).
class AppColorsLight {
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF1D4ED8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF111827);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color sentBubble = primary;
  static const Color onSentBubble = Color(0xFFFFFFFF);
  static const Color receivedBubble = Color(0xFFF3F4F6);
  static const Color onlineGreen = Color(0xFF22C55E);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color shadow = Color(0x14000000);
  static const Color glassBackground = surface;
  static const Color glassBorder = outline;
}

class AppColorsDark {
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF16191F);
  static const Color surfaceVariant = Color(0xFF1F232B);
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color onPrimaryContainer = Color(0xFFDBEAFE);
  static const Color secondary = Color(0xFF60A5FA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFE5E7EB);
  static const Color onSurface = Color(0xFFE5E7EB);
  static const Color onSurfaceVariant = Color(0xFF9CA3AF);
  static const Color outline = Color(0xFF262B33);
  static const Color sentBubble = primary;
  static const Color onSentBubble = Color(0xFFFFFFFF);
  static const Color receivedBubble = Color(0xFF1F232B);
  static const Color onlineGreen = Color(0xFF22C55E);
  static const Color error = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFF450A0A);
  static const Color onErrorContainer = Color(0xFFFCA5A5);
  static const Color shadow = Color(0x66000000);
  static const Color glassBackground = surface;
  static const Color glassBorder = outline;
}

class AppAvatarColors {
  static const List<Color> palette = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
  ];
}

extension AppColorScheme on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  Color get sentBubble =>
      _isDark ? AppColorsDark.sentBubble : AppColorsLight.sentBubble;

  Color get onSentBubble =>
      _isDark ? AppColorsDark.onSentBubble : AppColorsLight.onSentBubble;

  Color get receivedBubble =>
      _isDark ? AppColorsDark.receivedBubble : AppColorsLight.receivedBubble;

  Color get onlineGreen =>
      _isDark ? AppColorsDark.onlineGreen : AppColorsLight.onlineGreen;

  /// Blue-to-indigo gradient used for primary call-to-action buttons.
  List<Color> get accentGradient => [primary, const Color(0xFF6366F1)];

  Color get glassBackground =>
      _isDark ? AppColorsDark.glassBackground : AppColorsLight.glassBackground;

  Color get glassBorder =>
      _isDark ? AppColorsDark.glassBorder : AppColorsLight.glassBorder;
}
