import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadCvBtn extends StatefulWidget {
  const DownloadCvBtn({super.key, this.onExploreProjects});

  final VoidCallback? onExploreProjects;

  @override
  State<DownloadCvBtn> createState() => _DownloadCvBtnState();
}

class _DownloadCvBtnState extends State<DownloadCvBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;
        final isCyber = state.portfolioStyle == PortfolioStyle.cyber;

        return Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onTap: () async {
                  try {
                    await launchUrl(Uri.parse(resumeLink));
                  } catch (e) {
                    debugPrint("## Error launching URL: $e");
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  transform:
                      Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
                  decoration: BoxDecoration(
                    gradient: state.portfolioStyle == PortfolioStyle.glass
                        ? LinearGradient(colors: [accent, secondary])
                        : null,
                    color: state.portfolioStyle != PortfolioStyle.glass
                        ? accent
                        : null,
                    borderRadius: BorderRadius.circular(isCyber ? 6 : 999),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(_hovered ? 0.45 : 0.25),
                        blurRadius: _hovered ? 22 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCyber ? "> DOWNLOAD_CV" : "Download CV",
                        style: context.displaySmall.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: state.portfolioStyle == PortfolioStyle.glass
                              ? Colors.white
                              : (state.isDark
                                  ? const Color(0xFF090D16)
                                  : Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: state.portfolioStyle == PortfolioStyle.glass
                            ? Colors.white
                            : (state.isDark
                                ? const Color(0xFF090D16)
                                : Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.onExploreProjects != null)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onExploreProjects,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: state.cardSurfaceColor,
                      borderRadius: BorderRadius.circular(isCyber ? 6 : 999),
                      border: Border.all(
                        color: state.cardBorderColor,
                        width: 1.3,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCyber ? "[ VIEW_PROJECTS ]" : "Explore Projects",
                          style: context.displaySmall.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: context.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
