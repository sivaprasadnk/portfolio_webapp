import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class CopyrightText extends StatelessWidget {
  const CopyrightText({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColor.withOpacity(0.5);
    final year = DateTime.now().year;
    return Text(
      'Copyright © $year Sivaprasad NK .',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
        fontSize: size,
        color: color,
      ),
    );
  }
}
