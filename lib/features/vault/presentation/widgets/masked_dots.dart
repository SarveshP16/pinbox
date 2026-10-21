import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// A row of small dots standing in for a hidden secret, one per character
/// (capped so a long password doesn't push the row wider than the screen).
class MaskedDots extends StatelessWidget {
  const MaskedDots({
    super.key,
    required this.count,
    this.size = 4.5,
    this.gap,
    this.color,
  });

  final int count;
  final double size;

  /// Space between dots; defaults to a little wider than the dot itself.
  final double? gap;

  /// Dot colour; defaults to the theme's secondary text colour.
  final Color? color;

  static const maxDots = 10;

  @override
  Widget build(BuildContext context) {
    final shown = count.clamp(1, maxDots);
    final dotColor = color ?? context.colors.muted;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown; i++) ...[
            if (i > 0) SizedBox(width: gap ?? size * 1.7),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
