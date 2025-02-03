import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/home/widgets/tab_item.dart';

class ProjectsTab extends StatelessWidget {
  final TabController tabController;
  final Duration duration;
  const ProjectsTab({
    required this.tabController,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TabItem(
      screen: Screen.projects,
      // onTap: () {
      //   tabController.animateTo(3, duration: duration);
      // },
      tabController: tabController,
      title: 'Projects',
      // index: 3,
    );
  }
}
