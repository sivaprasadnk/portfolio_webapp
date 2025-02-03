import 'package:flutter/material.dart';

class DashImage extends StatelessWidget {
  const DashImage({
    Key? key,
    required this.showLottie,
    required this.leftPadding,
    required this.size,
  }) : super(key: key);

  final bool showLottie;
  final double leftPadding;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(seconds: 1),
      opacity: showLottie ? 1 : 0,
      child: Container(
        margin: EdgeInsets.only(left: leftPadding),
        child: Image.asset(
          'assets/images/dash/dash1.png',
          height: size,
        ),
      ),
    );
  }
}
