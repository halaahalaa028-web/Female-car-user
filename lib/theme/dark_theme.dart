import 'package:flutter/material.dart';
import 'package:ride_sharing_user_app/theme/custom_theme_color.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

ThemeData darkTheme = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF9E1B40),
  primaryColorDark: const Color(0xFF6E0D29),
  disabledColor: const Color(0xFF5A626A),
  scaffoldBackgroundColor: const Color(0xFF140E12),
  canvasColor: const Color(0xFF1A1217),
  shadowColor: Colors.black.withValues(alpha: 0.3),
  brightness: Brightness.dark,
  hintColor: const Color(0xFF9CA3AF),
  cardColor: const Color(0xFF22171E),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Color(0xFFD1D5DB)),
    bodyLarge: TextStyle(color: Color(0xFFF9FAFB)),
    titleMedium: TextStyle(color: Colors.white),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF9E1B40),
    error: Color(0xFFFF6767),
    surface: Color(0xFF22171E),
    secondary: Color(0xFFC37B91),
    tertiary: Color(0xFFD47A95),
    tertiaryContainer: Color(0xFF9E2A4B),
    secondaryContainer: Color(0xFFEE6464),
    onTertiary: Color(0xFFD9D9D9),
    onSecondary: Color(0xFFC37B91),
    onSecondaryContainer: Color(0xFFFED7AA),
    onTertiaryContainer: Color(0xFFB0BEC5),
    outline: Color(0xFF8B1236),
    onPrimaryContainer: Color(0xFF2E121C),
    errorContainer: Color(0xFF2A1515),
    primaryContainer: Color(0xFFFFA800),
    onSurface: Color(0xFFFCE7EC),
    onPrimary: Colors.white,
    inverseSurface: Color(0xFFF9FAFB),
    surfaceContainer: Color(0xFF2A1C25),
    secondaryFixedDim: Color(0xff808080),
  ),
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF9E1B40))),
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.dark(),
  ],
);

