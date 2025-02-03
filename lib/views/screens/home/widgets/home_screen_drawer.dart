import 'package:animate_do/animate_do.dart';
import 'package:auto_animated/auto_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/screens/animation_item_builder.dart';
import 'package:spnk/views/screens/home/widgets/copyright_text.dart';

class HomeScreenDrawer extends StatelessWidget {
  const HomeScreenDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.close,
                  color: context.primaryColor,
                ),
              ).showCursorOnHover,
              const SizedBox(width: 16),
            ],
          ),
          // const SizedBox(height: 0),`
          FadeInRightBig(
            child: Image.asset(
              'assets/images/exp_icon.png',
              height: 215,
            ),
          ),
          // const SizedBox(height: 15),
          SizedBox(
            width: 320,
            child: LiveList(
              shrinkWrap: true,
              separatorBuilder: (ctx, _) => const SizedBox(height: 10),
              padding: const EdgeInsets.all(15),
              showItemInterval: const Duration(milliseconds: 200),
              itemCount: Screen.values.length,
              itemBuilder: animationItemBuilder((index) {
                final screen = Screen.values[index];
                return ListItem(
                  title: screen.menuName,
                  callback: () {
                    Navigator.pop(context);
                    context
                        .read<ScreenBloc>()
                        .add(UpdateScreen(screen: screen));
                  },
                  icon: screen.icon,
                );

              }),
            ),
          ),
          const Spacer(),
          const CopyrightText(size: 15),
          // const Spacer(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

class ListItem extends StatefulWidget {
  final String title;
  final VoidCallback callback;
  final IconData icon;
  const ListItem({
    required this.title,
    required this.callback,
    required this.icon,
  });

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {

    return Theme(
      data: ThemeData(
        splashColor: kTransparentColor,
        highlightColor: kTransparentColor,
      ),
      child: MouseRegion(
        opaque: false,
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
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ListTile(
            dense: true,
            hoverColor: kTransparentColor,
            onTap: () {
              widget.callback.call();
              setState(() {});
            },
            leading: Icon(
              widget.icon,
              color: !isHovering ? context.primaryColor : context.hoverColor,
            ),
            title: Text(
              widget.title,
              style: context.displaySmall.copyWith(
                color: !isHovering ? context.primaryColor : context.hoverColor,
              ),
            ),
          ).showCursorOnHover,
        ),
      ),
    );
  }
}
