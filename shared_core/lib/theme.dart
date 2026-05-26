import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Yichalal palette — warm orange primary, soft mint accent, professional and
/// fully visible in both light and dark mode.
class AppColors {
  static const orange = Color(0xFFF26B1F);
  static const orangeDark = Color(0xFFC85410);
  static const orangeLight = Color(0xFFFCE4D2);
  static const mint = Color(0xFF2EC4B6);
  static const mintDark = Color(0xFF1A8F84);
  static const steel = Color(0xFF2B2D42);
  static const gunmetal = Color(0xFF1F2129);
  static const oil = Color(0xFF111318);
  static const surface = Color(0xFFFAFAFC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFEDEFF3);
  static const text = Color(0xFF1B1D2A);
  static const textMute = Color(0xFF6E7587);
  static const danger = Color(0xFFE63946);
  static const success = Color(0xFF06A77D);
  static const warn = Color(0xFFF4A261);
}

class AppTheme {
  static ThemeData light({Color primary = AppColors.orange}) {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light, primary: primary, secondary: AppColors.mint),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card, foregroundColor: AppColors.text, elevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 17),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      cardTheme: CardTheme(elevation: 0, color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.6)),
        labelStyle: GoogleFonts.poppins(color: AppColors.textMute, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMute),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.orangeLight,
        labelStyle: GoogleFonts.poppins(color: AppColors.orangeDark, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed, backgroundColor: AppColors.card,
        selectedItemColor: primary, unselectedItemColor: AppColors.textMute, showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 11)),
      dialogTheme: DialogTheme(backgroundColor: AppColors.card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );
  }

  static ThemeData dark({Color primary = AppColors.orange}) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, primary: primary, secondary: AppColors.mint),
      scaffoldBackgroundColor: AppColors.oil,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(backgroundColor: AppColors.gunmetal, foregroundColor: Colors.white, elevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      cardTheme: CardTheme(elevation: 0, color: const Color(0xFF1A1C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF2B2E38)))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF1A1C24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2B2E38))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2B2E38))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.6))),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed, backgroundColor: AppColors.gunmetal,
        selectedItemColor: primary, unselectedItemColor: Colors.white60, showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 11)),
    );
  }
}
