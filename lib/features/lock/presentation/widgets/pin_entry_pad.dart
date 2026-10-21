import 'package:flutter/material.dart';

import 'pin_dots.dart';
import 'pin_keypad.dart';

/// Dots + keypad wired together. Collects [length] digits, then calls [onComplete].
/// Return `true` from it to accept the PIN (dots stay filled while the parent
/// navigates or advances); return `false` to reject it — the dots shake and clear.
class PinEntryPad extends StatefulWidget {
  const PinEntryPad({
    super.key,
    required this.onComplete,
    this.onBiometric,
    this.enabled = true,
    this.length = 6,
  });

  final Future<bool> Function(String pin) onComplete;
  final VoidCallback? onBiometric;
  final bool enabled;
  final int length;

  @override
  State<PinEntryPad> createState() => _PinEntryPadState();
}

class _PinEntryPadState extends State<PinEntryPad> {
  String _pin = '';
  bool _busy = false;
  int _shakeKey = 0;

  Future<void> _digit(String d) async {
    if (_busy || !widget.enabled || _pin.length >= widget.length) return;
    setState(() => _pin += d);
    if (_pin.length < widget.length) return;

    _busy = true;
    final accepted = await widget.onComplete(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!accepted) {
        _pin = '';
        _shakeKey++;
      }
    });
  }

  void _delete() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PinDots(
          filled: _pin.length,
          length: widget.length,
          shakeKey: _shakeKey,
        ),
        const SizedBox(height: 40),
        PinKeypad(
          onDigit: _digit,
          onDelete: _delete,
          onBiometric: widget.onBiometric,
          enabled: widget.enabled,
        ),
      ],
    );
  }
}
