
import 'package:flutter/material.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/string_constants.dart';


ThemeData lightTheme = ThemeData(
  appBarTheme: AppBarTheme(
    backgroundColor: kLightColor1,
    // backgroundColor: ThemeData.light().scaffoldBackgroundColor,
  ),
  brightness: Brightness.light,
  buttonTheme: const ButtonThemeData(
    buttonColor: Color.fromRGBO(0, 34, 120, 1),
    textTheme: ButtonTextTheme.primary,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color.fromRGBO(239, 239, 239, 1),
  ),
  primaryColor: kDarkColor1,
  hoverColor: kPrimaryLightBlueColor,
  scaffoldBackgroundColor: kLightColor1,
  scrollbarTheme: const ScrollbarThemeData().copyWith(
    thumbVisibility: const WidgetStatePropertyAll(false),
    thumbColor: WidgetStateProperty.all(kLightColor1),
  ),
  shadowColor: Colors.black.withOpacity(0.2),
  splashColor: const Color(0xFF002278),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kDarkColor1,
    ),
    bodyMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kDarkColor1,
    ),
    bodySmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kDarkColor1,
    ),
    displayLarge: TextStyle(
      fontSize: 50,
      fontFamily: kLogoFontFamily,
      color: kDarkColor1,
    ),
    displayMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kDarkColor1,
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kDarkColor1,
    ),
    headlineSmall: TextStyle(
      fontSize: 50,
      fontFamily: 'Rajdhani',
      color: kDarkColor1,
    ),
    titleLarge: TextStyle(
      fontSize: 35,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kDarkColor1,
    ),
  ),
);

ThemeData darkTheme = ThemeData(
  appBarTheme: AppBarTheme(
    backgroundColor: kDarkColor1,
  ),
  brightness: Brightness.dark,
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.red,
    textTheme: ButtonTextTheme.primary,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color.fromRGBO(0, 34, 51, 1),
  ),
  primaryColor: kLightColor1,
  hoverColor: kPrimaryWhiteColor,
  primarySwatch: kMaterialCyanColor,
  scaffoldBackgroundColor: kDarkColor1,
  shadowColor: Colors.cyan.withOpacity(0.2),
  splashColor: kWhiteColor,
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kLightColor1,
    ),
    bodyMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kLightColor1,
    ),
    bodySmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kLightColor1,
    ),
    displayLarge: TextStyle(
      fontSize: 50,
      // fontFamily: 'Rajdhani',
      fontFamily: kLogoFontFamily,
      color: kLightColor1,
    ),
    displayMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kLightColor1,
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kLightColor1,
    ),
    headlineSmall: TextStyle(
      fontSize: 50,
      fontFamily: 'Rajdhani',
      color: kLightColor1,
    ),
    titleLarge: TextStyle(
      fontSize: 35,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kLightColor1,
    ),
  ),
);

///

ThemeData lightTheme1 = ThemeData(
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromRGBO(239, 239, 239, 1),
  ),
  brightness: Brightness.light,
  buttonTheme: const ButtonThemeData(
    buttonColor: Color.fromRGBO(0, 34, 120, 1),
    // buttonColor: kGreyColor2,
    textTheme: ButtonTextTheme.primary,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color.fromRGBO(239, 239, 239, 1),
  ),
  primaryColor: kPrimaryBlueColor,
  // primaryColor: kGreyColor2,
  hoverColor: kPrimaryLightBlueColor,
  primarySwatch: Colors.indigo,
  scaffoldBackgroundColor: const Color.fromRGBO(239, 239, 239, 1),
  scrollbarTheme: const ScrollbarThemeData().copyWith(
    thumbVisibility: const WidgetStatePropertyAll(false),
    thumbColor: WidgetStateProperty.all(Colors.cyan),
  ),
  shadowColor: Colors.black.withOpacity(0.2),
  splashColor: const Color(0xFF002278),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.bold,
      fontFamily: kRajdhaniFontFamily,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
      fontSize: 18,
      fontFamily: kRajdhaniFontFamily,
    ),
    bodySmall: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
    displayLarge: TextStyle(
      // fontFamily: 'Rajdhani',
      fontFamily: kLogoFontFamily,
      fontSize: 50,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
    displayMedium: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 30,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
    displaySmall: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Rajdhani',
      fontSize: 50,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
    titleLarge: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 35,
      color: kPrimaryBlueColor,
      // color: kGreyColor2,
    ),
  ),
);

ThemeData darkTheme1 = ThemeData(
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromRGBO(0, 34, 51, 1),
  ),
  brightness: Brightness.dark,
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.red,
    textTheme: ButtonTextTheme.primary,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color.fromRGBO(0, 34, 51, 1),
  ),
  primaryColor: kPrimaryWhiteColor,
  hoverColor: kPrimaryWhiteColor,
  primarySwatch: kMaterialCyanColor,
  scaffoldBackgroundColor: const Color.fromRGBO(0, 34, 51, 1),
  // scaffoldBackgroundColor: kPrimaryWhiteColor,
  // scrollbarTheme: const ScrollbarThemeData().copyWith(
  //   thumbVisibility: const WidgetStatePropertyAll(false),
  //   thumbColor: WidgetStateProperty.all(kCyanColor),
  // ),
  shadowColor: Colors.cyan.withOpacity(0.2),
  splashColor: kWhiteColor,
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: kWhiteColor,
      fontSize: 21,
      fontFamily: kRajdhaniFontFamily,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.bold,
      color: kWhiteColor,
      fontSize: 18,
      fontFamily: kRajdhaniFontFamily,
    ),
    bodySmall: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: kWhiteColor,
    ),
    displayLarge: TextStyle(
      // fontFamily: 'Rajdhani',
      fontFamily: kLogoFontFamily,
      fontSize: 50,
      color: kWhiteColor,
    ),
    displayMedium: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 30,
      color: kWhiteColor,
    ),
    displaySmall: TextStyle(
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: kWhiteColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Rajdhani',
      fontSize: 50,
      color: kWhiteColor,
    ),
    titleLarge: TextStyle(
      fontSize: 35,
      fontFamily: kRajdhaniFontFamily,
      fontWeight: FontWeight.bold,
      color: kWhiteColor,
    ),
  ),
);
