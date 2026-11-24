import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/explanation.dart';

class ComparisonCards extends StatelessWidget {
  final List<ComparisonCardData> cards;

  const ComparisonCards({Key? key, required this.cards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cards.map((item) {
        final isTerracotta = item.colorType == 'terracotta';
        final bgColor =
            isTerracotta ? const Color(0xFFFBECE6) : const Color(0xFFEAF5E8);
        final iconColor = isTerracotta
            ? AppColors.accentTerracotta
            : AppColors.primaryPaddyGreen;
        final icon = isTerracotta ? Icons.domain_rounded : Icons.account_balance_rounded;

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.titleSmall(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.scope,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isTerracotta
                              ? AppColors.terracottaDark
                              : AppColors.primaryDarkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
