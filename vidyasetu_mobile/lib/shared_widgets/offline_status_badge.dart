import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../state/health_provider.dart';

class OfflineStatusBadge extends ConsumerWidget {
  final String? overrideText;

  const OfflineStatusBadge({
    Key? key,
    this.overrideText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthStateProvider);
    final isOnline = healthState.isOnline;
    final isSyncing = healthState.isSyncing;
    final pendingCount = healthState.pendingQueueCount;

    final badgeColor = isOnline ? AppColors.successGreen : AppColors.primaryPaddyGreen;
    final badgeBg = isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFE5F4E7);
    final badgeBorder = isOnline ? const Color(0xFFC8E6C9) : const Color(0xFFCCE8CF);

    final text = overrideText ??
        (isOnline
            ? 'Cloud Connected'
            : (pendingCount > 0
                ? '$pendingCount Pending Sync • Offline SLM'
                : '100% Offline SLM'));

    return InkWell(
      onTap: () {
        // Trigger manual refresh & queue sync
        ref.read(healthStateProvider.notifier).syncQueue();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTypography.labelSmallBold(color: badgeColor),
            ),
            if (isSyncing) ...[
              const SizedBox(width: 6),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPaddyGreen,
                ),
              ),
            ] else if (isOnline && pendingCount > 0) ...[
              const SizedBox(width: 4),
              const Icon(Icons.sync, size: 12, color: AppColors.primaryPaddyGreen),
            ],
          ],
        ),
      ),
    );
  }
}
