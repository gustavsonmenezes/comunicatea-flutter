import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais - Paleta baseada em Soft UI para Neurodiversidade
  static const Color primaryColor = Color(0xFFA2D2FF); // Sky Blue (Calmante)
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color secondaryColor = Color(0xFFBEE1E6); // Soft Mint (Foco)
  static const Color accentColor = Color(0xFFFAD2E1); // Dusty Rose (Suave)
  static const Color successColor = Color(0xFFC7E9B0); // Verde Pastel
  static const Color warningColor = Color(0xFFFFF4BD); // Amarelo Pastel
  static const Color errorColor = Color(0xFFFFCCBB); // Coral Pastel

  // Cores neutras
  static const Color backgroundColor = Color(0xFFF8F9FA); // Warm Gray (Baixo brilho)
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF2D3436); // Cinza muito escuro (menos que preto)
  static const Color textSecondaryColor = Color(0xFF636E72);
  static const Color borderColor = Color(0xFFDFE6E9);

  // Tema Light
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: textPrimaryColor,
      secondary: secondaryColor,
      onSecondary: textPrimaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,

    // AppBar - Estilo Clean
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimaryColor,
        fontFamily: 'Quicksand',
      ),
    ),

    // Tipografia Arredondada e Espaçada
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: textPrimaryColor,
        fontFamily: 'Quicksand',
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: textPrimaryColor,
        fontFamily: 'Quicksand',
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
        color: textPrimaryColor,
        fontFamily: 'Quicksand',
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
        color: textPrimaryColor,
        fontFamily: 'Quicksand',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        letterSpacing: 0.2,
        color: textPrimaryColor,
        fontFamily: 'Quicksand',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        letterSpacing: 0.2,
        color: textSecondaryColor,
        fontFamily: 'Quicksand',
      ),
    ),

    // Botões com Bordas Bem Arredondadas (Soft UI)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Quicksand',
        ),
      ),
    ),

    // CARDS - O coração do Bento Grid
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),

    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.3);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 0,
    ),
  );

  // Tema Dark (opcional para modo de alto contraste)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: errorColor,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
