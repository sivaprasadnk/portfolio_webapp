import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/view_models/yt_downloader_view_model.dart';
import 'ui/views/yt_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final viewModel = YtDownloaderViewModel()..initialize();
  runApp(YtDownloaderMobileApp(viewModel: viewModel));
}

class YtDownloaderMobileApp extends StatefulWidget {
  const YtDownloaderMobileApp({
    super.key,
    this.viewModel,
  });

  final YtDownloaderViewModel? viewModel;

  @override
  State<YtDownloaderMobileApp> createState() => _YtDownloaderMobileAppState();
}

class _YtDownloaderMobileAppState extends State<YtDownloaderMobileApp> {
  late final YtDownloaderViewModel _vm;
  late final bool _ownsVm;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _vm = widget.viewModel!;
      _ownsVm = false;
    } else {
      _vm = YtDownloaderViewModel()..initialize();
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsVm) {
      _vm.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final cfg = _vm.themeConfig;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              cfg.isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              cfg.isDark ? Brightness.light : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: MaterialApp(
            title: 'YT Downloader',
            debugShowCheckedModeBanner: false,
            theme: cfg.toThemeData(),
            home: YtHomeScreen(viewModel: _vm),
          ),
        );
      },
    );
  }
}
