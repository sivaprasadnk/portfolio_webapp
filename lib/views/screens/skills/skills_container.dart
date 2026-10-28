import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class SkillsContainer extends StatelessWidget {
  const SkillsContainer({
    super.key,
    required this.skillDetails,
  });

  final SkillDetails skillDetails;

  @override
  Widget build(BuildContext context) {
    final skillName = skillDetails.title.trim();
    final icon = 'assets/svg/${skillDetails.iconName}.svg';

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;

        return ListenableBuilder(
          listenable: GamificationController.instance,
          builder: (context, _) {
            final boost =
                GamificationController.instance.getSkillBoost(skillName);
            final isMax = boost >= 5;
            final progress = (0.75 + (boost * 0.05)).clamp(0.0, 1.0);

            return PortfolioStyledCard(
              width:
                  context.isLargeDevice ? 225 : (context.screenWidth - 48) / 2,
              cyberHeader: '~/skill/${skillName.toLowerCase()}.bin',
              onTap: () =>
                  GamificationController.instance.boostSkill(skillName),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isMax
                              ? const Color(0xFFF59E0B).withOpacity(0.2)
                              : accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMax ? '★ MAXED' : 'Lv.${boost + 1}',
                          style: context.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMax ? const Color(0xFFF59E0B) : accent,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: context.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            accent.withOpacity(themeState.isDark ? 0.14 : 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isMax
                              ? const Color(0xFFF59E0B)
                              : accent.withOpacity(0.35),
                          width: isMax ? 1.8 : 1.0,
                        ),
                        boxShadow: isMax
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(0.35),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                      child: SvgPicture.asset(
                        icon,
                        height: 34,
                        width: 34,
                        colorFilter: ColorFilter.mode(
                          isMax ? const Color(0xFFF59E0B) : accent,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      skillName,
                      textAlign: TextAlign.center,
                      style: context.displaySmall.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: context.primaryColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMax ? const Color(0xFFF59E0B) : accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMax
                            ? const Color(0xFF10B981).withOpacity(0.16)
                            : secondary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isMax ? '✓ OVERCLOCKED' : '⚡ POWER UP (+15 XP)',
                        style: context.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMax ? const Color(0xFF10B981) : secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
