import 'package:flutter/material.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/Home';

  @override
  Widget build(BuildContext context) {
    return const RacingPortfolioScreen();
  }
}
