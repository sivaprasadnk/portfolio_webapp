import 'package:animate_do/animate_do.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class WindowsLargeSectionTitle extends StatelessWidget {
  const WindowsLargeSectionTitle({
    super.key,
    required this.title,
  });
  final String title;
  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      child: Container(
        padding: EdgeInsets.only(
          top: context.isLargeDevice ? context.screenHeight * 0.13 : 100,
          bottom: context.isLargeDevice ? 30 : 40,
        ),
        child: AutoSizeText(
          title,
          style: context.displayMedium,
        ),
      ),
    );
  }
}
