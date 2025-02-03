import 'package:flutter/material.dart';

class SampleCommonWidget extends InheritedWidget {
  final String data;
  const SampleCommonWidget({
    required this.data,
    required super.child,
  });

  static SampleCommonWidget of(BuildContext context) {
    final SampleCommonWidget? result =
        context.dependOnInheritedWidgetOfExactType<SampleCommonWidget>();
    return result!;
  }

  @override
  bool updateShouldNotify(SampleCommonWidget oldWidget) {
    return oldWidget.data != data;
  }
}
