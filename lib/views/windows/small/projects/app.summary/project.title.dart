import 'package:flutter/material.dart';

class ProjectTitle extends StatelessWidget {
  const ProjectTitle({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'PlayfairDisplay',
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 23.0,
      ),
    );
  }
}
