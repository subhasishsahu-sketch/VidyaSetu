import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// VidyaSetu Typography System
/// English: Plus Jakarta Sans
/// Odia: Noto Sans Odia with appropriate fallback and scaling
class AppTypography {
  static TextStyle headlineLarge({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle headlineMedium({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );

  static TextStyle headlineSmall({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );

  static TextStyle titleMedium({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleSmall({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyLargeOdia({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.notoSansOriya(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );

  static TextStyle bodyLargeEnglish({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodySmallMuted({Color color = AppColors.textMutedOlive}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelSmall({Color color = AppColors.textMutedOlive}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelSmallBold({Color color = AppColors.primaryPaddyGreen}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle captionBold({Color color = AppColors.textHighContrast}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
