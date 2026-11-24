import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/subject.dart';

class SubjectPills extends StatelessWidget {
  final List<Subject> subjects;
  final String selectedSubjectId;
  final Function(String) onSelect;
  final bool isOdia;

  const SubjectPills({
    Key? key,
    required this.subjects,
    required this.selectedSubjectId,
    required this.onSelect,
    required this.isOdia,
  }) : super(key: key);

  IconData _getIcon(String code) {
    switch (code) {
      case 'HIST':
        return Icons.account_balance;
      case 'PHYS':
        return Icons.bolt;
      case 'BIO':
        return Icons.eco;
      case 'MATH':
        return Icons.calculate;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOdia ? 'ବିଷୟ ଚୟନ' : 'Explore Subjects / ବିଷୟ ସମୂହ',
              style: AppTypography.titleMedium(),
            ),
            Text(
              isOdia ? 'ସମସ୍ତ ବିଷୟ (୪)' : '4 Cached',
              style: AppTypography.labelSmallBold(
                color: AppColors.primaryPaddyGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: subjects.map((subject) {
              final isSelected = subject.id == selectedSubjectId;
              final label = isOdia
                  ? '${subject.nameOr} (${subject.nameOr})'
                  : '${subject.nameEn} (${subject.nameOr})';

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(subject.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPaddyGreen
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryPaddyGreen
                            : AppColors.chipBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIcon(subject.code),
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryPaddyGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textHighContrast,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF88D49E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
