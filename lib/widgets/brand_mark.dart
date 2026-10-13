import 'package:flutter/material.dart';

/// The app's logo: a rounded square with a blue gradient and a chat glyph.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.secondary, colorScheme.primary],
        ),
      ),
      child: Icon(
        Icons.forum_rounded,
        size: size * 0.55,
        color: colorScheme.onPrimary,
      ),
    );
  }
}
