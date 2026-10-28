import 'package:flutter/material.dart';

import '../../theme/mono_tokens.dart';
import 'nocturne_spotlight.dart';

/// A cast or crew portrait in the Nocturne layout: the photo in a circle, or
/// the person's initials on a tint of their name's hue when there is none.
class NocturnePersonPortrait extends StatelessWidget {
  const NocturnePersonPortrait({super.key, required this.name, required this.size, this.photo});

  final String name;
  final double size;

  /// The photo, already sized to [size]; null draws the initials.
  final Widget? photo;

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final photo = this.photo;
    if (photo != null) {
      return ClipOval(
        child: SizedBox.square(dimension: size, child: photo),
      );
    }
    final tint = HSLColor.fromAHSL(1, nocturneTitleHue(name), 0.32, 0.28).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(tint, t.surface, 0.35)),
      child: Text(
        nocturneMonogram(name),
        maxLines: 1,
        style: TextStyle(color: t.text, fontSize: size * 0.3, fontWeight: FontWeight.w700, height: 1),
      ),
    );
  }
}
