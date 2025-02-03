import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/common_tooltip.dart';

class TorchIcon extends StatelessWidget {
  const TorchIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        // final status = state.showSpotLight ? "on" : "off";
        final msg = state.showSpotLight
            ? "Spotlight mode : on, hover over screen to view hidden details"
            : "Click to enable spotlight";
        return GestureDetector(
          onTap: () {
            context.read<ThemeBloc>().add(ToggleSpotLight());
          },
          child: CommonTooltip(
            msg: msg,
            child: Icon(
              Icons.light,
              color: context.primaryColor,
            ),
          ),
        ).showCursorOnHover;
      },
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Offset pointerPosition;
  final Color bgColor;

  SpotlightPainter(
    this.pointerPosition,
    this.bgColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          bgColor,
        ],
        stops: const [0.2, 1.0],
      ).createShader(
        Rect.fromCircle(center: pointerPosition, radius: 100),
      )
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(
      Offset.zero & size,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint on every pointer move
  }
}
