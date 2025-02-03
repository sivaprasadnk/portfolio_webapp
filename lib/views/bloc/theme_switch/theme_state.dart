import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/utils/theme_list.dart';

class ThemeState extends Equatable {
  // final bool isDarkTheme;
  final ThemeData themeData;
  final bool showSpotLight;
  ThemeState({
    // bool? isDarkTheme,
    ThemeData? themeData,
    this.showSpotLight = false,
  }) : themeData = themeData ?? _getInitialTheme();

  ThemeState copyWith({ThemeData? newTheme, bool? spotLightMode}) {
    return ThemeState(
      // isDarkTheme: isDark ?? isDarkTheme,
      themeData: newTheme ?? themeData,
      showSpotLight: spotLightMode ?? showSpotLight,
    );
  }

  @override
  List<Object?> get props => [
        // isDarkTheme,
        themeData,
        showSpotLight,
      ];

  static bool _checkForDarkTheme() {
    final now = DateTime.now();
    return now.hour < 12;
  }

  static ThemeData _getInitialTheme() {
    final darkColor = darkColorList[0];
    final lightColor = lightColorList[0];
    final isDarkTheme = _checkForDarkTheme();
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: !isDarkTheme ? lightColor : darkColor,
      ),
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      drawerTheme: DrawerThemeData(
        backgroundColor: !isDarkTheme ? lightColor : darkColor,
      ),
      primaryColor: isDarkTheme ? lightColor : darkColor,
      hoverColor: isDarkTheme ? lightColor : darkColor,
      scaffoldBackgroundColor: !isDarkTheme ? lightColor : darkColor,
      scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.all(
          isDarkTheme ? lightColor : darkColor,
        ),
      ),
      shadowColor: !isDarkTheme
          ? darkColor.withOpacity(0.5)
          : lightColor.withOpacity(0.5),
      splashColor: const Color(0xFF002278),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
        displayLarge: TextStyle(
          fontSize: 50,
          // fontFamily: 'Zina',
          fontFamily: kLogoFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 50,
          fontFamily: 'Zina',
          color: isDarkTheme ? lightColor : darkColor,
        ),
        titleLarge: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: isDarkTheme ? lightColor : darkColor,
        ),
      ),
    );
  }

}
