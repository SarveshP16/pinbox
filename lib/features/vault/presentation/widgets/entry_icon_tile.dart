import 'package:flutter/material.dart';

import '../../domain/entry_type.dart';
import 'entry_type_style.dart';

/// Rounded square holding an entry type's icon, tinted per type.
class EntryIconTile extends StatelessWidget {
  const EntryIconTile({super.key, required this.type, this.size = 40});

  final EntryType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.tintOf(context),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(type.icon, size: size * 0.55, color: type.inkOf(context)),
    );
  }
}
