import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import '../state/locale_provider.dart';

class LanguageTogglePill extends ConsumerWidget {
  const LanguageTogglePill({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final isOdia = language == AppLanguage.odia;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2ECE0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillButton(
            label: 'ଓଡ଼ିଆ',
            isActive: isOdia,
            onTap: () {
              ref.read(localeProvider.notifier).setLanguage(AppLanguage.odia);
            },
          ),
          _buildPillButton(
            label: 'English',
            isActive: !isOdia,
            onTap: () {
              ref.read(localeProvider.notifier).setLanguage(AppLanguage.english);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
