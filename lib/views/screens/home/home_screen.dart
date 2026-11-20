import 'package:flutter/material.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/Home';

  @override
  Widget build(BuildContext context) {
    return const InteractiveGridHomeScreen();
  }
}
