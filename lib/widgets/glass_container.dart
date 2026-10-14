import 'package:flutter/material.dart';

import 'package:chatapp/widgets/depth.dart';

/// Raised panel used for headers, sheets and dialogs.
///
/// Historically this blurred what was behind it; it now paints a solid
/// surface with a subtle top-lit gradient and a drop shadow, which gives the
/// layered-depth look and is far cheaper to render on web. [blurSigma] and
/// [opacity] are kept so older call sites compile; they no longer change
/// the appearance.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double? opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Shadow strength, 0 (flat) to 3 (floating).
  final int level;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 15.0,
    this.opacity,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.level = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.zero;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppDepth.raisedFill(colorScheme, colorScheme.surface),
        borderRadius: effectiveBorderRadius,
        border: border ?? Border.all(color: colorScheme.outline, width: 1),
        boxShadow: AppDepth.shadows(colorScheme, level: level),
      ),
      child: child,
    );
  }
}
