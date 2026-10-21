import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// A label above a white, rounded input. On focus the border turns green and a soft
/// tinted ring appears around it, as in the Add PIN design.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.autofocus = false,
    this.autocorrect = true,
    this.suffix,
    this.pinDots = false,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool autofocus;
  final bool autocorrect;
  final Widget? suffix;

  /// Draws the obscured characters as large, widely spaced dots (the PIN field look).
  final bool pinDots;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? context.colors.danger
        : focused
        ? context.colors.primary
        : context.colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.body(13.5, weight: 600)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: focused || hasError ? 1.5 : 1,
            ),
            boxShadow: [
              if (focused && !hasError)
                BoxShadow(
                  color: context.colors.primaryTint,
                  spreadRadius: 4,
                  blurRadius: 0,
                ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            obscuringCharacter: '•',
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: 1,
            autofocus: widget.autofocus,
            autocorrect: widget.autocorrect && !widget.obscureText,
            enableSuggestions: !widget.obscureText,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: context.colors.primary,
            style: widget.pinDots && widget.obscureText
                ? AppText.body(23, letterSpacing: 6.5, height: 1.0)
                : AppText.body(15.5),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.body(
                15.5,
                color: context.colors.muted.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 14.5,
              ),
              suffixIcon: widget.suffix,
            ),
          ),
        ),
        if (hasError || widget.helper != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.zero,
            child: Text(
              widget.errorText ?? widget.helper!,
              style: AppText.body(
                12.5,
                color: hasError ? context.colors.danger : context.colors.muted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
