import 'package:flutter/material.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';

class ViewMoreContainerSmall extends StatelessWidget {
  const ViewMoreContainerSmall({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    return Container(
      margin: const EdgeInsets.only(top: 5, right: 5, bottom: 8),
      decoration: BoxDecoration(
        color: kPrimaryBlueColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: screenWidth > 600
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'View More',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontSize: 12,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.info,
                  color: kWhiteColor,
                ),
              ),
      ),
    ).showCursorOnHover;
  }
}
