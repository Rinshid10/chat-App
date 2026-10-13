import 'package:flutter/material.dart';

/// Flat surface panel used for headers, sheets and the message input.
///
/// It used to blur what is behind it. The minimal theme replaces that with
/// a solid surface and a hairline border, which is also much cheaper to
/// render on web. [blurSigma] and [opacity] are kept so existing call sites
/// compile; they no longer change the appearance.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double? opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 15.0,
    this.opacity,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.zero;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: effectiveBorderRadius,
        border: border ?? Border.all(color: colorScheme.outline, width: 1),
      ),
      child: child,
    );
  }
}
