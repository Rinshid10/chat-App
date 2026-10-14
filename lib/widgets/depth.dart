import 'package:flutter/material.dart';

import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/theme/app_theme.dart';

/// Shared "layered depth" look: every raised surface has a soft vertical
/// gradient, a light edge on top, a darker edge below and stacked drop
/// shadows. Interactive surfaces press down when held and can lift on hover.
class AppDepth {
  AppDepth._();

  static bool _isDark(ColorScheme cs) => cs.brightness == Brightness.dark;

  static Color lighten(Color c, double amount) =>
      Color.alphaBlend(Colors.white.withOpacity(amount), c);

  static Color darken(Color c, double amount) =>
      Color.alphaBlend(Colors.black.withOpacity(amount), c);

  /// Drop shadows for a raised surface. [level] 0 is flat, 3 is floating.
  static List<BoxShadow> shadows(ColorScheme cs, {int level = 1, Color? tint}) {
    if (level <= 0) return const [];
    final dark = _isDark(cs);
    final base = tint ?? Colors.black;
    final near = dark ? 0.45 : (tint != null ? 0.30 : 0.10);
    final far = dark ? 0.30 : (tint != null ? 0.22 : 0.07);
    final l = level.clamp(1, 3).toDouble();
    return [
      BoxShadow(
        color: base.withOpacity(near),
        offset: Offset(0, 1.5 * l),
        blurRadius: 3 * l,
      ),
      BoxShadow(
        color: base.withOpacity(far),
        offset: Offset(0, 7 * l),
        blurRadius: 14 * l,
        spreadRadius: -3,
      ),
    ];
  }

  /// Fill for a raised surface: slightly lighter at the top, darker below.
  static Gradient raisedFill(ColorScheme cs, Color color) {
    final dark = _isDark(cs);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lighten(color, dark ? 0.07 : 0.0),
        color,
        darken(color, dark ? 0.06 : 0.035),
      ],
    );
  }

  /// Fill for a pressed-in surface (text fields, wells): darker at the top.
  static Gradient insetFill(ColorScheme cs, Color color) {
    final dark = _isDark(cs);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        darken(color, dark ? 0.22 : 0.06),
        color,
        lighten(color, dark ? 0.03 : 0.0),
      ],
    );
  }

  /// 1px rim drawn around a surface: a highlight on top fading to a shade
  /// at the bottom, so the edge reads as lit from above.
  static Gradient rim(ColorScheme cs, {bool inset = false, Color? tint}) {
    final dark = _isDark(cs);
    final outline = tint ?? cs.outline;
    final top = Color.alphaBlend(
      Colors.white.withOpacity(dark ? 0.16 : 0.9),
      outline,
    );
    final bottom = Color.alphaBlend(
      Colors.black.withOpacity(dark ? 0.35 : 0.12),
      outline,
    );
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: inset ? [bottom, top] : [top, bottom],
    );
  }
}

/// A raised (or inset) panel with the depth treatment. Pass [onTap] to make
/// it press down while held; [hoverLift] raises it slightly under a mouse.
class DepthSurface extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final BoxShape shape;
  final Color? color;
  final Gradient? gradient;
  final Color? shadowTint;
  final Color? rimTint;
  final int level;
  final bool inset;
  final bool hoverLift;
  final double? width;
  final double? height;
  final double edge;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final String? tooltip;
  final Clip clipBehavior;

  const DepthSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppTheme.radius,
    this.shape = BoxShape.rectangle,
    this.color,
    this.gradient,
    this.shadowTint,
    this.rimTint,
    this.level = 1,
    this.inset = false,
    this.hoverLift = false,
    this.width,
    this.height,
    this.edge = 0,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.tooltip,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  State<DepthSurface> createState() => _DepthSurfaceState();
}

class _DepthSurfaceState extends State<DepthSurface> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _interactive =>
      widget.onTap != null ||
      widget.onLongPress != null ||
      widget.onSecondaryTap != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = widget.color ?? cs.surface;

    final lifted = widget.hoverLift && _hovered && !_pressed;
    final level = widget.inset
        ? 0
        : _pressed
        ? (widget.level - 1).clamp(0, 3)
        : lifted
        ? (widget.level + 1).clamp(0, 3)
        : widget.level;
    final dy = _pressed
        ? 2.0 + widget.edge
        : lifted
        ? -2.0
        : 0.0;
    final scale = _pressed ? 0.985 : 1.0;
    final edge = _pressed ? 0.0 : widget.edge;

    final isCircle = widget.shape == BoxShape.circle;
    final outerRadius = isCircle ? null : BorderRadius.circular(widget.radius);
    final innerRadius = isCircle
        ? null
        : BorderRadius.circular((widget.radius - 1).clamp(0, 999));

    final shadows = <BoxShadow>[
      if (edge > 0)
        BoxShadow(
          color: AppDepth.darken(widget.shadowTint ?? base, 0.35),
          offset: Offset(0, edge),
        ),
      ...AppDepth.shadows(cs, level: level, tint: widget.shadowTint),
    ];

    Widget surface = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      transform: Matrix4.identity()
        ..translate(0.0, dy)
        ..scale(scale),
      transformAlignment: Alignment.center,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: outerRadius,
        gradient: AppDepth.rim(cs, inset: widget.inset, tint: widget.rimTint),
        boxShadow: shadows,
      ),
      child: Container(
        clipBehavior: widget.clipBehavior,
        padding: widget.padding,
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: innerRadius,
          gradient:
              widget.gradient ??
              (widget.inset
                  ? AppDepth.insetFill(cs, base)
                  : AppDepth.raisedFill(cs, base)),
        ),
        child: widget.child,
      ),
    );

    if (widget.tooltip != null) {
      surface = Tooltip(message: widget.tooltip!, child: surface);
    }

    if (!_interactive && !widget.hoverLift) return surface;

    return MouseRegion(
      cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _interactive
            ? () => setState(() => _pressed = false)
            : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        child: surface,
      ),
    );
  }
}

/// Accent-colored 3D button: gradient fill, lit rim, a solid bottom edge
/// that disappears when pressed, and a tinted glow.
class DepthButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final BoxShape shape;
  final double? width;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;

  const DepthButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.height = 50,
    this.radius = AppTheme.controlRadius,
    this.shape = BoxShape.rectangle,
    this.width,
    this.colors,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = colors ?? cs.accentGradient;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppDepth.lighten(palette.first, 0.12),
        palette.first,
        palette.last,
      ],
    );
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: cs.onPrimary),
          child: DepthSurface(
            onTap: onPressed,
            level: 2,
            edge: 3,
            width: width,
            height: height,
            radius: radius,
            shape: shape,
            gradient: gradient,
            shadowTint: palette.first,
            rimTint: palette.first,
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// A thin divider that also paints a soft shade on its far side, so the bar
/// or panel before it reads as sitting above the content after it.
class DepthEdge extends StatelessWidget {
  final Axis axis;
  final double shade;

  const DepthEdge({super.key, required this.axis, this.shade = 10});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    final shadow = Colors.black.withOpacity(dark ? 0.35 : 0.08);
    final horizontal = axis == Axis.horizontal;

    return SizedBox(
      height: horizontal ? shade + 1 : null,
      width: horizontal ? null : shade + 1,
      child: Flex(
        direction: horizontal ? Axis.vertical : Axis.horizontal,
        children: [
          Container(
            height: horizontal ? 1 : null,
            width: horizontal ? null : 1,
            color: cs.outline,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: horizontal
                      ? Alignment.topCenter
                      : Alignment.centerLeft,
                  end: horizontal
                      ? Alignment.bottomCenter
                      : Alignment.centerRight,
                  colors: [shadow, shadow.withOpacity(0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tilts its child a few degrees toward the mouse pointer, with perspective,
/// so large panels feel like physical cards on desktop.
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTiltDegrees;

  const TiltCard({super.key, required this.child, this.maxTiltDegrees = 4});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _target = Offset.zero;

  void _update(PointerEvent event, Size size) {
    if (size.isEmpty) return;
    final dx = (event.localPosition.dx / size.width) * 2 - 1;
    final dy = (event.localPosition.dy / size.height) * 2 - 1;
    setState(() => _target = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return MouseRegion(
          onHover: (e) => _update(e, size),
          onExit: (_) => setState(() => _target = Offset.zero),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: _target),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, offset, child) {
              final tilt = widget.maxTiltDegrees * 3.14159 / 180;
              final matrix = offset == Offset.zero
                  ? Matrix4.identity()
                  : (Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateX(-offset.dy * tilt)
                      ..rotateY(offset.dx * tilt));
              return Transform(
                alignment: Alignment.center,
                transform: matrix,
                child: child,
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
