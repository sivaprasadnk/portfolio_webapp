import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/screens/home/widgets/intro_text.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';

class HomeScreenLarge extends StatefulWidget {
  @override
  _HomeScreenLargeState createState() => _HomeScreenLargeState();
}

class _HomeScreenLargeState extends State<HomeScreenLarge>
    with AutomaticKeepAliveClientMixin {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = context.screenWidth;
    final leftPadding = screenWidth * .1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: [
        // const SocialMediaIconsList(),
        Padding(
          padding: EdgeInsets.only(left: leftPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntroText(
                imageHeight: 250,
                imageWidth: screenWidth * .4,
              ),
              const SizedBox(height: 30),
              const DownloadCvBtn(),
              const SizedBox(height: 15),
              // Row(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     Text(
              //       "Follow me ",
              //       style: Theme.of(context).textTheme.displaySmall,
              //     ),
              //     const SizedBox(width: 10),
              //     const SocialMediaIconsList(),
              //   ],
              // ),
            ],
          ),
        ),
        if (context.isLargeDevice)
        OrbitAnimation3()
        // ProfilePic(
        //   width: screenWidth * 0.28,
        // ),
      ],
    );
  }
}
