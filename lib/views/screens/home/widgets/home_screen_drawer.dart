import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/screen_details/screen_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class HomeScreenDrawer extends StatelessWidget {
  const HomeScreenDrawer({super.key, this.onSelectScreen});

  final ValueChanged<Screen>? onSelectScreen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;

        return Drawer(
          child: SafeArea(
            child: BlocBuilder<ScreenBloc, ScreenState>(
              builder: (context, screenState) {
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SP',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: context.primaryColor,
                            ),
                          ),
                        ).showCursorOnHover,
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: StyleSwitcherBar(compact: true),
                    ),
                    const SizedBox(height: 16),
                    FadeInRightBig(
                      duration: const Duration(milliseconds: 400),
                      child: Image.asset(
                        'assets/images/exp_icon.png',
                        height: 140,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...Screen.values.map((screen) {
                      final isSelected = screenState.selectedScreen == screen;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? accent.withOpacity(0.6)
                                  : Colors.transparent,
                            ),
                          ),
                          tileColor: isSelected
                              ? accent.withOpacity(0.14)
                              : Colors.transparent,
                          leading: Icon(
                            screen.icon,
                            color: isSelected ? accent : context.primaryColor,
                          ),
                          title: Text(
                            screen.menuName,
                            style: context.displaySmall.copyWith(
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected ? accent : context.primaryColor,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context
                                .read<ScreenBloc>()
                                .add(UpdateScreen(screen: screen));
                            onSelectScreen?.call(screen);
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
