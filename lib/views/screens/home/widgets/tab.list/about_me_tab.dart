import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/home/widgets/tab_item.dart';

class AboutMeTab extends StatelessWidget {
  final TabController tabController;
  final Duration duration;
  const AboutMeTab({
    required this.tabController,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TabItem(
      screen: Screen.aboutMe,
      // onTap: () {
      //   tabController.animateTo(0, duration: duration);
      // },
      title: 'About Me',
      tabController: tabController,
      // index: 4,
    );
  }
}
