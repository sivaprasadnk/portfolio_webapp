import 'package:flutter/material.dart';

abstract class ThemeEvent {
  ThemeEvent();
}

class ToggleTheme extends ThemeEvent {
  final bool isDarkTheme;
  final ThemeData currentTheme;
  ToggleTheme({
    required this.isDarkTheme,
    required this.currentTheme,
  });
}

class UpdateTheme extends ThemeEvent {
  final Brightness brightness;
  final Color primaryColor;
  final Color bgColor;
  UpdateTheme({
    required this.brightness,
    required this.primaryColor,
    required this.bgColor,
  });
}

class UpdatePrimaryColor extends ThemeEvent {
  final Color primaryColor;
  final Color bgColor;
  UpdatePrimaryColor({
    required this.primaryColor,
    required this.bgColor,
  });
}

class UpdateBgColor extends ThemeEvent {
  final Color primaryColor;
  final Color bgColor;
  UpdateBgColor({
    required this.bgColor,
    required this.primaryColor,
  });
}

class ToggleSpotLight extends ThemeEvent {
  // final b;
  ToggleSpotLight();
}
