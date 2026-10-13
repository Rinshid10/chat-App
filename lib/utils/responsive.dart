import 'package:flutter/material.dart';

/// Layout breakpoints shared across the app.
///
/// Below [desktop] the app keeps its phone layout. At or above it the
/// chat list and chat pane sit side by side, sheets become dialogs, and
/// forms are shown as centered cards.
class Breakpoints {
  Breakpoints._();

  static const double desktop = 900;
}

/// True when the window is wide enough for the desktop/web layout.
bool isDesktopLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
}

/// Wraps a form-style screen body. On phones the child fills the width.
/// On desktop the child is centered inside a card with a capped width.
class ResponsiveFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry desktopPadding;

  /// When set, the desktop card gets this exact height (clamped to the
  /// window) instead of sizing to its content. Needed for children that use
  /// [Spacer] or [Expanded], which require a bounded height.
  final double? fixedHeight;

  const ResponsiveFormCard({
    super.key,
    required this.child,
    this.desktopPadding = const EdgeInsets.all(32),
    this.fixedHeight,
  });

  static const double maxWidth = 440;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopLayout(context)) return child;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      padding: desktopPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(isDark ? 0.4 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );

    final height = fixedHeight;
    if (height != null) {
      final available = MediaQuery.sizeOf(context).height - 48;
      return Center(
        child: SizedBox(
          width: maxWidth,
          height: height < available ? height : available,
          child: card,
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: card,
        ),
      ),
    );
  }
}

/// Centers [child] with a maximum width on desktop; passes it through on
/// phones. Used for long lists and detail pages so they do not stretch
/// across very wide windows.
class MaxWidthBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthBody({super.key, required this.child, this.maxWidth = 960});

  @override
  Widget build(BuildContext context) {
    if (!isDesktopLayout(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
