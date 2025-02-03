// class SlideFadeText extends StatefulWidget {
//   @override
//   _SlideFadeTextState createState() => _SlideFadeTextState();
// }

// class _SlideFadeTextState extends State<SlideFadeText>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: const Offset(0, -1),
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
//       ),
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
//       ),
//     );

//     _controller.forward();

//     _controller.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         Future.delayed(const Duration(seconds: 1), () {
//           _controller.reverse();
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SlideTransition(
//       position: _slideAnimation,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: const Text(
//           'Hello Flutter!',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';

class FooterText extends StatefulWidget {
  const FooterText({super.key});

  @override
  State<FooterText> createState() => _FooterTextState();
}

class _FooterTextState extends State<FooterText>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat();

  Animation<Offset>? _offsetAnimation1;

  Animation<Offset>? _offsetAnimation2;

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  String txt1 = "Copyright @Sivaprasad";
  String txt2 = "Made in love";
  String curntText = 'Copyright @Sivaprasad';
  @override
  void initState() {
    // Timer(const Duration(milliseconds: 200), () => _controller.forward());
    timer = Timer.periodic(const Duration(seconds: 1), (timerValue) {
      // debugPrin
      _offsetAnimation1 = Tween<Offset>(
        begin: const Offset(0, -1),
        end: const Offset(0, 0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeIn,
        ),
      );
      _offsetAnimation2 = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, 1),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeIn,
        ),
      );
      setState(() {
        timer = timerValue;
        // curntText = timerValue.tick.isEven
        //     ? curntText == txt1
        //         ? txt2
        //         : txt1
        //     : curntText == txt1
        //         ? txt2
        //         : txt1;

      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _offsetAnimation1 != null && _offsetAnimation2 != null
        ? SlideTransition(
            position:
                timer!.tick.isEven ? _offsetAnimation1! : _offsetAnimation2!,
            // offset: const Offset(0, -1),
            // duration: const Duration(seconds: 1),
            child: FadeTransition(
              opacity: _controller,
              child: Text(curntText),
            ),
          )
        : const SizedBox.shrink();
  }
}
