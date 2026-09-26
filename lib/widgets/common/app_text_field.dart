import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppTextField — Design-system text input
///
/// Drop-in replacement for Flutter's [TextField] with:
///   • consistent dark theme styling (from AppColors/AppRadius)
///   • optional prefix icon (any IconData)
///   • error state with red border
///   • password visibility toggle
///   • label + hint
///
/// Usage:
///   AppTextField(label: 'Email', hint: 'you@ymentor.com', controller: ctrl)
///   AppTextField.password(label: 'Password', controller: ctrl)
/// ─────────────────────────────────────────────────────────────────────────────
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixWidget,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.isPassword = false,
    this.autofocus = false,
    this.textInputAction,
    this.validator,
  });

  /// Convenience constructor for password fields
  const AppTextField.password({
    super.key,
    this.label = 'Password',
    this.hint = '••••••••',
    this.controller,
    this.prefixIcon,
    this.suffixWidget,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction,
    this.validator,
  })  : isPassword = true,
        keyboardType = TextInputType.visiblePassword,
        maxLines = 1,
        minLines = null;

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool isPassword;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (widget.maxLines ?? 1) > 1;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      obscureText: widget.isPassword && _obscure,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        alignLabelWithHint: isMultiline,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixWidget,
      ),
    );
  }
}
