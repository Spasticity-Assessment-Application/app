import 'package:flutter/material.dart';
import '../../../domain/leg_side.dart';

class LegSideOptions extends StatelessWidget {
  final LegSide selectedLegSide;
  final ValueChanged<LegSide> onLegSideChanged;

  const LegSideOptions({
    super.key,
    required this.selectedLegSide,
    required this.onLegSideChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LegSideOption(
          legSide: LegSide.right,
          isSelected: selectedLegSide == LegSide.right,
          onTap: () => onLegSideChanged(LegSide.right),
        ),
        const SizedBox(height: 20),
        LegSideOption(
          legSide: LegSide.left,
          isSelected: selectedLegSide == LegSide.left,
          onTap: () => onLegSideChanged(LegSide.left),
        ),
      ],
    );
  }
}

class LegSideOption extends StatelessWidget {
  final LegSide legSide;
  final bool isSelected;
  final VoidCallback onTap;

  const LegSideOption({
    super.key,
    required this.legSide,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForLegSide(legSide),
                color: isSelected ? Colors.white : Colors.black87,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    legSide.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescriptionForLegSide(legSide),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 28)
            else
              Icon(
                Icons.circle_outlined,
                color: const Color(0xFFE5E5E5),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLegSide(LegSide legSide) {
    return legSide == LegSide.right ? Icons.arrow_forward : Icons.arrow_back;
  }

  String _getDescriptionForLegSide(LegSide legSide) {
    return legSide == LegSide.right
        ? 'Vidéo de la jambe droite du patient'
        : 'Vidéo de la jambe gauche du patient';
  }
}
