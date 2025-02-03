import 'package:flutter/material.dart';
import 'package:spnk/utils/common_colors.dart';

class ImageContainerSmall extends StatelessWidget {
  const ImageContainerSmall({
    Key? key,
    this.isWeb = false,
    required this.imagePath,
  }) : super(key: key);
  final String imagePath;
  final bool isWeb;
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    return Container(
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        color:
            isWeb ? const Color.fromRGBO(155, 101, 101, 1) : kTransparentColor,
        // color: Color.fromARGB(255, 129, 144, 157),
      ),
      height: screenHeight * 0.71,
      width: 300,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
        child: Image.asset(
          imagePath,
          fit: isWeb ? BoxFit.fitWidth : BoxFit.cover,
        ),
      ),
    );
  }
}
