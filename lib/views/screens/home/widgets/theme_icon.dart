import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/dark_color_listview.dart';
import 'package:spnk/views/screens/home/widgets/light_color_listview.dart';
import 'package:spnk/views/widgets/common_tooltip.dart';

class ThemeIcon extends StatelessWidget {
  const ThemeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAnimatedDialog(context),
      child: CommonTooltip(
        msg: 'Select color themes',
        child: Icon(
          Icons.color_lens,
          color: context.primaryColor,
        ).showCursorOnHover,
      ),
    );
  }

  void _showAnimatedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Allows closing when tapping outside
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack, // Smooth scale effect
            ),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.scaffoldColor,
                  border: Border.all(
                    color: context.primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select Theme',
                              style: TextStyle(
                                color: context.primaryColor,
                                fontSize: 20,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Icon(
                                Icons.close,
                                color: context.primaryColor,
                              ),
                            ).showCursorOnHover,
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Foreground Color'),
                        if (state.themeData.brightness == Brightness.dark)
                          const LightColorListView()
                        else
                          const DarkColorListView(),
                        const SizedBox(height: 12),
                        const Text('Background Color'),
                        if (state.themeData.brightness == Brightness.dark)
                          const DarkColorListView()
                        else
                          const LightColorListView(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
