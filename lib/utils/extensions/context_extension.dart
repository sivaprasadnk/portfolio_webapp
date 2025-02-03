import 'package:flutter/material.dart';
import 'package:spnk/utils/int_constants.dart';
// import 'package:provider/provider.dart';

extension BuiltContextExt on BuildContext {
  void pop() => Navigator.pop(this);

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  Color get primaryColor => Theme.of(this).primaryColor;
  Color get shadowColor => Theme.of(this).shadowColor;
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  // bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
  Color get hoverColor => Theme.of(this).hoverColor;

  TextTheme get textTheme => Theme.of(this).textTheme;

  TextStyle get displaySmall => textTheme.displaySmall!;
  TextStyle get bodySmall => textTheme.bodySmall!;
  TextStyle get displayMedium => textTheme.displayMedium!;
  TextStyle get bodyMedium => textTheme.bodyMedium!;

  bool get isMobileDevice => screenWidth <= mobileBreakPoint;
  bool get isLargeDevice => !isMobileDevice;
}
