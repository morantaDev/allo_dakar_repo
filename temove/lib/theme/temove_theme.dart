/// Thème moderne et cohérent pour TéMove
/// 
/// Identité visuelle :
/// - Couleurs principales : Jaune #FFD60A, Noir profond #0C0C0C, Vert doux #00C897
/// - Typographie : Inter ou Poppins
/// - Style : Minimaliste, mobile-first, flat design avec coins arrondis (16px+)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleurs TéMove
class TeMoveColors {
  // Couleurs principales
  static const Color primaryYellow = Color(0xFFFFD60A); // #FFD60A
  static const Color deepBlack = Color(0xFF0C0C0C); // #0C0C0C
  static const Color softGreen = Color(0xFF00C897); // #00C897
  
  // Nuances de jaune
  static const Color yellowLight = Color(0xFFFFE766);
  static const Color yellowDark = Color(0xFFCCAA08);
  
  // Nuances de noir/gris
  static const Color blackPrimary = Color(0xFF0C0C0C);
  static const Color blackSecondary = Color(0xFF1A1A1A);
  static const Color grayDark = Color(0xFF2C2C2C);
  static const Color grayMedium = Color(0xFF4A4A4A);
  static const Color grayLight = Color(0xFF6E6E6E);
  static const Color grayLighter = Color(0xFF9E9E9E);
  static const Color grayLightest = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  
  // Nuances de vert
  static const Color greenLight = Color(0xFF33D4A6);
  static const Color greenDark = Color(0xFF009A6E);
  
  // Couleurs sémantiques
  static const Color success = softGreen;
  static const Color error = Color(0xFFE63946);
  static const Color warning = Color(0xFFFFB703);
  static const Color info = Color(0xFF219EBC);
  
  // Couleurs de fond
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF0C0C0C);
  static const Color surfaceLight = white;
  static const Color surfaceDark = Color(0xFF1A1A1A);
  
  // Couleurs de texte
  static const Color textPrimaryLight = Color(0xFF0C0C0C);
  static const Color textSecondaryLight = Color(0xFF4A4A4A);
  static const Color textPrimaryDark = white;
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
}

/// Thème TéMove moderne
class TeMoveTheme {
  /// Obtenir le thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: TeMoveColors.primaryYellow,
        secondary: TeMoveColors.softGreen,
        surface: TeMoveColors.surfaceLight,
        background: TeMoveColors.backgroundLight,
        error: TeMoveColors.error,
        onPrimary: TeMoveColors.deepBlack,
        onSecondary: TeMoveColors.white,
        onSurface: TeMoveColors.textPrimaryLight,
        onBackground: TeMoveColors.textPrimaryLight,
        onError: TeMoveColors.white,
      ),
      scaffoldBackgroundColor: TeMoveColors.backgroundLight,
      
      // Typographie
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: TeMoveColors.textPrimaryLight,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: TeMoveColors.textPrimaryLight,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: TeMoveColors.textPrimaryLight,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryLight,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryLight,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryLight,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryLight,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryLight,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: TeMoveColors.textPrimaryLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: TeMoveColors.textSecondaryLight,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: TeMoveColors.textSecondaryLight,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textPrimaryLight,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textSecondaryLight,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textSecondaryLight,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: TeMoveColors.primaryYellow,
        foregroundColor: TeMoveColors.deepBlack,
        iconTheme: const IconThemeData(color: TeMoveColors.deepBlack),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.deepBlack,
          letterSpacing: -0.3,
        ),
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: TeMoveColors.primaryYellow,
          foregroundColor: TeMoveColors.deepBlack,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: TeMoveColors.primaryYellow, width: 2),
          foregroundColor: TeMoveColors.primaryYellow,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: TeMoveColors.primaryYellow,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TeMoveColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: TeMoveColors.grayLightest, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: TeMoveColors.grayLightest, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TeMoveColors.primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TeMoveColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TeMoveColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textSecondaryLight,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: TeMoveColors.grayLighter,
        ),
      ),
      
      // Cartes
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: TeMoveColors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      
      // Dialogues
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: TeMoveColors.white,
        elevation: 8,
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: TeMoveColors.white,
        elevation: 8,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: TeMoveColors.grayLightest,
        selectedColor: TeMoveColors.primaryYellow,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TeMoveColors.primaryYellow,
        foregroundColor: TeMoveColors.deepBlack,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: TeMoveColors.grayLightest,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  /// Obtenir le thème sombre
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: TeMoveColors.primaryYellow,
        secondary: TeMoveColors.softGreen,
        surface: TeMoveColors.surfaceDark,
        background: TeMoveColors.backgroundDark,
        error: TeMoveColors.error,
        onPrimary: TeMoveColors.deepBlack,
        onSecondary: TeMoveColors.white,
        onSurface: TeMoveColors.textPrimaryDark,
        onBackground: TeMoveColors.textPrimaryDark,
        onError: TeMoveColors.white,
      ),
      scaffoldBackgroundColor: TeMoveColors.backgroundDark,
      
      // Typographie (même structure que light, mais avec couleurs sombres)
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: TeMoveColors.textPrimaryDark,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: TeMoveColors.textPrimaryDark,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: TeMoveColors.textPrimaryDark,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: TeMoveColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: TeMoveColors.textSecondaryDark,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: TeMoveColors.textSecondaryDark,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textPrimaryDark,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textSecondaryDark,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textSecondaryDark,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: TeMoveColors.surfaceDark,
        foregroundColor: TeMoveColors.textPrimaryDark,
        iconTheme: const IconThemeData(color: TeMoveColors.textPrimaryDark),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TeMoveColors.textPrimaryDark,
          letterSpacing: -0.3,
        ),
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: TeMoveColors.primaryYellow,
          foregroundColor: TeMoveColors.deepBlack,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: TeMoveColors.primaryYellow, width: 2),
          foregroundColor: TeMoveColors.primaryYellow,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: TeMoveColors.primaryYellow,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TeMoveColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: TeMoveColors.grayMedium, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: TeMoveColors.grayMedium, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TeMoveColors.primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TeMoveColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TeMoveColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: TeMoveColors.textSecondaryDark,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: TeMoveColors.grayLight,
        ),
      ),
      
      // Cartes
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: TeMoveColors.surfaceDark,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      
      // Dialogues
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: TeMoveColors.surfaceDark,
        elevation: 8,
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: TeMoveColors.surfaceDark,
        elevation: 8,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: TeMoveColors.grayDark,
        selectedColor: TeMoveColors.primaryYellow,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TeMoveColors.primaryYellow,
        foregroundColor: TeMoveColors.deepBlack,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: TeMoveColors.grayMedium,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  /// Obtenir le thème selon la luminosité du système
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}

/// Constantes de design
class TeMoveDesign {
  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusCircular = 999.0;
  
  // Espacements
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Ombres
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Durées d'animation
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Courbes d'animation
  static const Curve animationCurve = Curves.easeInOutCubic;
}

