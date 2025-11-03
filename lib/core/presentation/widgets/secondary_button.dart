import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final Color backgroundColor;
  final Color borderColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = EdgeInsets.zero,
    this.textStyle,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFE5E5E5),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          padding: padding,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: textStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                letterSpacing: -0.2,
              ),
        ),
      ),
    );
  }
}
