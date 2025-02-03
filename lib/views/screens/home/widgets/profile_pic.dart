import 'package:flutter/material.dart';

class ProfilePic extends StatelessWidget {
  const ProfilePic({super.key, required this.width});
  final double width;
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 900),
      opacity: 1,
      child: Image.asset(
        'assets/images/picWithBlob.png',
        width: width,
      ),
    );
  }

  // Future<void> _delayedOpacityChange() async {
  //   await Future.delayed(
  //     const Duration(milliseconds: 100),
  //   ); // Adjust delay as needed
  // }
}
