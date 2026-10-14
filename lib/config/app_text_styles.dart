import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'theme.dart';

double tabletUiScale(double shortestSide) {
  final raw = shortestSide / 375;
  return (1 + (raw - 1) * 0.4).clamp(1.0, 1.35).toDouble();
}

double appFontSize(double size) {
  final su = ScreenUtil();
  final shortest = min(su.screenWidth, su.screenHeight);
  if (shortest < 600) return size.sp;
  return size * tabletUiScale(shortest);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => _base(28, FontWeight.w700);
  static TextStyle get headline => _base(22, FontWeight.w700);
  static TextStyle get titleLarge => _base(20, FontWeight.w700);
  static TextStyle get titleMedium => _base(16, FontWeight.w600);
  static TextStyle get titleSmall => _base(14, FontWeight.w600);
  static TextStyle get body => _base(14, FontWeight.w400);
  static TextStyle get bodySmall => _base(13, FontWeight.w400);
  static TextStyle get label => _base(12, FontWeight.w400);
  static TextStyle get smallLabel => _base(11, FontWeight.w400);
  static TextStyle get caption => _base(10, FontWeight.w400);
  static TextStyle get smallCaption => _base(9, FontWeight.w400);

  static TextStyle _base(double size, FontWeight weight) => TextStyle(
        fontSize: appFontSize(size),
        fontWeight: weight,
        fontFamily: AppTheme.fontFamily,
      );
}
