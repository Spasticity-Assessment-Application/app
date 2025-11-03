import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;

  // nouveau:
  final bool showBack;
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.title,
    this.foregroundColor = Colors.black,
    this.padding = const EdgeInsets.only(
      left: 8.0,
      right: 8.0,
      top: 8.0,
      bottom: 16.0,
    ),
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: foregroundColor,
                size: 20,
              ),
              splashRadius: 20,
              onPressed: onBack ?? () => context.pop(),
            )
          else
            const SizedBox(width: 48),

          const SizedBox(width: 4),

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
