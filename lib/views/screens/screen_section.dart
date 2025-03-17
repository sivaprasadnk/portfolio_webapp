import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/screens/section.title.dart';

class ScreenSection extends StatefulWidget {
  const ScreenSection({
    super.key,
    required this.title,
    required this.details,
    required this.imageName,
    this.keepAlive = true,
  });
  final String title;
  final Widget details;
  final String imageName;
  final bool keepAlive;

  @override
  State<ScreenSection> createState() => _ScreenSectionState();
}

class _ScreenSectionState extends State<ScreenSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // double leftPadding = context.isLargeDevice ? 150 : 20;
    // final double leftPadding = context.screenWidth * 0.1;
    // final double padding = !isMobilePlatform ? context.screenWidth * 0.09 : 20;
    return Container(
      width: isMobilePlatform ? double.infinity : double.infinity,
      // padding: EdgeInsets.only(left: padding, right: 0),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WindowsLargeSectionTitle(
              title: widget.title,
            ).addLeftPadding(
                isMobilePlatform ? 20 : context.screenWidth * 0.09),
            widget.details,
          ],
        ),
      ),
    );
  }
}
