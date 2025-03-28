import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/home/widgets/tab_item.dart';

class ContactMeTab extends StatelessWidget {
  final TabController tabController;
  final Duration duration;
  const ContactMeTab({
    required this.tabController,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TabItem(
      screen: Screen.contactMe,
      // onTap: () {
      //   tabController.animateTo(4, duration: duration);
      // },
      title: 'Contact Me',
      tabController: tabController,
      // index: 4,
    );
  }
}
