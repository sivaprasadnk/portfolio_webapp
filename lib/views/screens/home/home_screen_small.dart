import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';

class HomeScreenSmall extends StatelessWidget {
  const HomeScreenSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // const SizedBox(width: 15),
        // const SocialMediaIconsList(),
        const Spacer(),
        // const Spacer(),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            // SizedBox(height: context.screenHeight * 0.2),
            // const ProfilePic(width: 315),
            OrbitAnimation3(),
            Text(
              "Hi,\nI 'm Sivaprasad NK .",
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SizedBox(
                    width: context.screenWidth * 0.8,
                    child: Text(
                      'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala .',
                      style: context.displaySmall.copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Row(
              children: [
                DownloadCvBtn(),
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
        ),
        const Spacer(),
      ],
    );
  }
}
