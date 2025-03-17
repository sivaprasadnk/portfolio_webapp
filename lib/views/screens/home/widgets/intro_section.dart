import 'package:flutter/material.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';

class IntroSection extends StatefulWidget {
  const IntroSection({super.key});

  @override
  State<IntroSection> createState() => _IntroSectionState();
}

class _IntroSectionState extends State<IntroSection>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _subTextController;
  late Animation<double> _subTextFade;
  late Animation<Offset> _subTextSlide;

  late AnimationController _btnController;
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    // Main text animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Sub text animation
    _subTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _subTextFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _subTextController,
      curve: Curves.easeInOut,
    ));

    _subTextSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _subTextController, curve: Curves.easeOut),
    );

    // Button animation
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _btnController,
      curve: Curves.easeInOut,
    ));

    _btnSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOut),
    );

    // Start animations with delay
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _controller.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _subTextController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _btnController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _subTextController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Text Animation
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            // child: AnimatedNameText(
            //   staticText: "Hi,",
            //   targetText: "I'm Sivaprasad NK.",
            //   duration: Duration(seconds: 3),
            //   jumbleSpeed: Duration(milliseconds: 30),
            // ),
            child: Text(
              "Hi,\nI'm Sivaprasad NK.",
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
        ),
        // AnimatedNameText(),
        const SizedBox(height: 15),

        // Sub Text Animation
        SlideTransition(
          position: _subTextSlide,
          child: FadeTransition(
            opacity: _subTextFade,
            child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
              // child: AnimatedNameText(
              //   staticText: "",
              //   targetText:
              //       "Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala.",
              //   duration: Duration(seconds: 3),
              //   jumbleSpeed: Duration(milliseconds: 30),
              //   targetTextStyle: Theme.of(context).textTheme.displaySmall,
              // )
              child: Text(
                'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
                ),
          ),
        ),
        const SizedBox(height: 25),

        // Button Animation
        SlideTransition(
          position: _btnSlide,
          child: FadeTransition(
            opacity: _btnFade,
            child: const Row(
              children: [
                DownloadCvBtn(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// class DownloadCvBtn extends StatelessWidget {
//   const DownloadCvBtn({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () {
//         // Handle download action
//       },
//       child: const Text("Download CV"),
//     );
//   }
// }
