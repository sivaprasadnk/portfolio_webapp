import 'package:flutter/material.dart';

enum Screen {
  home,
  aboutMe,
  skills,
  experience,
  projects,
  contactMe,
}

extension ScreenExt on Screen {
  String get menuName {
    switch (this) {
      case Screen.home:
        return "Home";
      case Screen.aboutMe:
        return 'About';
      case Screen.skills:
        return 'Skills';
      case Screen.experience:
        return 'Experience';
      case Screen.projects:
        return 'Projects';
      case Screen.contactMe:
        return "Contact";
    }
  }

  String get screenTitle {
    switch (this) {
      case Screen.home:
        return "Home";
      case Screen.aboutMe:
        return 'About Me';
      case Screen.skills:
        return 'My Skills';
      case Screen.experience:
        return 'My Experience';
      case Screen.projects:
        return 'My personal Projects';
      case Screen.contactMe:
        return "Contact Me";
    }
  }

  IconData get icon {
    switch (this) {
      case Screen.home:
        return Icons.home;
      case Screen.aboutMe:
        return Icons.person_2;
      case Screen.skills:
        return Icons.code;
      case Screen.experience:
        return Icons.work;
      case Screen.projects:
        return Icons.apps;
      case Screen.contactMe:
        return Icons.call;
    }
  }
}
