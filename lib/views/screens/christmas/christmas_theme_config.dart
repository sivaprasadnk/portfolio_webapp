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
}
