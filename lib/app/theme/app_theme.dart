import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFBF3E4),
      paper = Color(0xFFFFF9EE),
      paperDark = Color(0xFFF3E5C8),
      ink = Color(0xFF3B2A20),
      muted = Color(0xFF8A7262),
      border = Color(0xFFCDB58D),
      coral = Color(0xFFE07A5F),
      mint = Color(0xFF7FB7A4),
      teal = Color(0xFF3F8C86),
      blue = Color(0xFF5B8FA8),
      pink = Color(0xFFF6D5C6),
      yellow = Color(0xFFF6E2B0),
      green = Color(0xFFD3EBDF),
      lightBlue = Color(0xFFD5E6EE),
      mustard = Color(0xFFE3A82B);
}

TextStyle serif(
  double size, {
  FontWeight weight = FontWeight.w600,
  Color? color,
  bool italic = false,
}) => TextStyle(
  fontFamily: 'Lora',
  fontSize: size,
  fontWeight: weight,
  color: color ?? AppColors.ink,
  height: 1.25,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
);
TextStyle body(double size, {Color? color, FontWeight? weight}) => TextStyle(
  fontFamily: 'BeVietnamPro',
  fontSize: size,
  height: 1.5,
  color: color ?? AppColors.ink,
  fontWeight: weight ?? FontWeight.w400,
);
ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'BeVietnamPro',
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.coral,
    brightness: Brightness.light,
    primary: AppColors.coral,
    surface: AppColors.paper,
  ),
  textTheme: TextTheme(bodyMedium: body(16)),
  sliderTheme: const SliderThemeData(
    trackHeight: 10,
    activeTrackColor: AppColors.mint,
    inactiveTrackColor: AppColors.yellow,
    thumbColor: AppColors.coral,
    overlayColor: Color(0x22E07A5F),
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 13),
    trackShape: RoundedRectSliderTrackShape(),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.paper,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
);

class AppDimensions {
  static const pagePadding = 16.0, maxWidth = 640.0, cardRadius = 18.0;
}
