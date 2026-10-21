import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// 3x4 numeric keypad. The bottom-left slot shows a fingerprint key when
/// [onBiometric] is given (otherwise it is left blank), the bottom-right is delete.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final bool enabled;

  static const _gap = 13.0;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> keys) => Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(
            child: AspectRatio(aspectRatio: 100 / 71, child: keys[i]),
          ),
        ],
      ],
    );

    Widget digit(String d) => _KeyButton(
      onTap: enabled ? () => onDigit(d) : null,
      child: Text(d, style: AppText.display(27, weight: 700)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([digit('1'), digit('2'), digit('3')]),
          const SizedBox(height: _gap),
          row([digit('4'), digit('5'), digit('6')]),
          const SizedBox(height: _gap),
          row([digit('7'), digit('8'), digit('9')]),
          const SizedBox(height: _gap),
          row([
            if (onBiometric != null)
              _KeyButton(
                onTap: enabled ? onBiometric : null,
                fill: context.colors.primaryTint,
                bordered: false,
                semanticLabel: 'Use biometrics',
                child: Icon(
                  LucideIcons.fingerprintPattern,
                  size: 28,
                  color: context.colors.primary,
                ),
              )
            else
              const SizedBox.shrink(),
            digit('0'),
            _KeyButton(
              onTap: enabled ? onDelete : null,
              fill: Colors.transparent,
              bordered: false,
              semanticLabel: 'Delete',
              child: Icon(
                LucideIcons.delete,
                size: 26,
                color: context.colors.ink,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.child,
    required this.onTap,
    this.fill,
    this.bordered = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Key background; defaults to the theme's surface colour.
  final Color? fill;
  final bool bordered;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: bordered
          ? BorderSide(color: context.colors.border)
          : BorderSide.none,
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: fill ?? context.colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Center(child: child),
        ),
      ),
    );
  }
}
