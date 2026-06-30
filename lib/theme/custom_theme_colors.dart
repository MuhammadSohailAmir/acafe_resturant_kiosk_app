import 'package:flutter/material.dart';
import 'package:acafe_customer/theme/brand_colors.dart';

class CustomThemeColors extends ThemeExtension<CustomThemeColors> {
  final Color ongoingCardColor;
  final Color confirmedCardColor;
  final Color processingCardColor;
  final Color outForDeliveryCardColor;
  final Color analyticsTextColor;
  final Color deliveredCountColor;
  final Color lightGrayBackground;
  final Color offWhite;
  final Color cardShadowColor;
  final Color errorColor;
  final Color pendingColor;

  const CustomThemeColors({
    required this.ongoingCardColor,
    required this.confirmedCardColor,
    required this.processingCardColor,
    required this.outForDeliveryCardColor,
    required this.analyticsTextColor,
    required this.deliveredCountColor,
    required this.lightGrayBackground,
    required this.offWhite,
    required this.cardShadowColor,
    required this.errorColor,
    required this.pendingColor,
  });

  // Predefined themes for light and dark modes
  factory CustomThemeColors.light() => const CustomThemeColors(
    ongoingCardColor: Color(0xFFF8BA3F),
    confirmedCardColor: Color(0xFF5B7F12),
    processingCardColor: Color(0xFFBF83FF),
    outForDeliveryCardColor: Color(0xFF3CD856),
    analyticsTextColor: BrandColors.onBackground,
    deliveredCountColor: Color(0xFF6BBA79),
    lightGrayBackground: BrandColors.background,
    offWhite: BrandColors.background,
    cardShadowColor: BrandColors.primaryDark,
    errorColor: Color(0xFFFF6161),
    pendingColor: Color(0xFF1D95FF),
  );

  factory CustomThemeColors.dark() => const CustomThemeColors(
    ongoingCardColor: Color(0xFFfff7c6),
    confirmedCardColor: Color(0xFFdfe8c0),
    processingCardColor: Color(0xFFe3ccfe),
    outForDeliveryCardColor: Color(0xFFc4f1c6),
    analyticsTextColor: Color(0xFFdccecc),
    deliveredCountColor: Color(0xFFc9e6ce),
    lightGrayBackground: BrandColors.backgroundDark,
    offWhite: Color(0xFF030303),
    cardShadowColor: BrandColors.primaryDark,
    errorColor: Color(0xFFFF6141),
    pendingColor: Color(0xFF1D95FF),
  );

  @override
  CustomThemeColors copyWith({
    Color? ongoingCardColor,
    Color? confirmedCardColor,
    Color? processingCardColor,
    Color? outForDeliveryCardColor,
    Color? analyticsTextColor,
    Color? deliveredCountColor,
    Color? lightWhiteColor,
    Color? offWhite,
    Color? cardShadowColor,
    Color? errorColor,
    Color? pendingColor,
  }) {
    return CustomThemeColors(
      ongoingCardColor: ongoingCardColor ?? this.ongoingCardColor,
      confirmedCardColor: confirmedCardColor ?? this.confirmedCardColor,
      processingCardColor: processingCardColor ?? this.processingCardColor,
      outForDeliveryCardColor: outForDeliveryCardColor ?? this.outForDeliveryCardColor,
      analyticsTextColor: analyticsTextColor ?? this.analyticsTextColor,
      deliveredCountColor: deliveredCountColor ?? this.deliveredCountColor,
      lightGrayBackground: lightWhiteColor ?? lightGrayBackground,
      offWhite: offWhite ?? this.offWhite,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      errorColor: errorColor ?? this.errorColor,
      pendingColor: pendingColor ?? this.pendingColor,
    );
  }

  @override
  CustomThemeColors lerp(ThemeExtension<CustomThemeColors>? other, double t) {
    if (other is! CustomThemeColors) return this;

    return CustomThemeColors(
      ongoingCardColor: Color.lerp(ongoingCardColor, other.ongoingCardColor, t)!,
      confirmedCardColor: Color.lerp(confirmedCardColor, other.confirmedCardColor, t)!,
      processingCardColor: Color.lerp(processingCardColor, other.processingCardColor, t)!,
      outForDeliveryCardColor: Color.lerp(outForDeliveryCardColor, other.outForDeliveryCardColor, t)!,
      analyticsTextColor: Color.lerp(analyticsTextColor, other.analyticsTextColor, t)!,
      deliveredCountColor: Color.lerp(deliveredCountColor, other.deliveredCountColor, t)!,
      lightGrayBackground: Color.lerp(lightGrayBackground, other.lightGrayBackground, t)!,
      offWhite: Color.lerp(offWhite, other.offWhite, t)!,
      cardShadowColor: Color.lerp(cardShadowColor, other.cardShadowColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      pendingColor: Color.lerp(pendingColor, other.pendingColor, t)!,
    );
  }
}