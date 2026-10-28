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

    widgets = const [
      CopyrightText(size: 15),
      MadeWithFlutterWidget(size: 15),
    ];

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Smoothly fade in -> hold visible -> smoothly fade out
    fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 56,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 22,
      ),
    ]).animate(animationController);

    // Smoothly slide up from below -> rest at center -> slide up & out
    slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, 0.55),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 56,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.55),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 22,
      ),
    ]).animate(animationController);

    animationController.forward();

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() {
            currentIndex = (currentIndex + 1) % widgets.length;
          });
          animationController
            ..reset()
            ..forward();
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
