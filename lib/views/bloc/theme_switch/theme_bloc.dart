import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/theme_switch/theme_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState()) {
    on<ToggleTheme>(_toggleTheme);
    on<UpdateTheme>(_updateTheme);
    on<ToggleSpotLight>(_toggleSpotLight);
    // on<GetColorTheme>(_getColorTheme);s
    // on<UpdatePrimaryColor>(_updatePrimaryColor);
    // on<UpdateBgColor>(_updateBgColor);
  }

  void _toggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    final currentTheme = event.currentTheme;
    // final currentBrightness = currentTheme.brightness;
    final bgColor = event.isDarkTheme
        ? currentTheme.scaffoldBackgroundColor
        : currentTheme.primaryColor;
    final primaryColor = event.isDarkTheme
        ? currentTheme.primaryColor
        : currentTheme.scaffoldBackgroundColor;
    final newTheme = ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
      ),
      brightness: event.isDarkTheme ? Brightness.light : Brightness.dark,
      drawerTheme: DrawerThemeData(
        backgroundColor: bgColor,
      ),
      primaryColor: primaryColor,
      hoverColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.all(
          primaryColor,
        ),
      ),
      shadowColor: primaryColor.withOpacity(0.5),
      splashColor: const Color(0xFF002278),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displayLarge: TextStyle(
          fontSize: 50,
          // fontFamily: 'Rajdhani',
          fontFamily: kLogoFontFamily,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 50,
          fontFamily: 'Rajdhani',
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
      ),
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _updatePrimaryColor(UpdatePrimaryColor event, Emitter<ThemeState> emit) {
    final primaryColor = event.primaryColor;
    final bgColor = event.bgColor;
    final newTheme = ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
      ),
      brightness: state.themeData.brightness,
      drawerTheme: DrawerThemeData(
        backgroundColor: bgColor,
      ),
      primaryColor: primaryColor,
      hoverColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.all(
          primaryColor,
        ),
      ),
      shadowColor: primaryColor.withOpacity(0.5),
      splashColor: const Color(0xFF002278),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displayLarge: TextStyle(
          fontSize: 50,
          // fontFamily: 'Rajdhani',
          fontFamily: kLogoFontFamily,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 50,
          fontFamily: 'Rajdhani',
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
      ),
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _updateBgColor(UpdateBgColor event, Emitter<ThemeState> emit) {
    final color = event.bgColor;
    final primaryColor = event.primaryColor;
    final newTheme = ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: color,
      ),
      brightness: state.themeData.brightness,
      drawerTheme: DrawerThemeData(
        backgroundColor: color,
      ),
      primaryColor: primaryColor,
      hoverColor: primaryColor,
      scaffoldBackgroundColor: color,
      scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.all(
          primaryColor,
        ),
      ),
      shadowColor: color.withOpacity(0.5),
      splashColor: const Color(0xFF002278),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displayLarge: TextStyle(
          fontSize: 50,
          // fontFamily: 'Rajdhani',
          fontFamily: kLogoFontFamily,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 50,
          fontFamily: 'Rajdhani',
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
      ),
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _updateTheme(UpdateTheme event, Emitter<ThemeState> emit) {
    final primaryColor = event.primaryColor;
    final bgColor = event.bgColor;
    final mode = event.brightness;
    final newTheme = ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
      ),
      brightness: mode,
      drawerTheme: DrawerThemeData(
        backgroundColor: bgColor,
      ),
      primaryColor: primaryColor,
      hoverColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.all(
          primaryColor,
        ),
      ),
      shadowColor: primaryColor.withOpacity(0.5),
      splashColor: const Color(0xFF002278),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displayLarge: TextStyle(
          fontSize: 50,
          // fontFamily: 'Rajdhani',s
          fontFamily: kLogoFontFamily,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 50,
          fontFamily: 'Rajdhani',
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
      ),
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _toggleSpotLight(ToggleSpotLight event, Emitter<ThemeState> emit) {
    emit(state.copyWith(spotLightMode: !state.showSpotLight));
  }

}
