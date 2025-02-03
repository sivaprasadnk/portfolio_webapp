import 'package:flutter/material.dart';
import 'package:spnk/utils/common_colors.dart';

class MinSize extends StatelessWidget {
  const MinSize({
    Key? key,
    this.minWidth,
    this.minHeight,
    required this.child,
  }) : super(key: key);

  final Widget child;

  final double? minWidth;

  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldScrollVertical =
            minHeight != null && constraints.maxHeight <= minHeight!;
        final contentHeight =
            shouldScrollVertical ? minHeight : constraints.maxHeight;

        final shouldScrollHorizontal =
            minWidth != null && constraints.maxWidth <= minWidth!;
        final contentWidth =
            shouldScrollHorizontal ? minWidth : constraints.maxWidth;
        debugPrint('constraints.maxHeight => ${constraints.maxHeight}');
        debugPrint('shouldScrollVertical => $shouldScrollVertical');
        debugPrint('contentHeight => $contentHeight');
        debugPrint('shouldScrollHorizontal => $shouldScrollHorizontal');
        debugPrint('contentWidth => $contentWidth');
        return Theme(
          data: Theme.of(context).copyWith(
            highlightColor: kWhiteColor, //Does not work
          ),
          child: SingleChildScrollView(
            physics: shouldScrollVertical
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Scrollbar(
              // thumbVisibility: shouldScrollHorizontal,
              thumbVisibility: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: shouldScrollHorizontal
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: UnconstrainedBox(
                  child: SizedBox(
                    height: contentHeight,
                    width: contentWidth,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
