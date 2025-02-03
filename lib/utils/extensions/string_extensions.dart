import 'package:animated_icon/animated_icon.dart';

extension StringExt on String {
  AnimateIcons get iconFromString {
    if (this == 'home') {
      return AnimateIcons.home;
    } else if (this == "call") {
      return AnimateIcons.chatMessage;
    } else if (this == 'email') {
      return AnimateIcons.mail;
    }
    return AnimateIcons.home;
  }

  // IconData get skillIconFromString {
  //   if (this == 'dart') {
  //     return FontAwesomeIcons.ht;
  //   } else if (this == "flutter") {
  //     return AnimateIcons.chatMessage;
  //   } else if (this == 'firebase') {
  //     return AnimateIcons.mail;
  //   }else if (this == 'html') {
  //     return AnimateIcons.mail;
  //   }else if (this == 'css') {
  //     return AnimateIcons.mail;
  //   }
  //   return AnimateIcons.home;
  // }
}
