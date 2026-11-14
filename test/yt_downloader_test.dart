import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spnk/main.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:spnk/views/screens/yt_downloader/yt_models.dart';
import 'package:spnk/views/screens/yt_downloader/yt_service.dart';
import 'package:spnk/views/screens/yt_downloader/yt_web_helper.dart';

class _FakeYtService extends YtService {
  @override
  Future<YtVideoInfo> fetchVideoInfo(String rawInput) async {
    final parsed = ParsedYoutubeTarget.tryParse(rawInput);
    if (parsed == null) {
      throw const FormatException('Invalid YouTube URL');
    }
    return YtVideoInfo(
      videoId: parsed.videoId,
      title: 'Me at the zoo',
      author: 'jawed',
      urlKind: parsed.kind,
      lengthSeconds: 19,
      viewCount: 345000000,
      likeCount: 16500000,
      rating: 4.9,
      activeProviderNode: 'yt.test-node.local',
      videoStreams: const [
        YtStreamOption(
          itag: '137',
          qualityLabel: '1080p60',
          container: 'mp4',
          codecs: 'avc1.64002a',
          mimeType: 'video/mp4',
          downloadUrl: 'https://yt.test-node.local/latest_version?id=test&itag=137',
          isAudioOnly: false,
          isCombined: false,
          resolutionHeight: 1080,
          fps: 60,
          contentLengthBytes: 4200000,
        ),
      ],
      audioStreams: const [
        YtStreamOption(
          itag: '140',
          qualityLabel: '128 kbps',
          container: 'm4a',
          codecs: 'mp4a.40.2',
          mimeType: 'audio/mp4',
          downloadUrl: 'https://yt.test-node.local/latest_version?id=test&itag=140',
          isAudioOnly: true,
          isCombined: false,
          bitrate: 128000,
          contentLengthBytes: 310000,
        ),
      ],
      captions: const [
        YtCaptionOption(
          label: 'English',
          languageCode: 'en',
          downloadUrl: 'https://yt.test-node.local/api/v1/captions/test',
        ),
      ],
      thumbnails: YtThumbnailOption.buildForVideo(parsed.videoId),
    );
  }

  @override
  Future<Uint8List> downloadBytesWithProgress(
    String url, {
    int? expectedBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    onProgress?.call(1024, 1024);
    return Uint8List.fromList([0, 1, 2, 3, 4, 5]);
  }
}

class _FakeYtPlatformHelper implements YtPlatformHelper {
  final List<String> savedFileNames = [];

  @override
  bool get isWeb => true;

  @override
  void configurePageMeta() {}

  @override
  Future<bool> saveBytesAsFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    savedFileNames.add(fileName);
    return true;
  }

  @override
  Future<bool> triggerDirectDownload({
    required String url,
    required String fileName,
  }) async {
    savedFileNames.add(fileName);
    return true;
  }

  @override
  Future<Uint8List?> muxMp4VideoAndAudio({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
  }) async {
    return Uint8List.fromList([...videoBytes, ...audioBytes]);
  }

  @override
  Future<Uint8List?> convertAudioToWav(Uint8List encodedAudioBytes) async {
    return Uint8List.fromList([82, 73, 70, 70]);
  }

  @override
  String registerEmbedPlayer({required String videoId, int startSeconds = 0}) {
    return 'fake-embed-$videoId';
  }

  @override
  Widget buildEmbedPlayer(String viewType) {
    return const SizedBox.shrink();
  }
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    setup();
  });

  group('ParsedYoutubeTarget URL parsing', () {
    test('parses watch, shorts, music, short-links, and raw IDs', () {
      final watch = ParsedYoutubeTarget.tryParse(
        'https://www.youtube.com/watch?v=jNQXAC9IVRw&t=1m15s',
      );
      expect(watch?.videoId, 'jNQXAC9IVRw');
      expect(watch?.kind, YtUrlKind.watch);
      expect(watch?.startSeconds, 75);

      final shortUrl =
          ParsedYoutubeTarget.tryParse('https://youtu.be/aqz-KE-bpKQ');
      expect(shortUrl?.videoId, 'aqz-KE-bpKQ');
      expect(shortUrl?.kind, YtUrlKind.shortLink);

      final shorts = ParsedYoutubeTarget.tryParse(
        'https://www.youtube.com/shorts/WhWc3b3KhnY',
      );
      expect(shorts?.videoId, 'WhWc3b3KhnY');
      expect(shorts?.kind, YtUrlKind.shorts);

      final music = ParsedYoutubeTarget.tryParse(
        'https://music.youtube.com/watch?v=jNQXAC9IVRw',
      );
      expect(music?.videoId, 'jNQXAC9IVRw');
      expect(music?.kind, YtUrlKind.music);

      final rawId = ParsedYoutubeTarget.tryParse('jNQXAC9IVRw');
      expect(rawId?.videoId, 'jNQXAC9IVRw');
      expect(rawId?.kind, YtUrlKind.rawId);

      expect(ParsedYoutubeTarget.tryParse('https://example.com/foo'), isNull);
    });
  });

  testWidgets(
    'YtDownloaderScreen fetches metadata, switches tabs, and downloads MP4 + WAV',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeYtService();
      final fakeHelper = _FakeYtPlatformHelper();

      await tester.pumpWidget(
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: context.watch<ThemeBloc>().state.themeData,
                home: YtDownloaderScreen(
                  service: fakeService,
                  platformHelper: fakeHelper,
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('YouTube Downloader'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('yt_url_input')),
        'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      );
      await tester.pump();
      expect(find.text('VIDEO • jNQXAC9IVRw'), findsOneWidget);

      await tester.tap(find.byKey(const Key('yt_fetch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Me at the zoo'), findsOneWidget);
      expect(find.text('jawed'), findsOneWidget);
      expect(find.text('1080p60 • MP4'), findsOneWidget);

      // Download muxed 1080p60 MP4
      await tester.tap(find.text('Download').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(fakeHelper.savedFileNames, contains('Me_at_the_zoo_1080p60.mp4'));
      expect(find.textContaining('RECENT DOWNLOADS (1)'), findsOneWidget);

      // Switch to Audio tab & convert to WAV
      await tester.tap(find.text('Audio (2)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Studio WAV • 16-bit PCM'), findsOneWidget);

      await tester.tap(find.text('Convert & Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(fakeHelper.savedFileNames, contains('Me_at_the_zoo_128kbps.wav'));

      // Flush gamification toast timer
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Projects section in Pit-Wall Dossier lists YouTube Downloader and launches it',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('PIT WALL'));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('05 • PROJECTS'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.scrollUntilVisible(
        find.text('YouTube Downloader'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('YouTube Downloader'), findsOneWidget);

      // Close modal & flush timers
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(seconds: 3));
    },
  );
}

