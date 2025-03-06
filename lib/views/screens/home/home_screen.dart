import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/int_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/screen_details/screen_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/about_me/about_me_screen.dart';
import 'package:spnk/views/screens/contact_me/contact_me_screen.dart';
import 'package:spnk/views/screens/experience/experience_screen.dart';
import 'package:spnk/views/screens/home/home_screen_large.dart';
import 'package:spnk/views/screens/home/home_screen_small.dart';
import 'package:spnk/views/screens/home/widgets/animated_footer.dart';
import 'package:spnk/views/screens/home/widgets/home_screen_drawer.dart';
import 'package:spnk/views/screens/home/widgets/logo_text.dart';
import 'package:spnk/views/screens/home/widgets/menu_icon.dart';
import 'package:spnk/views/screens/home/widgets/tab_item.dart';
import 'package:spnk/views/screens/home/widgets/theme_icon.dart';
import 'package:spnk/views/screens/home/widgets/theme_switch.dart';
import 'package:spnk/views/screens/home/widgets/torch_icon.dart';
import 'package:spnk/views/screens/projects/projects_screen.dart';
import 'package:spnk/views/screens/skills/skills_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/Home';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: Screen.values.length, vsync: this);
    _tabController.addListener(() {
      context
          .read<ScreenBloc>()
          .add(UpdateScreen(screen: _tabController.index.screenFromIndex));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Offset _mousePosition = Offset.zero;
  Offset _pointerPosition = const Offset(0, 0);
  @override
  Widget build(BuildContext context) {
    const Duration duration = Duration(seconds: 1);
    final width = context.screenWidth;
    List<Widget> menuList = [
      const SizedBox(width: 32),
      const BrightnessSwitch(),
      const SizedBox(width: 32),
      const ThemeIcon(),
      // const SizedBox(width: 16),
      // const ThemeSwitch(),
    ];
    final List<Widget> screenList = Screen.values.map((screen) {
      return TabItem(
        title: screen.menuName,
        tabController: _tabController,
        screen: screen,
      );
    }).toList();

    final List tabsList = [
      const SizedBox(
        width: 30,
      ),
      ...screenList,
    ];
    if (context.screenWidth > 995) {
      menuList = [
        const TorchIcon(),
        ...menuList,
        ...tabsList,
      ];
    } else {
      menuList = [
        ...menuList,
        const SizedBox(width: 16),
        const MenuIcon(),
        // ...[
        //   const MenuIcon(),
        // ],
      ];
    }
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final showSpotLight = state.showSpotLight;
        return MouseRegion(
          cursor: showSpotLight ? SystemMouseCursors.none : MouseCursor.defer,
          onHover: (PointerHoverEvent event) {
            setState(() {
              _mousePosition = event.position;
            });
          },
          child: Stack(
            children: [
              Scaffold(
                // bottomNavigationBar: const FooterText(),
                // bottomNavigationBar: SlideFadeText(),
                bottomNavigationBar: const AnimatedFooter(),
                extendBodyBehindAppBar: true,
                extendBody: true,
                endDrawer: const HomeScreenDrawer(),
                appBar: PreferredSize(
                  preferredSize: Size(context.screenWidth * 0.8, 65),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      title: LogoText(
                        onTap: () {
                          if (context.isLargeDevice) {
                            _tabController.animateTo(
                              0,
                              duration: duration,
                            );
                            // context.read<ThemeBloc>().add(ToggleSpotLight());
                          } else {
                            context.read<ScreenBloc>().add(UpdateScreen());
                          }
                        },
                      ),
                      actions: menuList,
                    ),
                  ),
                ),
                body: context.screenWidth < 995
                    ? BlocBuilder<ScreenBloc, ScreenState>(
                        builder: (context, state) {
                          switch (state.selectedScreen) {
                            case Screen.home:
                              return const HomeScreenSmall();
                            case Screen.contactMe:
                              return ContactMeScreen();
                            case Screen.projects:
                              return ProjectsScreen();
                            case Screen.experience:
                              return ExperienceScreen();
                            case Screen.aboutMe:
                              return const AboutMeScreen();
                            case Screen.skills:
                              return SkillsScreen();
                          }
                        },
                      )
                    : Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.screenWidth * 0.02,
                            ),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                HomeScreenLarge(),
                                const AboutMeScreen(),
                                SkillsScreen(),
                                ExperienceScreen(),
                                ProjectsScreen(),
                                ContactMeScreen(),
                              ],
                            ),
                          ),
                          if (showSpotLight)
                            Positioned.fill(
                              child: MouseRegion(
                                onHover: (event) {
                                  setState(() {
                                    _pointerPosition = event.localPosition;
                                  });
                                },
                                child: CustomPaint(
                                  painter: SpotlightPainter(
                                    _pointerPosition,
                                    context.scaffoldColor,
                                  ),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              left: _mousePosition.dx - 35,
                              top: _mousePosition.dy - 35,
                              child: IgnorePointer(
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    seconds: 1,
                                  ),
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.primaryColor
                                            .withOpacity(0.8),
                                        spreadRadius: 50,
                                        blurRadius: 100,
                                      ),
                                    ],
                                    // border: Border.all(
                                    //   color: context.primaryColor,
                                    // ),
                                  ),
                                ),
                              ),
                            ),
                          
                        ],
                      ),
              ),
              // if (context.isLargeDevice)
              //   Positioned(
              //     left: _mousePosition.dx - 35,
              //     top: _mousePosition.dy - 35,
              //     child: IgnorePointer(
              //       child: AnimatedContainer(
              //         duration: const Duration(
              //           seconds: 1,
              //         ),
              //         width: 70,
              //         height: 70,
              //         decoration: BoxDecoration(
              //           shape: BoxShape.circle,
              //           boxShadow: [
              //             BoxShadow(
              //               color: context.primaryColor.withOpacity(0.8),
              //               spreadRadius: 50,
              //               blurRadius: 100,
              //             ),
              //           ],
              //           // border: Border.all(
              //           //   color: context.primaryColor,
              //           // ),
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        );
      },
    );
  }
}
