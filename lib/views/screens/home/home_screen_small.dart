import 'package:flutter/material.dart';
import 'package:spnk/views/screens/home/widgets/intro_section.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';

class HomeScreenSmall extends StatelessWidget {
  const HomeScreenSmall({super.key, this.onExploreProjects});

  final VoidCallback? onExploreProjects;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const OrbitAnimation3(),
          const SizedBox(height: 16),
          IntroSection(onExploreProjects: onExploreProjects),
        ],
      ),
    );
  }
}
