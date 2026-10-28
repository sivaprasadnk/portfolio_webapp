import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/screen_details/screen_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class TabItem extends StatefulWidget {
  const TabItem({
    super.key,
    required this.title,
    required this.screen,
    this.tabController,
    this.onSelect,
  });

  final TabController? tabController;
  final String title;
  final Screen screen;
  final ValueChanged<Screen>? onSelect;

  @override
  State<TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<TabItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final isCyber = themeState.portfolioStyle == PortfolioStyle.cyber;

        return BlocBuilder<ScreenBloc, ScreenState>(
          builder: (context, screenState) {
            final isSelected = screenState.selectedScreen == widget.screen;

            return MouseRegion(
              onEnter: (_) => setState(() => isHovering = true),
              onExit: (_) => setState(() => isHovering = false),
              child: GestureDetector(
                onTap: () {
                  context
                      .read<ScreenBloc>()
                      .add(UpdateScreen(screen: widget.screen));
                  if (widget.onSelect != null) {
                    widget.onSelect!(widget.screen);
                  } else {
                    widget.tabController?.animateTo(
                      widget.screen.index,
                      duration: const Duration(milliseconds: 600),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withOpacity(themeState.isDark ? 0.18 : 0.12)
                        : (isHovering
                            ? context.primaryColor.withOpacity(0.06)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(isCyber ? 6 : 999),
                    border: Border.all(
                      color: isSelected
                          ? accent.withOpacity(0.55)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: AutoSizeText(
                    isCyber ? '/${widget.title.toLowerCase()}' : widget.title,
                    maxLines: 1,
                    style: context.displaySmall.copyWith(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? accent
                          : (isHovering
                              ? accent
                              : context.primaryColor.withOpacity(0.8)),
                    ),
                  ),
                ),
              ).showCursorOnHover,
            );
          },
        );
      },
    );
  }
}
