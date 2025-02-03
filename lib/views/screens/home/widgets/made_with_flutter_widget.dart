import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class MadeWithFlutterWidget extends StatelessWidget {
  const MadeWithFlutterWidget({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.end,
    required this.size,
  });
  final MainAxisAlignment mainAxisAlignment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor.withOpacity(0.5);
    return Row(
      mainAxisAlignment: mainAxisAlignment,
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
        AvatarGlow(
          glowColor: color,
          endRadius: 20.0,
          showTwoGlows: false,
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
          ),
        ),
        // CircleAvatar(
        //   child: Icon(
        //     Icons.favorite,
        //     color: Colors.red,
        //   ),
        // ),
        Text(
          ' in ',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
            fontSize: size,
            color: color,

            fontFamily: 'Roboto',
          ),
        ),
        FlutterLogo(
          size: size,
        ),
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
