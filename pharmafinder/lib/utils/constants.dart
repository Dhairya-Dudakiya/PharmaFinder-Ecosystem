// utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF60AD5E);
  static const primaryDark = Color(0xFF005005);
  static const accent = Color(0xFF8BC34A);
  static const background = Color(0xFFF5F5F5);
  static const textDark = Color(0xFF212121);
  static const textLight = Color(0xFF757575);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFFFA000);
  static const white = Color(0xFFFFFFFF);
}

class AppStyles {
  static const titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );
}
