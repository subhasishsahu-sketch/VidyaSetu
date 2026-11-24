import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/explanation.dart';

class RourkelaReferenceCard extends StatelessWidget {
  final HistoricalReference reference;

  const RourkelaReferenceCard({Key? key, required this.reference})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderHairline),
      ),
      child: Row(
        children: [
          // Historical photo placeholder matching archive look in Screenshot 2
          Container(
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFD6DFD5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.photo_library_outlined,
                color: AppColors.secondarySage,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textMutedOlive),
                    const SizedBox(width: 4),
                    Text(
                      reference.location,
                      style: AppTypography.labelSmallBold(
                        color: AppColors.textHighContrast,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reference.description,
                  style: AppTypography.bodySmallMuted(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reference.archiveLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMutedOlive,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
