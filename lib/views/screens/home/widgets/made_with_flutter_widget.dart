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
            fontSize: size,
            color: color,
            fontFamily: 'Roboto',
          ),
        ),
        const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 16,
        ),
        Text(
          '  in ',
          style: TextStyle(
            fontSize: size,
            color: color,
            fontFamily: 'Roboto',
          ),
        ),
        Text(
          ' Flutter  ',
          style: TextStyle(
            fontSize: size,
            color: color,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}
