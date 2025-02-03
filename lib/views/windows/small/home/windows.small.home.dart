// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:provider/provider.dart';
// import 'package:spnk/utils/common_widgets.dart';
// import 'package:spnk/utils/extensions/widget_extensions.dart';
// import 'package:spnk/utils/screen_type.dart';
// import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
// import 'package:spnk/views/bloc/screen_details/screen_event.dart';
// import 'package:spnk/views/bloc/screen_details/screen_state.dart';
// import 'package:spnk/views/windows/common/logo_text.dart';
// import 'package:spnk/views/windows/common/theme_switch.dart';
// import 'package:spnk/views/windows/small/contactme/windows.small.contactme.screen.dart';
// import 'package:spnk/views/windows/small/experience/windows.small.experience.screen.dart';
// import 'package:spnk/views/windows/small/home/windows.small.drawer.dart';
// import 'package:spnk/views/windows/small/home/windows.small.home.screen.dart';
// import 'package:spnk/views/windows/small/projects/projects.screen.small.dart';

// class WindowsSmallHome extends StatefulWidget {
//   static const routeName = '/HomeSmall';

//   @override
//   _WindowsSmallHomeState createState() => _WindowsSmallHomeState();
// }

// class _WindowsSmallHomeState extends State<WindowsSmallHome> {
//   @override
//   void setState(VoidCallback fn) {
//     if (mounted) {
//       super.setState(fn);
//     }
//   }

//   bool showProPic = false;

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   Widget build(BuildContext context) {
//     const double size = 15;

//     final screenSize = MediaQuery.of(context).size;
//     final screenWidth = screenSize.width;
//     return Scaffold(
//       key: _scaffoldKey,
//       extendBodyBehindAppBar: true,
//       bottomNavigationBar: const Padding(
//         padding: EdgeInsets.symmetric(vertical: 10),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             WindowsRightFooter(size: size),
//           ],
//         ),
//       ),
//       appBar: PreferredSize(
//         preferredSize: Size(screenWidth, 80),
//         child: Row(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(left: 36, top: 18),
//               child: LogoText(
//                 onTap: () {},
//               ),
//             ),
//             const Spacer(),
//             const ThemeSwitch(),
//             const SizedBox(
//               width: 20,
//             ),
//             BlocBuilder<ScreenBloc, ScreenState>(
//               builder: (context, state) {
//                 return state.selectedScreen == Screen.home
//                     ? GestureDetector(
//                         onTap: () {
//                           context
//                               .read<ScreenBloc>()
//                               .add(UpdateScreen(screen: Screen.menu));
//                         },
//                         child: Icon(
//                           Icons.menu,
//                           color: Theme.of(context).splashColor,
//                         ).showCursorOnHover,
//                       )
//                     : GestureDetector(
//                         onTap: () {
//                           context.read<ScreenBloc>().add(UpdateScreen());
//                         },
//                         child: Icon(
//                           Icons.close,
//                           color: Theme.of(context).splashColor,
//                         ).showCursorOnHover,
//                       );
//               },
//             ),
//             const SizedBox(width: 10),
//           ],
//         ),
//       ),
//       body: BlocBuilder<ScreenBloc, ScreenState>(
//         builder: (context, state) {
//           final screen = context.read<ScreenBloc>().state.selectedScreen;

//           final menuSelectedCheck = screen == Screen.menu;
//           return SizedBox(
//             width: screenWidth,
//             child: Stack(
//               children: [
//                 if (!menuSelectedCheck)
//                   screen == Screen.home
//                       ? WindowsSmallHomeScreen(showProPic: showProPic)
//                       : screen == Screen.contactMe
//                           ? WindowsSmallContactMeScreen()
//                           : screen == Screen.projects
//                               ? ProjectsScreenSmall()
//                               : screen == Screen.experience
//                                   ? WindowsSmallExperienceScreen()
//                                   : const SizedBox.shrink()
//                 else
//                   WindowsSmallDrawer(),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
