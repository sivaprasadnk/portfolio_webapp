import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class SkillsContainer extends StatelessWidget {
  const SkillsContainer({
    super.key,
    required this.skillDetails,
  });

  final SkillDetails skillDetails;

  @override
  Widget build(BuildContext context) {
    final icon = 'assets/svg/${skillDetails.iconName}.svg';

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;

        return PortfolioStyledCard(
          width: context.isLargeDevice ? 220 : (context.screenWidth - 56) / 2,
          cyberHeader: '~/skill/${skillDetails.title.trim().toLowerCase()}',
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(themeState.isDark ? 0.14 : 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accent.withOpacity(0.3),
                    ),
                  ),
                  child: SvgPicture.asset(
                    icon,
                    height: 36,
                    width: 36,
                    colorFilter: ColorFilter.mode(
                      accent,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  skillDetails.title.trim(),
                  textAlign: TextAlign.center,
                  style: context.displaySmall.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Core Stack',
                    style: context.bodySmall.copyWith(
                      fontSize: 12,
                      color: context.primaryColor.withOpacity(0.65),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
