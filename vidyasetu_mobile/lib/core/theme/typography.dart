import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// VidyaSetu Typography System
/// English: Plus Jakarta Sans
/// Odia: Noto Sans Odia with offline-safe font fallback
class AppTypography {
  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    bool isOdia = false,
  }) {
    try {
      if (isOdia) {
        return GoogleFonts.notoSansOriya(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      }
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    } catch (_) {
      // Safe offline fallback in Airplane Mode
      return TextStyle(
        fontFamily: isOdia ? 'Noto Sans Oriya' : 'Plus Jakarta Sans',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
  }

  static TextStyle headlineLarge({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.25);

  static TextStyle headlineMedium({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1.3);

  static TextStyle headlineSmall({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 18, fontWeight: FontWeight.w700, color: color, height: 1.3);

  static TextStyle titleMedium({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextStyle titleSmall({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyLarge({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodyLargeOdia({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.6, isOdia: true);

  static TextStyle bodyLargeEnglish({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle bodyMedium({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 13, fontWeight: FontWeight.w400, color: color, height: 1.45);

  static TextStyle bodySmall({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle bodySmallMuted({Color color = AppColors.textMutedOlive}) =>
      _font(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle labelSmall({Color color = AppColors.textMutedOlive}) =>
      _font(fontSize: 11, fontWeight: FontWeight.w500, color: color);

  static TextStyle labelSmallBold({Color color = AppColors.primaryPaddyGreen}) =>
      _font(fontSize: 11, fontWeight: FontWeight.w700, color: color);

  static TextStyle captionBold({Color color = AppColors.textHighContrast}) =>
      _font(fontSize: 12, fontWeight: FontWeight.w600, color: color);
}
