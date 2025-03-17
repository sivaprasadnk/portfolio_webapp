import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadCvBtn extends StatefulWidget {
  const DownloadCvBtn({super.key});

  @override
  State<DownloadCvBtn> createState() => _DownloadCvBtnState();
}

class _DownloadCvBtnState extends State<DownloadCvBtn>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.5), // Slide down
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeIn,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeInOut,
      ),
    );

    // Reset and repeat when animation completes
    _iconController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _iconController.reset();
        _iconController.forward();
      }
    });
  }

  void _onHover(bool isHovered) {
    if (isHovered) {
      _iconController.repeat(); // Start repeating when hovered
    } else {
      _iconController.stop(); // Stop when hover ends
      _iconController.reset();
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: InkWell(
        onTap: () async {
          try {
            await launchUrl(
              Uri.parse(resumeLink),
            );
          } catch (e) {
            debugPrint("## Error launching URL: $e");
          }
        },
        child: AnimatedContainer(
          duration: const Duration(seconds: 1),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: Row(
            children: [
              Text(
                "Download CV",
                style: context.displaySmall.copyWith(
                  color: context.scaffoldColor,
                ),
              ),
              const SizedBox(width: 15),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Icon(
                    Icons.arrow_downward,
                    color: context.scaffoldColor,
                  ),
                ),
              ),
            ],
          ),
        ).showCursorOnHover.addShadowOnHover,
      ),
    );
  }
}
