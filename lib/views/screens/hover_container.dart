import 'package:flutter/material.dart';

class HoverContainer extends StatefulWidget {
  const HoverContainer({
    super.key,
    required this.child,
  });
  final Widget child;
  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
      child: widget.child,
    );
  }
}
