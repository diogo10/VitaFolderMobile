import 'package:flutter/material.dart';
import 'package:house_mira/theme/sand_palette.dart';

InputDecoration sandInputDecoration({
  required String hint,
  required IconData prefixIcon,
  Widget? suffixIcon,
  BuildContext? context,
}) {
  final theme = context != null ? Theme.of(context).textTheme : null;
  return InputDecoration(
    hintText: hint,
    hintStyle:
        theme?.bodyMedium?.copyWith(color: SandPalette.sand300) ??
        const TextStyle(color: SandPalette.sand300, fontSize: 14),
    prefixIcon: Icon(prefixIcon, size: 18, color: SandPalette.sand400),
    suffixIcon: suffixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 48),
    suffixIconConstraints: const BoxConstraints(minWidth: 48),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: _outlineBorder(),
    enabledBorder: _outlineBorder(),
    focusedBorder: _outlineBorder(width: 1.5),
  );
}

OutlineInputBorder _outlineBorder({double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: SandPalette.sand200, width: width),
  );
}

class SandLabeledField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final String? helperText;
  final Widget? labelTrailing;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const SandLabeledField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.helperText,
    this.labelTrailing,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  State<SandLabeledField> createState() => _SandLabeledFieldState();
}

class _SandLabeledFieldState extends State<SandLabeledField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: theme.labelSmall?.copyWith(
                  color: SandPalette.sand500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              widget.labelTrailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText && _obscured,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          style: theme.bodyMedium?.copyWith(color: SandPalette.sand600),
          decoration: sandInputDecoration(
            hint: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: SandPalette.sand300,
                    ),
                  )
                : null,
            context: context,
          ),
          validator: widget.validator,
        ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              widget.helperText!,
              style: theme.bodySmall?.copyWith(
                color: SandPalette.sand400,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}
