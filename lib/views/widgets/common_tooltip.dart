import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class CommonTooltip extends StatelessWidget {
  const CommonTooltip({
    super.key,
    required this.msg,
    required this.child,
  });
  final String msg;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      textStyle: context.displaySmall.copyWith(fontSize: 12),
      decoration: BoxDecoration(
        color: context.scaffoldColor,
        border: Border.all(
          color: context.primaryColor,
        ),
      ),
      message: msg,
      child: child,
    );
  }
}
