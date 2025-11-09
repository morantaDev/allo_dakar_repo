import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 Design System TéMove - Ultra-moderne et dynamique
/// Palette moderne : Bleu électrique, Violet-rose dégradé, Turquoise néon
/// Typographie : Inter (moderne, lisible)
/// Style : Minimaliste, mobile-first, flat design avec ombres douces
/// Border-radius : 16px minimum pour un design moderne et fluide
class AppTheme {
  // ============================================
  // 🎨 Couleurs principales - Palette moderne et dynamique
  // ============================================
  /// Bleu électrique / néon (couleur primaire) - #3B82F6
  /// Utilisé pour : boutons principaux, highlights, icônes importantes
  static const Color primaryColor = Color(0xFF3B82F6);
  
  /// Violet vibrant (couleur secondaire) - #8B5CF6
  /// Utilisé pour : fonds de cartes, overlays, boutons secondaires
  static const Color secondaryColor = Color(0xFF8B5CF6);
  
  /// Rose vibrant (accent) - #EC4899
  /// Utilisé pour : animations, dégradés, éléments d'accentuation
  static const Color accentColor = Color(0xFFEC4899);
  
  // ============================================
  // 🌈 Dégradés et couleurs dynamiques
  // ============================================
  /// Dégradé violet → rose (pour animations et overlays)
  static const LinearGradient purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );
  
  /// Dégradé bleu → violet (pour boutons premium)
  static const LinearGradient bluePurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  );
  
  // ============================================
  // 💎 Nuances de couleurs principales
  // ============================================
  // Nuances de bleu
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color blueDark = Color(0xFF2563EB);
  static const Color blueNeon = Color(0xFF3B82F6);
  
  // Nuances de violet
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color violetDark = Color(0xFF7C3AED);
  static const Color violetVibrant = Color(0xFF8B5CF6);
  
  // Nuances de rose
  static const Color roseLight = Color(0xFFF472B6);
  static const Color roseDark = Color(0xFFDB2777);
  static const Color roseVibrant = Color(0xFFEC4899);
  
  // ============================================
  // 🌫️ Nuances de gris (gris foncé moderne)
  // ============================================
  /// Gris foncé / presque noir - #111827
  /// Utilisé pour : fonds, textes, éléments neutres
  static const Color grayDarkest = Color(0xFF111827);
  static const Color grayDark = Color(0xFF1F2937);
  static const Color grayMedium = Color(0xFF374151);
  static const Color grayLight = Color(0xFF6B7280);
  static const Color grayLighter = Color(0xFF9CA3AF);
  static const Color grayLightest = Color(0xFFD1D5DB);
  
  // ============================================
  // 🎯 Couleurs de fond
  // ============================================
  /// Fond principal (gris foncé moderne) - #111827
  static const Color backgroundColor = Color(0xFF111827);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF111827);
  
  /// Surfaces (cartes, conteneurs)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceViolet = Color(0xFF8B5CF6);
  
  // ============================================
  // 📝 Couleurs de texte
  // ============================================
  /// Texte principal (blanc sur fonds foncés)
  static const Color textPrimary = Color(0xFFFFFFFF);
  /// Texte secondaire (gris foncé sur fonds clairs)
  static const Color textSecondary = Color(0xFF111827);
  /// Texte atténué (gris moyen)
  static const Color textMuted = Color(0xFF9CA3AF);
  /// Texte secondaire sur fonds foncés
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  
  // ============================================
  // ✅ Couleurs sémantiques
  // ============================================
  /// Turquoise néon / cyan - #06B6D4
  /// Utilisé pour : confirmations, succès, états actifs
  static const Color successColor = Color(0xFF06B6D4);
  
  /// Rouge corail moderne - #F43F5E
  /// Utilisé pour : alertes, erreurs (harmonie avec la palette)
  static const Color errorColor = Color(0xFFF43F5E);
  
  /// Orange/Warning (pour avertissements)
  static const Color warningColor = Color(0xFFF59E0B);
  
  /// Info (bleu clair)
  static const Color infoColor = Color(0xFF3B82F6);
  
  // ============================================
  // 🎨 Couleurs d'accentuation (héritées pour compatibilité)
  // ============================================
  /// Alias pour compatibilité (utilise turquoise)
  static const Color greenLight = Color(0xFF34D399);
  static const Color greenDark = Color(0xFF059669);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDark, // #111827
      colorScheme: const ColorScheme.dark(
        primary: primaryColor, // Bleu électrique
        secondary: secondaryColor, // Violet vibrant
        tertiary: accentColor, // Rose vibrant
        surface: surfaceDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondaryDark,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surfaceDark, // #1F2937
        foregroundColor: textPrimary,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primaryColor, // Bleu électrique
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor, // Bleu électrique
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: grayMedium, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: grayMedium, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondaryDark,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: grayLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceDark,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor, // Bleu électrique
        secondary: secondaryColor, // Violet vibrant
        tertiary: accentColor, // Rose vibrant
        surface: Colors.white,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textSecondary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textSecondary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textSecondary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textSecondary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: grayMedium,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: primaryColor, // Bleu électrique
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primaryColor, // Bleu électrique
          foregroundColor: Colors.white,
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
          side: const BorderSide(color: primaryColor, width: 2), // Bleu électrique
          foregroundColor: primaryColor,
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
          foregroundColor: primaryColor, // Bleu électrique
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: grayLightest, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: grayLightest, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2), // Bleu électrique
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: grayMedium,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: grayLighter,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceLight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor, // Bleu électrique
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
  
  // ============================================
  // 🎨 Helpers pour les dégradés
  // ============================================
  /// Créer un dégradé violet-rose personnalisé
  /// Utilisé pour : fonds de cartes, overlays, animations
  static LinearGradient createPurplePinkGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [secondaryColor, accentColor],
    );
  }
  
  /// Créer un dégradé bleu-violet personnalisé
  /// Utilisé pour : boutons premium, éléments spéciaux
  static LinearGradient createBluePurpleGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [primaryColor, secondaryColor],
    );
  }
  
  /// Créer un dégradé bleu-turquoise (pour succès/confirmations)
  /// Utilisé pour : états de succès, confirmations
  static LinearGradient createBlueCyanGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [primaryColor, successColor],
    );
  }
  
  /// Créer un dégradé violet-rose avec opacité pour overlays
  /// Utilisé pour : overlays, backgrounds avec transparence
  static LinearGradient createPurplePinkGradientWithOpacity({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double opacity = 0.8,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        secondaryColor.withOpacity(opacity),
        accentColor.withOpacity(opacity),
      ],
    );
  }
}

