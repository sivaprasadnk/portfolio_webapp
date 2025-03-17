import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';

class HomeScreenLarge extends StatefulWidget {
  const HomeScreenLarge({super.key});

  @override
  State<HomeScreenLarge> createState() => _HomeScreenLargeState();
}

class _HomeScreenLargeState extends State<HomeScreenLarge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool showImage = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      setState(() {
        showImage = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final leftPadding = screenWidth * 0.1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Added fade-in effect for image
              AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: showImage
                    ? AnimatedOpacity(
                        duration: const Duration(seconds: 1),
                        opacity: showImage ? 1 : 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.4,
                            minWidth: screenWidth * 0.1,
                          ),
                          child: Image.asset(
                            'assets/images/dash/dash1.png',
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              return child;
                            },
                            height: 250,
                            width: screenWidth * 0.4,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 250,
                        width: screenWidth * 0.4,
                      ),
              ),
              const SizedBox(height: 15),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Hi,\nI'm Sivaprasad NK.",
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: context.screenWidth * 0.4,
                    child: Text(
                      'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala.',
                      style: context.displaySmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const DownloadCvBtn(),
            ],
          ),
        ),
        if (context.isLargeDevice)
          const OrbitAnimation3(), // ✅ Kept the orbiting effect
      ],
    );
  }
}
