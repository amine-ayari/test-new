import 'package:flutter/material.dart';
import 'package:flutter_activity_app/config/app_theme.dart';


enum ButtonSize { small, medium, large }
enum ButtonVariant { filled, outlined, text, tonal }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final ButtonSize size;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;
  final bool elevated;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.filled,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.size = ButtonSize.medium,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.padding,
    this.fullWidth = true,
    this.elevated = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine button height based on size
    double buttonHeight;
    double fontSize;
    double iconSize;
    
    switch (widget.size) {
      case ButtonSize.small:
        buttonHeight = 36;
        fontSize = 14;
        iconSize = 16;
        break;
      case ButtonSize.medium:
        buttonHeight = 48;
        fontSize = 16;
        iconSize = 18;
        break;
      case ButtonSize.large:
        buttonHeight = 56;
        fontSize = 16;
        iconSize = 20;
        break;
    }
    
    // Determine colors based on variant
    Color bgColor;
    Color txtColor;
    Color borderColor;
    
    switch (widget.variant) {
      case ButtonVariant.filled:
        bgColor = widget.backgroundColor ?? AppTheme.primaryColor;
        txtColor = widget.textColor ?? Colors.white;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.outlined:
        bgColor = Colors.transparent;
        txtColor = widget.textColor ?? AppTheme.primaryColor;
        borderColor = widget.backgroundColor ?? AppTheme.primaryColor;
        break;
      case ButtonVariant.text:
        bgColor = Colors.transparent;
        txtColor = widget.textColor ?? AppTheme.primaryColor;
        borderColor = Colors.transparent;
        break;
      case ButtonVariant.tonal:
        bgColor = widget.backgroundColor?.withOpacity(0.1) ?? 
                 AppTheme.primaryColor.withOpacity(0.1);
        txtColor = widget.textColor ?? AppTheme.primaryColor;
        borderColor = Colors.transparent;
        break;
    }
    
    // Create button content
    Widget buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            height: iconSize + 2,
            width: iconSize + 2,
            child: CircularProgressIndicator(
              color: txtColor,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: iconSize),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: txtColor,
          ),
        ),
      ],
    );
    
    // Create button with animation
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onPressed == null ? 1.0 : _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed,
        child: Container(
          width: widget.fullWidth ? double.infinity : widget.width,
          height: widget.height ?? buttonHeight,
          decoration: BoxDecoration(
            color: widget.onPressed == null 
                ? bgColor.withOpacity(0.5) 
                : _isPressed 
                    ? bgColor.withOpacity(0.8) 
                    : bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.onPressed == null 
                  ? borderColor.withOpacity(0.5) 
                  : borderColor,
              width: widget.variant == ButtonVariant.outlined ? 2 : 0,
            ),
            boxShadow: widget.elevated && widget.variant != ButtonVariant.text
                ? [
                    BoxShadow(
                      color: bgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: widget.padding ?? 
                  EdgeInsets.symmetric(
                    horizontal: widget.size == ButtonSize.small ? 12 : 16,
                  ),
          child: buttonContent,
        ),
      ),
    );
  }
}
