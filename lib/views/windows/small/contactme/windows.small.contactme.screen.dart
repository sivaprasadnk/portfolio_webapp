import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/screens/contact_me/contact_details_list_view.dart';
import 'package:spnk/views/windows/common/screen_image.dart';
import 'package:spnk/views/windows/small/screen_title.dart';

class WindowsSmallContactMeScreen extends StatelessWidget {
 
  @override
  Widget build(BuildContext context) {
    final screenHeight = context.screenHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(title: 'Contact Me'),
        SizedBox(height: screenHeight * 0.05),
        const ContactDetailsListView(
        ),
        const SizedBox(height: 50),
        Flexible(
          child: ScreenImage(
            alignment: Alignment.center,
            height: 250,
            width: context.screenWidth * 0.3,

            imagePath: 'assets/images/dash/dash4.png',
          ),
        ),
      ],
    );
  }
}
