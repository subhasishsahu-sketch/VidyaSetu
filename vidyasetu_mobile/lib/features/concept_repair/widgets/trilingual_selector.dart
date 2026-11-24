import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../models/explanation.dart';

class TrilingualSelector extends StatelessWidget {
  final ExplanationMode selectedMode;
  final Function(ExplanationMode) onModeChanged;

  const TrilingualSelector({
    Key? key,
    required this.selectedMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2ECE0),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _buildSegment(
            icon: Icons.translate,
            label: 'Bilingual Mix',
            mode: ExplanationMode.bilingualMix,
          ),
          _buildSegment(
            label: 'ସମ୍ପୂର୍ଣ୍ଣ ଓଡ଼ିଆ',
            mode: ExplanationMode.pureOdia,
          ),
          _buildSegment(
            label: 'English',
            mode: ExplanationMode.pureEnglish,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    IconData? icon,
    required String label,
    required ExplanationMode mode,
  }) {
    final isSelected = selectedMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDarkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
