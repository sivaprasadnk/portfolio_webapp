import 'package:flutter/material.dart';
import 'package:spnk/views/screens/home/widgets/intro_text.dart';
import 'package:spnk/views/screens/home/widgets/profile_pic.dart';

class WindowsSmallHomeScreen extends StatefulWidget {
  final bool showProPic;
  const WindowsSmallHomeScreen({required this.showProPic});

  @override
  State<WindowsSmallHomeScreen> createState() => _WindowsSmallHomeScreenState();
}

class _WindowsSmallHomeScreenState extends State<WindowsSmallHomeScreen> {
  bool showProPic = false;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      setState(() {
        showProPic = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    return Column(
      children: [
        IntroText(
          leftPadding: screenWidth * .2,
          topPadding: screenHeight * 0.08,
          imageHeight: 190,
          imageWidth: screenWidth * 0.2,

        ),
        SizedBox(height: screenHeight * 0.05),
        Row(
          children: [
            SizedBox(width: screenWidth * 0.05),
            // const SocialMediaIconsList(),
            SizedBox(width: screenWidth * 0.12),
            AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: showProPic ? 1 : 0,
              child: ProfilePic(
                width: screenHeight * 0.35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
