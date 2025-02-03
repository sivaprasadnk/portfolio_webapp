import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/experience/exp_details_list_view.dart';
import 'package:spnk/views/screens/screen_section.dart';

class ExperienceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenSection(
      title: Screen.experience.screenTitle,
      details: const ExpDetailsListView(),
      imageName: 'dash2',
    );
  }
}
