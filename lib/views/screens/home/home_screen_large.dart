import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';

class HomeScreenLarge extends StatefulWidget {
  const HomeScreenLarge({super.key, this.onExploreProjects});

  final VoidCallback? onExploreProjects;

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
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
        setState(() {
          showImage = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final horizontalPad = screenWidth * 0.08;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final isCyber = state.portfolioStyle == PortfolioStyle.cyber;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: 36,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accent
                                    .withOpacity(state.isDark ? 0.14 : 0.10),
                                borderRadius:
                                    BorderRadius.circular(isCyber ? 6 : 999),
                                border:
                                    Border.all(color: accent.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCyber
                                        ? 'SYS.ONLINE // FLUTTER_ENGINEER'
                                        : 'Available for Flutter & Web Projects',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            if (showImage)
                              Image.asset(
                                'assets/images/dash/dash1.png',
                                height: 54,
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          "Hi, I'm",
                          style: context.displaySmall.copyWith(
                            fontSize: 24,
                            color: context.primaryColor.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sivaprasad NK.",
                          style:
                              Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontSize: 56,
                                    height: 1.08,
                                    letterSpacing: -1.0,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: Text(
                            'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala — building fast, clean, cross-platform mobile & web experiences.',
                            style: context.displaySmall.copyWith(
                              fontSize: 21,
                              height: 1.5,
                              color: context.primaryColor.withOpacity(0.82),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        DownloadCvBtn(
                          onExploreProjects: widget.onExploreProjects,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Flexible(
                flex: 5,
                child: OrbitAnimation3(),
              ),
            ],
          ),
        );
      },
    );
  }
}
