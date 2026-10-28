import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/string_constants.dart';

enum PortfolioStyle {
  glass,
  bento,
  cyber,
}

extension PortfolioStyleExt on PortfolioStyle {
  String get label {
    switch (this) {
      case PortfolioStyle.glass:
        return 'Glass';
      case PortfolioStyle.bento:
        return 'Bento';
      case PortfolioStyle.cyber:
        return 'Cyber';
    }
  }

  String get fullName {
    switch (this) {
      case PortfolioStyle.glass:
        return 'Glassmorphic & Neon';
      case PortfolioStyle.bento:
        return 'Minimalist Bento';
      case PortfolioStyle.cyber:
        return 'Futuristic Cyber';
    }
  }

  IconData get icon {
    switch (this) {
      case PortfolioStyle.glass:
        return Icons.auto_awesome_rounded;
      case PortfolioStyle.bento:
        return Icons.grid_view_rounded;
      case PortfolioStyle.cyber:
        return Icons.terminal_rounded;
    }
  }
}

class ThemeState extends Equatable {
  final ThemeData themeData;
  final bool showSpotLight;
  final PortfolioStyle portfolioStyle;

  ThemeState({
    ThemeData? themeData,
    this.showSpotLight = false,
    this.portfolioStyle = PortfolioStyle.glass,
  }) : themeData = themeData ??
            buildThemeForStyle(
              style: portfolioStyle,
              isDark: true,
            );

  bool get isDark => themeData.brightness == Brightness.dark;

  Color get accentColor {
    switch (portfolioStyle) {
      case PortfolioStyle.glass:
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5);
      case PortfolioStyle.bento:
        return isDark ? const Color(0xFF10B981) : const Color(0xFF18181B);
      case PortfolioStyle.cyber:
        return isDark ? const Color(0xFF00F0FF) : const Color(0xFF0077B6);
    }
  }

  Color get secondaryAccent {
    switch (portfolioStyle) {
      case PortfolioStyle.glass:
        return isDark ? const Color(0xFFA855F7) : const Color(0xFF06B6D4);
      case PortfolioStyle.bento:
        return isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
      case PortfolioStyle.cyber:
        return isDark ? const Color(0xFFFF2A85) : const Color(0xFFD90429);
    }
  }

  Color get cardSurfaceColor {
    switch (portfolioStyle) {
      case PortfolioStyle.glass:
        return isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.75);
      case PortfolioStyle.bento:
        return isDark ? const Color(0xFF141418) : const Color(0xFFFFFFFF);
      case PortfolioStyle.cyber:
        return isDark
            ? const Color(0xFF0B1324).withOpacity(0.88)
            : const Color(0xFFFFFFFF).withOpacity(0.92);
    }
  }

  Color get cardBorderColor {
    switch (portfolioStyle) {
      case PortfolioStyle.glass:
        return isDark
            ? Colors.white.withOpacity(0.14)
            : const Color(0xFF4F46E5).withOpacity(0.18);
      case PortfolioStyle.bento:
        return isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
      case PortfolioStyle.cyber:
        return isDark
            ? const Color(0xFF00F0FF).withOpacity(0.45)
            : const Color(0xFF0077B6).withOpacity(0.45);
    }
  }

  double get cardRadius {
    switch (portfolioStyle) {
      case PortfolioStyle.glass:
        return 20;
      case PortfolioStyle.bento:
        return 24;
      case PortfolioStyle.cyber:
        return 8;
    }
  }

  ThemeState copyWith({
    ThemeData? newTheme,
    bool? spotLightMode,
    PortfolioStyle? portfolioStyle,
  }) {
    return ThemeState(
      themeData: newTheme ?? themeData,
      showSpotLight: spotLightMode ?? showSpotLight,
      portfolioStyle: portfolioStyle ?? this.portfolioStyle,
    );
  }

  @override
  List<Object?> get props => [
        themeData,
        showSpotLight,
        portfolioStyle,
      ];

  static ThemeData buildThemeForStyle({
    required PortfolioStyle style,
    required bool isDark,
    Color? customPrimary,
    Color? customBg,
  }) {
    Color bgColor;
    Color primaryColor;
    Color hoverColor;

    switch (style) {
      case PortfolioStyle.glass:
        bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF3F6FC);
        primaryColor =
            isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
        hoverColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5);
        break;
      case PortfolioStyle.bento:
        bgColor = isDark ? const Color(0xFF09090B) : const Color(0xFFF7F7F5);
        primaryColor =
            isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
        hoverColor = isDark ? const Color(0xFF10B981) : const Color(0xFF4F46E5);
        break;
      case PortfolioStyle.cyber:
        bgColor = isDark ? const Color(0xFF050811) : const Color(0xFFEEF2F6);
        primaryColor =
            isDark ? const Color(0xFFE2F1FF) : const Color(0xFF0B1324);
        hoverColor = isDark ? const Color(0xFF00F0FF) : const Color(0xFF0077B6);
        break;
    }

    if (customBg != null) bgColor = customBg;
    if (customPrimary != null) primaryColor = customPrimary;

    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
      ),
      brightness: isDark ? Brightness.dark : Brightness.light,
      drawerTheme: DrawerThemeData(
        backgroundColor: bgColor,
      ),
      primaryColor: primaryColor,
      hoverColor: hoverColor,
      scaffoldBackgroundColor: bgColor,
      scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.all(hoverColor.withOpacity(0.5)),
      ),
      shadowColor: hoverColor.withOpacity(0.25),
      splashColor: hoverColor.withOpacity(0.15),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displayLarge: TextStyle(
          fontSize: 42,
          fontFamily: kLogoFontFamily,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 48,
          fontFamily: kRajdhaniFontFamily,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          fontFamily: kRajdhaniFontFamily,
          color: primaryColor,
        ),
      ),
    );
  }
}
