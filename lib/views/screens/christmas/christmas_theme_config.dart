import 'package:flutter/material.dart';

/// Centralized festive theme configuration.
/// Flip [isChristmasEditionEnabled] to `false` after the holiday season to
/// immediately restore the classic /v4 grid home screen as the root route (`/`).
class ChristmasThemeConfig {
  const ChristmasThemeConfig._();

  static const bool isChristmasEditionEnabled = true;

  // Core luxury Christmas palette
  static const Color midnightBlue = Color(0xFF060E1F);
  static const Color deepNavy = Color(0xFF0B1A33);
  static const Color darkForestGreen = Color(0xFF0A281E);
  static const Color pineEmerald = Color(0xFF14533B);
  static const Color burgundy = Color(0xFF6E1423);
  static const Color crimsonGlow = Color(0xFFB91C3B);
  static const Color champagneGold = Color(0xFFF5D076);
  static const Color warmGold = Color(0xFFD4A039);
  static const Color snowWhite = Color(0xFFF8FAFC);
  static const Color icyBlue = Color(0xFFBAE6FD);
  static const Color frostTint = Color(0x14FFFFFF);
  static const Color frostBorder = Color(0x38F5D076);

  static const LinearGradient heroBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      midnightBlue,
      deepNavy,
      darkForestGreen,
    ],
  );

  static const LinearGradient goldActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      champagneGold,
      warmGold,
    ],
  );

  static const LinearGradient burgundyCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x336E1423),
      Color(0x220B1A33),
    ],
  );

  /// Returns days remaining until December 25 of the current year (or next year
  /// if December 25 has already passed).
  static int daysUntilChristmas(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var target = DateTime(now.year, 12, 25);
    if (today.isAfter(target)) {
      target = DateTime(now.year + 1, 12, 25);
    }
    return target.difference(today).inDays;
  }

  static String countdownLabel(DateTime now) {
    final days = daysUntilChristmas(now);
    return switch (days) {
      0 => 'Merry Christmas Today!',
      1 => '1 Day Until Christmas',
      _ => '$days Days to Dec 25',
    };
  }

  // Day / Night living winter village palette
  static const Color daySkyTop = Color(0xFF3E95DC);
  static const Color daySkyMid = Color(0xFF83C7F6);
  static const Color daySkyHorizon = Color(0xFFE5F3FD);

  static const Color nightSkyTop = Color(0xFF040B1A);
  static const Color nightSkyMid = Color(0xFF0B1C3D);
  static const Color nightSkyHorizon = Color(0xFF1A345C);

  static const Color dayCardBg = Color(0xD8F8FCFF);
  static const Color nightCardBg = Color(0xB809172E);
  static const Color dayCardBorder = Color(0xBBE0EEFB);
  static const Color nightCardBorder = Color(0x668ED0FB);

  static const Color dayTextPrimary = Color(0xFF0F223A);
  static const Color nightTextPrimary = Color(0xFFF8FAFC);
  static const Color dayTextSecondary = Color(0xFF334E6E);
  static const Color nightTextSecondary = Color(0xFFD6E7F8);

  static const Color cabinWoodDark = Color(0xFF3A2316);
  static const Color cabinWoodLight = Color(0xFF694329);
  static const Color warmLanternAmber = Color(0xFFFFB74D);

  /// Returns `true` when [now] falls in daytime (06:00 <= hour < 18:00).
  static bool isDayTime(DateTime now) => now.hour >= 6 && now.hour < 18;

  static Color skyTop(double dayFactor) =>
      Color.lerp(nightSkyTop, daySkyTop, dayFactor)!;

  static Color skyMid(double dayFactor) =>
      Color.lerp(nightSkyMid, daySkyMid, dayFactor)!;

  static Color skyHorizon(double dayFactor) =>
      Color.lerp(nightSkyHorizon, daySkyHorizon, dayFactor)!;

  static Color cardSurface(double dayFactor) =>
      Color.lerp(nightCardBg, dayCardBg, dayFactor)!;

  static Color cardBorder(double dayFactor) =>
      Color.lerp(nightCardBorder, dayCardBorder, dayFactor)!;

  static Color primaryText(double dayFactor) =>
      Color.lerp(nightTextPrimary, dayTextPrimary, dayFactor)!;

  static Color secondaryText(double dayFactor) =>
      Color.lerp(nightTextSecondary, dayTextSecondary, dayFactor)!;

  static Color accentGold(double dayFactor) =>
      Color.lerp(champagneGold, const Color(0xFFB4690E), dayFactor)!;

  static Color accentIce(double dayFactor) =>
      Color.lerp(icyBlue, const Color(0xFF0369A1), dayFactor)!;
}
