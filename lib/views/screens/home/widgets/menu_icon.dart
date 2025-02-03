import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';

class MenuIcon extends StatelessWidget {
  const MenuIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Scaffold.of(context).openEndDrawer();
          },
          child: Icon(
            Icons.menu,
            color: context.primaryColor,
          ),
        );
      },
    ).showCursorOnHover;
  }
}
