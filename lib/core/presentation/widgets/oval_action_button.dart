import 'package:flutter/material.dart';

enum OvalActionButtonVariant {
  dark,
  light,
}

class OvalActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final OvalActionButtonVariant variant;

  const OvalActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = variant == OvalActionButtonVariant.dark;

    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: isDark
            ? null
            : Border.all(
                color: const Color(0xFFE5E5E5),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.25 : 0.15,
            ),
            blurRadius: isDark ? 20 : 25,
            offset: Offset(0, isDark ? 12 : 15),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
