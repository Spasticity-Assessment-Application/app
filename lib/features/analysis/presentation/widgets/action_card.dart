import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSecondary;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSecondary ? const Color(0xFFF5F5F5) : Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: isSecondary
                ? Border.all(color: const Color(0xFFE0E0E0), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSecondary
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSecondary ? Colors.black : Colors.white,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isSecondary ? Colors.black : Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSecondary
                            ? Colors.grey.shade600
                            : Colors.white.withValues(alpha: 0.8),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isSecondary
                    ? Colors.grey.shade400
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
