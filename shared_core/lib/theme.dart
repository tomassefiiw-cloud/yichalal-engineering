import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified Yichalal palette — warm orange primary, soft mint accent.
/// Same colors and tokens in Customer & Mechanic apps for unified branding.
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

  // Dark-mode tokens
  static const darkCard = Color(0xFF1A1C24);
  static const darkBorder = Color(0xFF2B2E38);
  static const darkText = Color(0xFFEDEEF2);
  static const darkTextMute = Color(0xFFA8ADBC);
}

class AppTheme {
  static ThemeData light({Color primary = AppColors.orange}) {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary, brightness: Brightness.light,
        primary: primary, secondary: AppColors.mint,
        surface: AppColors.card, onSurface: AppColors.text,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card, foregroundColor: AppColors.text, elevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 17),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      cardTheme: CardTheme(
        elevation: 0, color: AppColors.card, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.6)),
        labelStyle: GoogleFonts.poppins(color: AppColors.textMute, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMute),
        prefixIconColor: AppColors.textMute,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.orangeLight,
        selectedColor: primary,
        labelStyle: GoogleFonts.poppins(color: AppColors.orangeDark, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed, backgroundColor: AppColors.card,
        selectedItemColor: primary, unselectedItemColor: AppColors.textMute, showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 17),
        contentTextStyle: GoogleFonts.poppins(color: AppColors.text, fontSize: 14),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMute,
        textColor: AppColors.text,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    );
  }

  static ThemeData dark({Color primary = AppColors.orange}) {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.darkText, displayColor: AppColors.darkText);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary, brightness: Brightness.dark,
        primary: primary, secondary: AppColors.mint,
        surface: AppColors.darkCard, onSurface: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.oil,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.darkText),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.gunmetal, foregroundColor: AppColors.darkText, elevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 17),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardTheme(
        elevation: 0, color: AppColors.darkCard, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.6)),
        labelStyle: GoogleFonts.poppins(color: AppColors.darkTextMute, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.poppins(color: AppColors.darkTextMute),
        prefixIconColor: AppColors.darkTextMute,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A1F18),
        selectedColor: primary,
        labelStyle: GoogleFonts.poppins(color: AppColors.orangeLight, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed, backgroundColor: AppColors.gunmetal,
        selectedItemColor: primary, unselectedItemColor: AppColors.darkTextMute, showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 17),
        contentTextStyle: GoogleFonts.poppins(color: AppColors.darkText, fontSize: 14),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkTextMute,
        textColor: AppColors.darkText,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 1),
      tabBarTheme: TabBarTheme(
        labelColor: primary, unselectedLabelColor: AppColors.darkTextMute,
        indicatorColor: primary,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
      ),
    );
  }
}
