import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      child: Container(
        width: context.screenWidth * 0.35,
        // width: 180,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            width: 2,
            color: Colors.cyan,
          ),
        ),
        margin: EdgeInsets.only(
          left: context.screenWidth * 0.1,
          top: context.screenHeight * 0.2,
        ),
        child: Center(
          child: Text(
            title,
            style: context.displaySmall,
          ),
        ),
      ),
    );
  }
}
