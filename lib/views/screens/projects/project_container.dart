import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectContainer extends StatelessWidget {
  const ProjectContainer({
    super.key,
    required this.project,
  });

  final ProjectDetails project;

  Future<void> _launchProject() async {
    final containsPlayStoreUrl = project.playStoreUrl.isNotEmpty;
    final containsWebUrl = project.webUrl.isNotEmpty;
    if (containsPlayStoreUrl && containsWebUrl) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await launchUrl(Uri.parse(project.playStoreUrl));
      } else {
        await launchUrl(Uri.parse(project.webUrl));
      }
    } else if (containsPlayStoreUrl) {
      await launchUrl(Uri.parse(project.playStoreUrl));
    } else if (containsWebUrl) {
      await launchUrl(Uri.parse(project.webUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;
        final isPlayStore = project.playStoreUrl.isNotEmpty;

        return PortfolioStyledCard(
          width: context.isLargeDevice ? 370 : double.infinity,
          cyberHeader:
              '~/projects/${project.projName.toLowerCase().replaceAll(' ', '_')}',
          onTap: _launchProject,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.22),
                          secondary.withOpacity(0.14),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPlayStore
                          ? Icons.phone_android_rounded
                          : Icons.language_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: project.techStackList.map((tool) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(
                            themeState.isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          tool,
                          style: context.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                project.projName,
                style: context.displaySmall.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...project.descList.map((desc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 15,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          desc,
                          style: context.bodyMedium.copyWith(
                            fontSize: 16,
                            height: 1.35,
                            color: context.primaryColor.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              Divider(
                color: themeState.cardBorderColor,
                height: 1,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPlayStore ? 'Google Play Store' : 'Live Web App',
                    style: context.bodySmall.copyWith(
                      fontSize: 14,
                      color: context.primaryColor.withOpacity(0.65),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(
                        themeState.portfolioStyle == PortfolioStyle.cyber
                            ? 4
                            : 999,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Project',
                          style: context.bodySmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: themeState.isDark
                                ? const Color(0xFF090D16)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: themeState.isDark
                              ? const Color(0xFF090D16)
                              : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
