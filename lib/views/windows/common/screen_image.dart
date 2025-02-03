import 'package:flutter/material.dart';

class ScreenImage extends StatefulWidget {
  const ScreenImage({
    Key? key,
    required this.alignment,
    required this.height,
    required this.width,
    required this.imagePath,
  }) : super(key: key);

  final AlignmentGeometry alignment;
  final double height;
  final double width;
  final String imagePath;

  @override
  State<ScreenImage> createState() => _ScreenImageState();
}

class _ScreenImageState extends State<ScreenImage> {
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      setState(() {
        showLottie = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: AnimatedOpacity(
        duration: const Duration(seconds: 1),
        opacity: showLottie ? 1 : 0,
        child: Container(
          // color: Colors.black26,
          width: widget.width,
          constraints: const BoxConstraints(
            maxWidth: 400,
            minWidth: 250,
          ),
          child: Image.asset(
            widget.imagePath,
          ),
        ),
      ),
    );
  }
}
