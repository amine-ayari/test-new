import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/config/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final bool showLabel;
  final bool filled;
  final Color? fillColor;
  final String? helperText;
  final bool isDense;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.showLabel = false,
    this.filled = true,
    this.fillColor,
    this.helperText,
    this.isDense = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.labelText!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              style: TextStyle(
                fontSize: widget.isDense ? 14 : 16,
                color: widget.enabled
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                labelText: widget.showLabel ? null : widget.labelText,
                helperText: widget.helperText,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                        size: widget.isDense ? 18 : 20,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.enabled
                        ? AppTheme.dividerColor
                        : Colors.transparent,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.enabled
                        ? AppTheme.dividerColor
                        : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.errorColor),
                ),
                filled: widget.filled,
                fillColor: widget.fillColor ??
                    (widget.enabled ? Colors.white : Colors.grey.shade100),
                contentPadding: widget.contentPadding ??
                    EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: widget.isDense ? 12 : 16,
                    ),
                isDense: widget.isDense,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: widget.isDense ? 14 : 16,
                ),
                labelStyle: TextStyle(
                  color: _isFocused
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                ),
                helperStyle: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
                counterStyle: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
