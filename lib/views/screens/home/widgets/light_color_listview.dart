import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/theme_list.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class LightColorListView extends StatelessWidget {
  const LightColorListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            height: 35,
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: lightColorList.length,
              itemBuilder: (context, index) {
                final color = lightColorList[index];
                final isDarkTheme =
                    state.themeData.brightness == Brightness.dark;

                return GestureDetector(
                  onTap: () {
                    try {
                      if (isDarkTheme) {
                        context.read<ThemeBloc>().add(
                              UpdateTheme(
                                brightness: state.themeData.brightness,
                                primaryColor: color,
                                bgColor: context.scaffoldColor,
                              ),
                            );
                      } else {
                        context.read<ThemeBloc>().add(
                              UpdateTheme(
                                brightness: state.themeData.brightness,
                                primaryColor: context.primaryColor,
                                bgColor: color,
                              ),
                            );
                      }
                    } catch (err) {
                      debugPrint('err $err');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 22,
                    width: 22,
                    // margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        width: 2,
                        color: kGreyColor,
                      ),
                    ),
                  ),
                ).showCursorOnHover;
              },
            ),
          ),
        );
      },
    );
  }
}
