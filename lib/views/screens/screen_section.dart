import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
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
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          WindowsLargeSectionTitle(
            title: widget.title,
          ).addLeftPadding(horizontalPad),
          widget.details,
        ],
      ),
    );
  }
}
