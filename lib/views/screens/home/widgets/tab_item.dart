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

        return BlocBuilder<ScreenBloc, ScreenState>(
          builder: (context, screenState) {
            final isSelected = screenState.selectedScreen == widget.screen;

            return MouseRegion(
              onEnter: (_) => setState(() => isHovering = true),
              onExit: (_) => setState(() => isHovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        widget.title.toUpperCase(),
                        maxLines: 1,
                        style: context.displaySmall.copyWith(
                          fontSize: 13,
                          letterSpacing: 1.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? accent
                              : (isHovering
                                  ? accent
                                  : context.primaryColor
                                      .withValues(alpha: 0.72)),
                          shadows: isSelected
                              ? [
                                  Shadow(
                                    color: accent.withValues(alpha: 0.75),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 2,
                        width: isSelected ? 24 : (isHovering ? 12 : 0),
                        decoration: BoxDecoration(
                          color: accent,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.85),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
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
