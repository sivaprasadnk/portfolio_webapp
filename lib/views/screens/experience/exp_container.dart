import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
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
        final stageNum = experience.order + 1;

        return PortfolioStyledCard(
          width: context.isLargeDevice ? 370 : double.infinity,
          cyberHeader:
              '~/quest/stage_0${stageNum}_${experience.orgName.split(' ').first.toLowerCase()}.log',
          onTap: () {
            GamificationController.instance.completeQuest('career_chronicler');
            GamificationController.instance.addXp(
              15,
              reason: 'Cleared Stage 0$stageNum: ${experience.title}!',
              uniqueKey: 'exp_stage_$stageNum',
            );
          },
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          accent.withOpacity(themeState.isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accent.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'STAGE 0$stageNum • ${experience.startDate} – ${experience.endDate}',
                      style: context.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '✓ CLEARED',
                      style: context.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
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
                    Icons.castle_rounded,
                    size: 16,
                    color: secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Guild: ${experience.orgName}',
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
              const SizedBox(height: 14),
              Text(
                'QUEST LOOT & SKILLS ACQUIRED:',
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: context.primaryColor.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 10),
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
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          desc,
                          style: context.bodySmall.copyWith(
                            fontSize: 14,
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
