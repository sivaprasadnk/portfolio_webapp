import 'package:flutter/material.dart';
import 'package:spnk/views/screens/home/widgets/copyright_text.dart';
import 'package:spnk/views/screens/home/widgets/made_with_flutter_widget.dart';

class AnimatedFooter extends StatefulWidget {
  const AnimatedFooter({super.key});

  @override
  State<AnimatedFooter> createState() => _AnimatedFooterState();
}

class _AnimatedFooterState extends State<AnimatedFooter>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  List<Widget> widgets = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    widgets = [
      CopyrightText(size: 15),
      MadeWithFlutterWidget(size: 15),
    ];

    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    slideAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -0.7), // Adjusted to prevent large movement
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    animationController.forward();

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            currentIndex = (currentIndex + 1) % widgets.length;
          });

          animationController.reset();
          animationController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: widgets[currentIndex],
          ),
        );
      },
    );
  }
}
