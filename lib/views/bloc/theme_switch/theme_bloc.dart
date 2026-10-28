import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:spnk/views/bloc/theme_switch/theme_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState()) {
    on<ToggleTheme>(_toggleTheme);
    on<UpdateTheme>(_updateTheme);
    on<ToggleSpotLight>(_toggleSpotLight);
    on<UpdatePrimaryColor>(_updatePrimaryColor);
    on<UpdateBgColor>(_updateBgColor);
    on<ChangePortfolioStyle>(_changePortfolioStyle);
  }

  void _changePortfolioStyle(
    ChangePortfolioStyle event,
    Emitter<ThemeState> emit,
  ) {
    final newTheme = ThemeState.buildThemeForStyle(
      style: event.style,
      isDark: state.isDark,
    );
    emit(
      state.copyWith(
        newTheme: newTheme,
        portfolioStyle: event.style,
      ),
    );
  }

  void _toggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    final nextIsDark = !event.isDarkTheme;
    final newTheme = ThemeState.buildThemeForStyle(
      style: state.portfolioStyle,
      isDark: nextIsDark,
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _updateTheme(UpdateTheme event, Emitter<ThemeState> emit) {
    final nextIsDark = event.brightness == Brightness.dark;
    final newTheme = ThemeState.buildThemeForStyle(
      style: state.portfolioStyle,
      isDark: nextIsDark,
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _updatePrimaryColor(
    UpdatePrimaryColor event,
    Emitter<ThemeState> emit,
  ) {
    final newTheme = ThemeState.buildThemeForStyle(
      style: state.portfolioStyle,
      isDark: state.isDark,
      customPrimary: event.primaryColor,
      customBg: event.bgColor,
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _updateBgColor(UpdateBgColor event, Emitter<ThemeState> emit) {
    final newTheme = ThemeState.buildThemeForStyle(
      style: state.portfolioStyle,
      isDark: state.isDark,
      customPrimary: event.primaryColor,
      customBg: event.bgColor,
    );
    emit(state.copyWith(newTheme: newTheme));
  }

  void _toggleSpotLight(ToggleSpotLight event, Emitter<ThemeState> emit) {
    emit(state.copyWith(spotLightMode: !state.showSpotLight));
  }
}
