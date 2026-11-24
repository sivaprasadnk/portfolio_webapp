import 'package:flutter/material.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';
import 'package:spnk/views/screens/christmas/santa_village_2d_screen.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/Home';

  @override
  Widget build(BuildContext context) {
    if (ChristmasThemeConfig.isChristmasEditionEnabled) {
      return const SantaVillage2dScreen();
    }
    return const InteractiveGridHomeScreen();
  }
}
