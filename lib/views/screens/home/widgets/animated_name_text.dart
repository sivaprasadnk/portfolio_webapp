import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedNameText extends StatefulWidget {
  final String staticText;
  final String targetText;
  final Duration duration;
  final Duration jumbleSpeed;
  final TextStyle? staticTextStyle;
  final TextStyle? targetTextStyle;

  const AnimatedNameText({
    super.key,
    required this.staticText,
    required this.targetText,
    this.duration = const Duration(seconds: 2),
    this.jumbleSpeed = const Duration(milliseconds: 40),
    this.staticTextStyle,
    this.targetTextStyle,
  });

  @override
  State<AnimatedNameText> createState() => _AnimatedNameTextState();
}

class _AnimatedNameTextState extends State<AnimatedNameText>
    with TickerProviderStateMixin {
  late List<String> _displayedText;
  late Timer? _jumbleTimer;
  int _revealIndex = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize with random characters
    _displayedText = List.generate(
      widget.targetText.length,
      (index) => widget.targetText[index] == ' ' ? ' ' : _getRandomChar(),
    );

    _startJumbleEffect();
  }

  String _getRandomChar() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()';
    return chars[_random.nextInt(chars.length)];
  }

  void _startJumbleEffect() {
    _jumbleTimer = Timer.periodic(widget.jumbleSpeed, (timer) {
      setState(() {
        // Jumble remaining characters
        for (int i = _revealIndex; i < widget.targetText.length; i++) {
          if (widget.targetText[i] != ' ') {
            _displayedText[i] = _getRandomChar();
          }
        }

        // Gradually reveal characters
        if (_revealIndex < widget.targetText.length) {
          if (widget.targetText[_revealIndex] != ' ') {
            _displayedText[_revealIndex] = widget.targetText[_revealIndex];
          }
          _revealIndex++;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _jumbleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Static Text
        if (widget.staticText.isNotEmpty)
          Text(
            widget.staticText,
            style: widget.staticTextStyle ??
                Theme.of(context).textTheme.displayMedium,
          ),
        // Animated Target Text
        AnimatedSwitcher(
          duration: widget.jumbleSpeed,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Text(
            _displayedText.join(),
            key: ValueKey<String>(_displayedText.join()),
            style: widget.targetTextStyle ??
                Theme.of(context).textTheme.displayMedium,
          ),
        ),
      ],
    );
  }
}
