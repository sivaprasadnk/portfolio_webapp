import 'package:flutter/material.dart';
import 'package:spnk/views/screens/home/widgets/intro_section.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';

class HomeScreenSmall extends StatelessWidget {
  const HomeScreenSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        // SizedBox(height: context.screenHeight * 0.2),
        // const ProfilePic(width: 315),
        OrbitAnimation3(),
        Row(
          children: [
            Spacer(),
            IntroSection(),
            Spacer(),
          ],
        ),
        
        // const SizedBox(height: 15),
        // Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     Text(
        //       "Follow me ",
        //       style: context.displaySmall,
        //     ),
        //     const SizedBox(width: 10),
        //     const SocialMediaIconsList(),
        //   ],
        // ),

        const SizedBox(height: 50),
      ],
    );
  }
}
