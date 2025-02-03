import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/screen_details/screen_state.dart';
// import 'package:universal_html/html.dart';

class TabItem extends StatefulWidget {
  const TabItem({
    required this.title,
    required this.tabController,
    required this.screen,
  });

  final TabController tabController;

  final String title;
  final Screen screen;

  @override
  State<TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<TabItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = context.hoverColor;
    var normalColor = !isDarkTheme ? kPrimaryBlueColor : kWhiteColor;
    normalColor = context.primaryColor;
    final currentIdx = widget.tabController.index;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovering = true;
        });
      },
      onExit: (val) {
        setState(() {
          isHovering = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              context
                  .read<ScreenBloc>()
                  .add(UpdateScreen(screen: widget.screen));
              widget.tabController.animateTo(
                widget.screen.index,
                duration: const Duration(seconds: 1),
              );
            },
            child: SizedBox(
              height: 40,
              width: 100,
              child: Center(
                child: AutoSizeText(
                  widget.title,
                  style: context.displaySmall.copyWith(
                    fontSize: 16,
                    color: currentIdx == widget.screen.index
                        ? normalColor
                        : isHovering
                            ? context.hoverColor
                            : context.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<ScreenBloc, ScreenState>(
            builder: (context, state) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  color: normalColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                width:
                    state.selectedScreen.index == widget.screen.index ? 100 : 0,
              );
            },
          ),
        ],
      ).showCursorOnHover,
    );
  }
}
