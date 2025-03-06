import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class MadeWithFlutterWidget extends StatelessWidget {
  const MadeWithFlutterWidget({
    super.key,
    required this.size,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor.withOpacity(0.5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          ' Made with ',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
            fontSize: size,
            color: color,
            fontFamily: 'Roboto',
          ),
        ),
        // AvatarGlow(
        //   glowColor: color,
        //   endRadius: 10.0,
        //   showTwoGlows: false,
        //   child: const Icon(
        //     Icons.favorite,
        //     color: Colors.red,
        //   ),
        // ),
        // CircleAvatar(
        //   radius: ,
        //   child: Icon(
        //     Icons.favorite,
        //     color: Colors.red,
        //     size: 16,
        //   ),
        // ),
        Icon(
          Icons.favorite,
          color: Colors.red,
          size: 16,
        ),
        Text(
          '  in ',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
            fontSize: size,
            color: color,

            fontFamily: 'Roboto',
          ),
        ),
        // Icon(Icons.logo)
        // FlutterLogo(
        //   size: size,
        // ),
        Text(
          ' Flutter  ',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
            fontSize: size,
            color: color,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
