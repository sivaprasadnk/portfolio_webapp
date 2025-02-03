import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/home/widgets/tab_item.dart';

class ExperienceTab extends StatelessWidget {
  final TabController tabController;
  final Duration duration;
  const ExperienceTab({
    required this.tabController,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TabItem(
      screen: Screen.experience,
      // onTap: () {
      //   tabController.animateTo(
      //     2,
      //     duration: duration,
      //     curve: Curves.decelerate,
      //   );
      // },
      tabController: tabController,
      title: 'Experience',
      // index: 2,
    );
  }
}
