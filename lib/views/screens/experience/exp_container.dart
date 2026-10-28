import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class ExpContainer extends StatelessWidget {
  const ExpContainer({super.key, required this.experience});
  final ExperienceDetails experience;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;

        return PortfolioStyledCard(
          width: context.isLargeDevice ? 370 : double.infinity,
          cyberHeader: '~/career/${experience.orgName.split(' ').first.toLowerCase()}.log',
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(themeState.isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accent.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${experience.startDate} — ${experience.endDate}",
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.work_outline_rounded,
                    color: secondary.withOpacity(0.75),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                experience.title,
                style: context.displaySmall.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 16,
                    color: context.primaryColor.withOpacity(0.65),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      experience.orgName,
                      style: context.bodyMedium.copyWith(
                        fontSize: 16,
                        color: context.primaryColor.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                color: themeState.cardBorderColor,
                height: 1,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: experience.detailsList.map((desc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.primaryColor.withOpacity(0.10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          desc,
                          style: context.bodySmall.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
