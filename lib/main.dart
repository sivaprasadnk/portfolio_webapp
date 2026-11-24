import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_event.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_event.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_event.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/project/project_event.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/arcade/arcade_screen.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_home_screen.dart';
import 'package:spnk/views/screens/home/home_screen.dart';
import 'package:spnk/views/screens/privacy_policy/chronocraft_privacy_policy_screen.dart';
import 'package:spnk/views/screens/privacy_policy/qrcode_privacy_policy_screen.dart';
import 'package:spnk/views/screens/privacy_policy/yt_downloader_privacy_policy_screen.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';
import 'package:spnk/views/screens/solar/solar_system_screen.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';

void main() {
  setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage('assets/images/mesh1.jpg'), context);
    precacheImage(const AssetImage('assets/images/dash/dash1.png'), context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<ScreenBloc>(create: (_) => ScreenBloc()),
        BlocProvider<AboutMeBloc>(
          create: (_) => AboutMeBloc()
            ..add(
              FetchAboutMe(),
            ),
        ),
        BlocProvider<ExpDetailsBloc>(
          create: (_) => ExpDetailsBloc()
            ..add(
              FetchExpDetails(),
            ),
        ),
        BlocProvider<ProjectBloc>(
          create: (_) => ProjectBloc()
            ..add(
              FetchProjects(),
            ),
        ),
        BlocProvider<SkillDetailsBloc>(
          create: (_) => SkillDetailsBloc()
            ..add(
              FetchSkillDetailsEvent(),
            ),
        ),
        BlocProvider<ContactDetailsBloc>(
          create: (_) => ContactDetailsBloc()
            ..add(
              FetchContactDetails(),
            ),
        ),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            title: 'Sivaprasad NK',
            debugShowCheckedModeBanner: false,
            theme: state.themeData,
            initialRoute: initialRoute,
            routes: {
              '/': (context) => const SplashScreen(),
              HomeScreen.routeName: (context) => const HomeScreen(),
              '/home': (context) => const HomeScreen(),
              InteractiveGridHomeScreen.routeName: (context) =>
                  const InteractiveGridHomeScreen(),
              '${InteractiveGridHomeScreen.routeName}/': (context) =>
                  const InteractiveGridHomeScreen(),
              RacingPortfolioScreen.routeName: (context) =>
                  const RacingPortfolioScreen(),
              '${RacingPortfolioScreen.routeName}/': (context) =>
                  const RacingPortfolioScreen(),
              SolarSystemPortfolioScreen.routeName: (context) =>
                  const SolarSystemPortfolioScreen(),
              '${SolarSystemPortfolioScreen.routeName}/': (context) =>
                  const SolarSystemPortfolioScreen(),
              ChronoCraftPrivacyPolicyScreen.routeName: (context) =>
                  const ChronoCraftPrivacyPolicyScreen(),
              '${ChronoCraftPrivacyPolicyScreen.routeName}/': (context) =>
                  const ChronoCraftPrivacyPolicyScreen(),
              QrCodePrivacyPolicyScreen.routeName: (context) =>
                  const QrCodePrivacyPolicyScreen(),
              '${QrCodePrivacyPolicyScreen.routeName}/': (context) =>
                  const QrCodePrivacyPolicyScreen(),
              YtDownloaderPrivacyPolicyScreen.routeName: (context) =>
                  const YtDownloaderPrivacyPolicyScreen(),
              '${YtDownloaderPrivacyPolicyScreen.routeName}/': (context) =>
                  const YtDownloaderPrivacyPolicyScreen(),
              QrCodeScreen.routeName: (context) => const QrCodeScreen(),
              '${QrCodeScreen.routeName}/': (context) => const QrCodeScreen(),
              ArcadeScreen.routeName: (context) => const ArcadeScreen(),
              '${ArcadeScreen.routeName}/': (context) => const ArcadeScreen(),
              YtDownloaderScreen.routeName: (context) =>
                  const YtDownloaderScreen(),
              '${YtDownloaderScreen.routeName}/': (context) =>
                  const YtDownloaderScreen(),
            },
            onGenerateRoute: (settings) {
              final name = settings.name ?? '';
              if (name.startsWith('/chronocraft/privacy-policy')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const ChronoCraftPrivacyPolicyScreen(),
                );
              }
              if (name.startsWith('/qrcode/privacy-policy')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const QrCodePrivacyPolicyScreen(),
                );
              }
              if (name.startsWith('/yt-downloader/privacy-policy') ||
                  name.startsWith('/youtube-downloader/privacy-policy')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const YtDownloaderPrivacyPolicyScreen(),
                );
              }
              if (name.startsWith('/qrcode')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const QrCodeScreen(),
                );
              }
              if (name.startsWith('/arcade')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const ArcadeScreen(),
                );
              }
              if (name.startsWith('/yt-downloader') ||
                  name.startsWith('/youtube-downloader')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const YtDownloaderScreen(),
                );
              }
              if (name == '/v2' ||
                  name.startsWith('/v2/') ||
                  name.startsWith('/v2?')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const RacingPortfolioScreen(),
                );
              }
              if (name == '/v3' ||
                  name.startsWith('/v3/') ||
                  name.startsWith('/v3?')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const SolarSystemPortfolioScreen(),
                );
              }
              if (name == '/v4' ||
                  name.startsWith('/v4/') ||
                  name.startsWith('/v4?')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const InteractiveGridHomeScreen(),
                );
              }
              if (name == '/home' || name == HomeScreen.routeName) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const HomeScreen(),
                );
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  bool _matchesV2(String value) =>
      value == '/v2' || value.startsWith('/v2/') || value.startsWith('/v2?');

  bool _matchesV3(String value) =>
      value == '/v3' || value.startsWith('/v3/') || value.startsWith('/v3?');

  bool _matchesV4(String value) =>
      value == '/v4' || value.startsWith('/v4/') || value.startsWith('/v4?');

  @override
  Widget build(BuildContext context) {
    final path = Uri.base.path;
    final fragment = Uri.base.fragment;
    if (_matchesV4(path) || _matchesV4(fragment)) {
      return const InteractiveGridHomeScreen();
    }
    if (_matchesV3(path) || _matchesV3(fragment)) {
      return const SolarSystemPortfolioScreen();
    }
    if (_matchesV2(path) || _matchesV2(fragment)) {
      return const RacingPortfolioScreen();
    }
    if (path.startsWith('/chronocraft/privacy-policy') ||
        fragment.startsWith('/chronocraft/privacy-policy')) {
      return const ChronoCraftPrivacyPolicyScreen();
    }
    if (path.startsWith('/qrcode/privacy-policy') ||
        fragment.startsWith('/qrcode/privacy-policy')) {
      return const QrCodePrivacyPolicyScreen();
    }
    if (path.startsWith('/yt-downloader/privacy-policy') ||
        fragment.startsWith('/yt-downloader/privacy-policy') ||
        path.startsWith('/youtube-downloader/privacy-policy') ||
        fragment.startsWith('/youtube-downloader/privacy-policy')) {
      return const YtDownloaderPrivacyPolicyScreen();
    }
    if (path.startsWith('/qrcode') || fragment.startsWith('/qrcode')) {
      return const QrCodeScreen();
    }
    if (path.startsWith('/arcade') || fragment.startsWith('/arcade')) {
      return const ArcadeScreen();
    }
    if (path.startsWith('/yt-downloader') ||
        fragment.startsWith('/yt-downloader') ||
        path.startsWith('/youtube-downloader') ||
        fragment.startsWith('/youtube-downloader')) {
      return const YtDownloaderScreen();
    }
    return HomeScreen();
  }
}
