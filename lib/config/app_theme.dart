import 'package:flutter/material.dart';

class AppTheme {
  // Palette de couleurs principale améliorée
  static const Color primaryColor = Color(0xFF5E35B1);      // Violet profond
  static const Color primaryLightColor = Color(0xFF9162E4); // Violet clair
  static const Color primaryDarkColor = Color(0xFF3B1F7A);  // Violet foncé
  
  static const Color secondaryColor = Color(0xFFFF6D00);    // Orange vif
  static const Color secondaryLightColor = Color(0xFFFF9E40); // Orange clair
  static const Color secondaryDarkColor = Color(0xFFD55800); // Orange foncé
  
  static const Color accentColor = Color(0xFF00BCD4);       // Cyan
  static const Color accentLightColor = Color(0xFF62EFFF);  // Cyan clair
  static const Color accentDarkColor = Color(0xFF008BA3);   // Cyan foncé
  
  // Couleurs sémantiques
  static const Color successColor = Color(0xFF43A047);      // Vert
  static const Color errorColor = Color(0xFFE53935);        // Rouge
  static const Color warningColor = Color(0xFFFFB300);      // Ambre
  static const Color infoColor = Color(0xFF2196F3);         // Bleu
  
  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFF5F5F5);   // Gris très clair
  static const Color surfaceColor = Colors.white;           // Blanc
  static const Color cardColor = Colors.white;              // Blanc
  
  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF212121);  // Gris très foncé
  static const Color textSecondaryColor = Color(0xFF757575); // Gris
  static const Color textLightColor = Color(0xFFBDBDBD);    // Gris clair
  static const Color textDisabledColor = Color(0xFFBDBDBD); // Gris clair
   static const Color dividerColor = Color(0xFFE2E8F0);
  
  // Couleurs de fond pour le mode sombre
  static const Color darkBackgroundColor = Color(0xFF121212);    // Noir presque pur
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);       // Gris très foncé
  static const Color darkCardColor = Color(0xFF2C2C2C);          // Gris foncé
  
  // Couleurs de texte pour le mode sombre
  static const Color darkTextPrimaryColor = Colors.white;
  static const Color darkTextSecondaryColor = Color(0xFFB0B0B0); // Gris clair
  static const Color darkTextLightColor = Color(0xFF757575);     // Gris

  // Thème clair
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    primaryColorLight: primaryLightColor,
    primaryColorDark: primaryDarkColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryLightColor,
      secondary: secondaryColor,
      secondaryContainer: secondaryLightColor,
      tertiary: accentColor,
      tertiaryContainer: accentLightColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onBackground: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: textLightColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: textLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: textSecondaryColor),
      hintStyle: const TextStyle(color: textLightColor),
    ),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimaryColor),
      bodyMedium: TextStyle(color: textPrimaryColor),
      bodySmall: TextStyle(color: textSecondaryColor),
      labelLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: textSecondaryColor),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return textLightColor;
        }
        return primaryColor;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return textLightColor;
        }
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return textLightColor.withOpacity(0.5);
        }
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
  );

  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    primaryColorLight: primaryLightColor,
    primaryColorDark: primaryDarkColor,
    colorScheme: ColorScheme.dark(
      primary: primaryLightColor,
      primaryContainer: primaryColor,
      secondary: secondaryLightColor,
      secondaryContainer: secondaryColor,
      tertiary: accentLightColor,
      tertiaryContainer: accentColor,
      background: darkBackgroundColor,
      surface: darkSurfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onBackground: darkTextPrimaryColor,
      onSurface: darkTextPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkCardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      selectedItemColor: accentColor,
      unselectedItemColor: darkTextSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: const BorderSide(color: accentColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: darkTextSecondaryColor),
      hintStyle: const TextStyle(color: darkTextLightColor),
    ),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: darkTextPrimaryColor),
      bodyMedium: TextStyle(color: darkTextPrimaryColor),
      bodySmall: TextStyle(color: darkTextSecondaryColor),
      labelLarge: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: darkTextPrimaryColor, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: darkTextSecondaryColor),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: darkCardColor,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3E3E3E),
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return darkTextLightColor;
        }
        return accentColor;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return darkTextLightColor;
        }
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return darkTextLightColor.withOpacity(0.5);
        }
        if (states.contains(WidgetState.selected)) {
          return accentColor.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
  );
}
