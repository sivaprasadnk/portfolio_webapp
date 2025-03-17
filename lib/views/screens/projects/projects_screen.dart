import 'package:flutter/material.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/projects/project_list_view.dart';
import 'package:spnk/views/screens/screen_section.dart';

class ProjectsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenSection(
      title: Screen.projects.screenTitle,
      details: const ProjectListView(),
      imageName: 'dash3',
      keepAlive: false,
    );
  }
}
