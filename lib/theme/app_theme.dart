import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Minimal theme: flat surfaces, hairline borders, one accent, 12px radius.
class AppTheme {
  static const double radius = 12;
  static const double controlRadius = 10;

  static ThemeData light() => _build(Brightness.light, const _Tokens.light());

  static ThemeData dark() => _build(Brightness.dark, const _Tokens.dark());

  static ThemeData _build(Brightness brightness, _Tokens t) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.primaryContainer,
      onPrimaryContainer: t.onPrimaryContainer,
      secondary: t.secondary,
      onSecondary: t.onPrimary,
      surface: t.surface,
      onSurface: t.onSurface,
      surfaceContainerHighest: t.surfaceVariant,
      onSurfaceVariant: t.onSurfaceVariant,
      outline: t.outline,
      outlineVariant: t.outline,
      error: t.error,
      onError: t.onPrimary,
      errorContainer: t.errorContainer,
      onErrorContainer: t.onErrorContainer,
      shadow: t.shadow,
    );

    final textTheme = _textTheme(t);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: t.onSurfaceVariant, size: 22),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: t.background,
        foregroundColor: t.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: t.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceVariant,
        hintStyle: TextStyle(color: t.onSurfaceVariant),
        prefixIconColor: t.onSurfaceVariant,
        suffixIconColor: t.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: t.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: t.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: t.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.onPrimary,
          disabledBackgroundColor: t.primary.withOpacity(0.5),
          disabledForegroundColor: t.onPrimary.withOpacity(0.8),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.onSurface,
          side: BorderSide(color: t.outline),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: t.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.primary,
        unselectedItemColor: t.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: t.primaryContainer,
        useIndicator: true,
        selectedIconTheme: IconThemeData(color: t.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: t.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.outline),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: t.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(color: t.outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: t.onSurfaceVariant,
        textColor: t.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: t.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? t.surfaceVariant : t.onSurface,
        contentTextStyle: TextStyle(
          color: isDark ? t.onSurface : t.surface,
          fontSize: 14,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? t.surfaceVariant : t.onSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: isDark ? t.onSurface : t.surface,
          fontSize: 12,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.onPrimary
              : t.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.primary
              : t.surfaceVariant,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : t.outline,
        ),
      ),
    );
  }

  static TextTheme _textTheme(_Tokens t) {
    final color = t.onSurface;
    final subtle = t.onSurfaceVariant;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: color),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: color),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: subtle),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtle,
      ),
    );
  }
}

/// Color tokens for one brightness, so light and dark share one builder.
class _Tokens {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onPrimary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color shadow;

  const _Tokens.light()
    : background = AppColorsLight.background,
      surface = AppColorsLight.surface,
      surfaceVariant = AppColorsLight.surfaceVariant,
      primary = AppColorsLight.primary,
      primaryContainer = AppColorsLight.primaryContainer,
      onPrimaryContainer = AppColorsLight.onPrimaryContainer,
      secondary = AppColorsLight.secondary,
      onPrimary = AppColorsLight.onPrimary,
      onSurface = AppColorsLight.onSurface,
      onSurfaceVariant = AppColorsLight.onSurfaceVariant,
      outline = AppColorsLight.outline,
      error = AppColorsLight.error,
      errorContainer = AppColorsLight.errorContainer,
      onErrorContainer = AppColorsLight.onErrorContainer,
      shadow = AppColorsLight.shadow;

  const _Tokens.dark()
    : background = AppColorsDark.background,
      surface = AppColorsDark.surface,
      surfaceVariant = AppColorsDark.surfaceVariant,
      primary = AppColorsDark.primary,
      primaryContainer = AppColorsDark.primaryContainer,
      onPrimaryContainer = AppColorsDark.onPrimaryContainer,
      secondary = AppColorsDark.secondary,
      onPrimary = AppColorsDark.onPrimary,
      onSurface = AppColorsDark.onSurface,
      onSurfaceVariant = AppColorsDark.onSurfaceVariant,
      outline = AppColorsDark.outline,
      error = AppColorsDark.error,
      errorContainer = AppColorsDark.errorContainer,
      onErrorContainer = AppColorsDark.onErrorContainer,
      shadow = AppColorsDark.shadow;
}
