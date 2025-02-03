import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class ShadowContainer extends StatefulWidget {
  const ShadowContainer({super.key, required this.child});
  final Widget child;
  @override
  State<ShadowContainer> createState() => _ShadowContainerState();
}

class _ShadowContainerState extends State<ShadowContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    BorderRadius? borderRadius;
    if (widget.child is Container) {
      final Container container = widget.child as Container;
      if (container.decoration is BoxDecoration) {
        final BoxDecoration decoration = container.decoration! as BoxDecoration;
        borderRadius = decoration.borderRadius as BorderRadius?;
      }
    }
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? context.hoverColor : context.primaryColor,
          borderRadius: borderRadius,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 2,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
