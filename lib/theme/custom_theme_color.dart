import 'package:flutter/material.dart';

class CustomThemeColors extends ThemeExtension<CustomThemeColors> {
  final Color blackColor;
  final Color infoColor;
  final Color primaryColor;
  final Color secondaryColor;

  const CustomThemeColors({
    required this.blackColor,
    required this.infoColor,
    this.primaryColor = const Color(0xFF8B1236),
    this.secondaryColor = const Color(0xFFC37B91),
  });

  // Predefined themes for light and dark modes
  factory CustomThemeColors.light() => const CustomThemeColors(
        blackColor: Color(0xFF000000),
        infoColor: Color(0xFF0177CD),
        primaryColor: Color(0xFF8B1236),
        secondaryColor: Color(0xFFC37B91),
      );

  factory CustomThemeColors.dark() => const CustomThemeColors(
        blackColor: Color(0xFFFFFFFF),
        infoColor: Color(0xFF0177CD),
        primaryColor: Color(0xFF9E1B40),
        secondaryColor: Color(0xFFC37B91),
      );

  @override
  CustomThemeColors copyWith({
    Color? blackColor,
    Color? infoColor,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return CustomThemeColors(
      blackColor: blackColor ?? this.blackColor,
      infoColor: infoColor ?? this.infoColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }

  @override
  CustomThemeColors lerp(ThemeExtension<CustomThemeColors>? other, double t) {
    if (other is! CustomThemeColors) return this;

    return CustomThemeColors(
      blackColor: Color.lerp(blackColor, other.blackColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
    );
  }
}