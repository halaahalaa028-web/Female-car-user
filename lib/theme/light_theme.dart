import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ride_sharing_user_app/theme/custom_theme_color.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

ThemeData lightTheme = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF8B1236),
  primaryColorDark: const Color(0xFF6E0D29),
  disabledColor: const Color(0xFFBABFC4),
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  shadowColor: Colors.black.withValues(alpha: 0.05),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFF111827)),
    bodySmall: TextStyle(color: Color(0xFF6B7280)),
    bodyLarge: TextStyle(color: Color(0xFF1F2937)),
    titleMedium: TextStyle(color: Color(0xFF111827)),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Color(0xFFEEEEEE)),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9CA3AF),
  cardColor: Colors.white,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF8B1236),
    secondary: Color(0xFFC37B91),
    error: Color(0xFFFF6767),
    surface: Color(0xFFF3F4F6),
    tertiary: Color(0xFFD47A95),
    tertiaryContainer: Color(0xFF8B1236),
    secondaryContainer: Color(0xFFEE6464),
    onTertiary: Color(0xFFD9D9D9),
    onSecondary: Color(0xFFC37B91),
    onSecondaryContainer: Color(0xFFFCE7EC),
    onTertiaryContainer: Color(0xFF6E0D29),
    outline: Color(0xFFE5B8C4),
    onPrimaryContainer: Color(0xFFFFF0F3),
    primaryContainer: Color(0xFFFFA800),
    onErrorContainer: Color(0xFFFFE6AD),
    onPrimary: Colors.white,
    surfaceTint: Color(0xFF8B1236),
    errorContainer: Color(0xFFF6F6F6),
    inverseSurface: Color(0xFF1E1015),
    surfaceContainer: Color(0xFF0094FF),
    secondaryFixedDim: Color(0xff808080),
  ),
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B1236))),
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.light(),
  ],
);

