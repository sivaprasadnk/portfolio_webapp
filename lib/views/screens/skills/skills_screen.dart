import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/screen_section.dart';
import 'package:spnk/views/screens/skills/skill_details_list_view.dart';

class SkillsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenSection(
      title: Screen.skills.screenTitle,
      details: const SkillDetailsListView(),
      imageName: 'dash4',
    );
  }
}
