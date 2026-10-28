import 'package:animate_do/animate_do.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class WindowsLargeSectionTitle extends StatelessWidget {
  const WindowsLargeSectionTitle({
    super.key,
    required this.title,
    this.sectionIndex,
  });

  final String title;
  final String? sectionIndex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final style = state.portfolioStyle;
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;

        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (style == PortfolioStyle.cyber)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '// SECTION :: ${title.toUpperCase().replaceAll(' ', '_')}',
                      style: context.bodySmall.copyWith(
                        fontSize: 13,
                        letterSpacing: 2.0,
                        color: accent,
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(state.isDark ? 0.14 : 0.10),
                      borderRadius: BorderRadius.circular(
                        style == PortfolioStyle.bento ? 6 : 999,
                      ),
                      border: Border.all(
                        color: accent.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      title.toUpperCase(),
                      style: context.bodySmall.copyWith(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: accent,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AutoSizeText(
                        title,
                        maxLines: 1,
                        style: context.displayMedium.copyWith(
                          fontSize: context.isLargeDevice ? 38 : 30,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: style == PortfolioStyle.cyber
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: 72,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [accent, secondary],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
