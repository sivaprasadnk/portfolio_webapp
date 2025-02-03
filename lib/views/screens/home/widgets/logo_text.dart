import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';

class LogoText extends StatelessWidget {
  const LogoText({Key? key, required this.onTap}) : super(key: key);
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Text(
        'SP',
        style: Theme.of(context).textTheme.displayLarge,
      ),
    ).showCursorOnHover;
  }
}
