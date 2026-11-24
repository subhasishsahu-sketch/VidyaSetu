import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class ConceptVsLanguageGrowthGraph extends StatelessWidget {
  final bool isOdia;

  const ConceptVsLanguageGrowthGraph({
    Key? key,
    required this.isOdia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isOdia
                      ? 'ବୃଦ୍ଧି ବିଶ୍ଳେଷଣ (Growth Analytics)'
                      : 'Concept Mastery vs Bilingual Efficiency',
                  style: AppTypography.titleMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Gap Closing: +36%',
                  style: AppTypography.labelSmallBold(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isOdia
                ? 'ମୂଳ ଧାରଣା ଦକ୍ଷତା ଏବଂ ଇଂରାଜୀ ଶବ୍ଦାବଳୀର ତୁଳନା'
                : 'Comparing Core Concept Mastery vs. English Technical Vocabulary',
            style: AppTypography.bodySmallMuted(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx <= 2) {
                          return Text(
                            'Ch ${idx + 1}',
                            style: AppTypography.labelSmall(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}%',
                          style: AppTypography.labelSmall(),
                        );
                      },
                    ),
                  ),
                ),
                minX: 0,
                maxX: 2,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  // Concept Growth Line (Paddy Green)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 68),
                      FlSpot(1, 78),
                      FlSpot(2, 85),
                    ],
                    isCurved: true,
                    color: AppColors.primaryPaddyGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  // Bilingual Language Efficiency Line (Terracotta Amber)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 35),
                      FlSpot(1, 56),
                      FlSpot(2, 78),
                    ],
                    isCurved: true,
                    color: AppColors.accentTerracotta,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(
                AppColors.primaryPaddyGreen,
                isOdia ? 'ଧାରଣା ଦକ୍ଷତା' : 'Concept Mastery (85%)',
              ),
              const SizedBox(width: 16),
              _buildLegend(
                AppColors.accentTerracotta,
                isOdia ? 'ଦ୍ୱିଭାଷୀ ଦକ୍ଷତା' : 'Bilingual Efficiency (78%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall()),
      ],
    );
  }
}
