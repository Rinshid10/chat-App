import 'package:flutter/material.dart';

import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/widgets/depth.dart';

/// The app's logo: a rounded gradient tile with a lit top edge, a glossy
/// highlight and a tinted glow, holding a chat glyph.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.accentGradient;
    final radius = size * 0.28;

    return DepthSurface(
      width: size,
      height: size,
      radius: radius,
      level: 2,
      shadowTint: accent.first,
      rimTint: accent.first,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppDepth.lighten(accent.first, 0.18),
          accent.first,
          accent.last,
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Glossy highlight across the upper half.
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.forum_rounded,
              size: size * 0.55,
              color: colorScheme.onPrimary,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
