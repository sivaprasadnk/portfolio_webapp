import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/screens/home/widgets/intro_section.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class HomeScreenSmall extends StatelessWidget {
  const HomeScreenSmall({
    super.key,
    this.onExploreProjects,
    this.onPlayArcade,
  });

  final VoidCallback? onExploreProjects;
  final VoidCallback? onPlayArcade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (context.screenWidth <= 620) ...[
            const Center(
              child: StyleSwitcherBar(compact: true),
            ),
            const SizedBox(height: 16),
          ],
          const OrbitAnimation3(),
          const SizedBox(height: 16),
          IntroSection(
            onExploreProjects: onExploreProjects,
            onPlayArcade: onPlayArcade,
          ),
        ],
      ),
    );
  }
}
