import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yt_downloader_mobile/data/services/media_storage_service.dart';
import 'package:yt_downloader_mobile/data/services/yt_extractor_service.dart';
import 'package:yt_downloader_mobile/domain/models/yt_models.dart';
import 'package:yt_downloader_mobile/main.dart';
import 'package:yt_downloader_mobile/ui/view_models/yt_downloader_view_model.dart';

class _FakeExtractorService extends YtExtractorService {
  Completer<void>? downloadGate;

  @override
  Future<YtVideoInfo> extractVideo(
    ParsedYoutubeTarget target, {
    String customEndpoint = '',
  }) async {
    return YtVideoInfo(
      videoId: target.videoId,
      title: 'Me at the zoo',
      author: 'jawed',
      urlKind: target.kind,
      publishedText: '2005-04-23',
      lengthSeconds: 19,
      viewCount: 348000000,
      likeCount: 16500000,
      rating: 4.9,
      activeProviderNode: 'On-Device YouTube Engine',
      videoStreams: const [
        YtStreamOption(
          itag: '18',
          qualityLabel: '360p',
          container: 'mp4',
          codecs: 'avc1.42001E, mp4a.40.2',
          mimeType: 'video/mp4',
          downloadUrl: 'https://example.com/video.mp4',
          isAudioOnly: false,
          isCombined: true,
          resolutionHeight: 360,
          fps: 30,
          bitrate: 500000,
          contentLengthBytes: 2 * 1024 * 1024,
        ),
      ],
      audioStreams: const [
        YtStreamOption(
          itag: '140',
          qualityLabel: '128 kbps',
          container: 'm4a',
          codecs: 'mp4a.40.2',
          mimeType: 'audio/mp4',
          downloadUrl: 'https://example.com/audio.m4a',
          isAudioOnly: true,
          isCombined: false,
          bitrate: 128000,
          contentLengthBytes: 512 * 1024,
        ),
      ],
      thumbnails: YtThumbnailOption.buildForVideo(target.videoId),
    );
  }

  @override
  Future<void> downloadStreamToFile(
    YtStreamOption stream,
    String destPath, {
    required YtCancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    final total = stream.contentLengthBytes ?? (2 * 1024 * 1024);
    onProgress?.call(total ~/ 2, total);

    if (downloadGate != null) {
      final completer = Completer<void>();
      cancelToken.addListener(() {
        if (!completer.isCompleted) {
          completer.completeError(const YtDownloadCancelledException());
        }
      });
      downloadGate!.future.then((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    }

    if (cancelToken.isCancelled) {
      throw const YtDownloadCancelledException();
    }

    onProgress?.call(total, total);
  }

  @override
  void dispose() {}
}

class _InMemoryStorageService extends MediaStorageService {
  final List<SavedMediaItem> _items = [];
  int galleryVideoSaveCount = 0;

  @override
  Future<String> allocateDestinationPath(String rawFileName) async {
    return '/mock/library/$rawFileName';
  }

  @override
  Future<List<SavedMediaItem>> loadSavedItems() async {
    return List<SavedMediaItem>.unmodifiable(_items);
  }

  @override
  Future<SavedMediaItem> registerSavedFile({
    required String videoId,
    required String title,
    required String filePath,
    required String formatBadge,
    required SavedMediaKind kind,
    bool savedToGallery = false,
  }) async {
    final item = SavedMediaItem(
      id: 'item_${_items.length + 1}_$videoId',
      videoId: videoId,
      title: title,
      fileName: filePath.split('/').last,
      filePath: filePath,
      formatBadge: formatBadge,
      sizeBytes: 2 * 1024 * 1024,
      kind: kind,
      savedAt: DateTime(2026, 11, 14, 12, 0),
      savedToGallery: savedToGallery,
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<SavedMediaItem> markSavedToGallery(SavedMediaItem target) async {
    final updated = target.copyWith(savedToGallery: true);
    final idx = _items.indexWhere((e) => e.id == target.id);
    if (idx >= 0) _items[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteSavedItem(SavedMediaItem target) async {
    _items.removeWhere((e) => e.id == target.id);
  }

  @override
  Future<void> clearLibrary() async {
    _items.clear();
  }

  @override
  Future<void> saveVideoToGallery(String filePath) async {
    galleryVideoSaveCount++;
  }

  @override
  Future<void> saveImageToGallery(String filePath) async {}
}

void main() {
  group('ParsedYoutubeTarget.tryParse', () {
    test('parses standard watch, shorts, music, youtu.be, and raw IDs', () {
      final watch = ParsedYoutubeTarget.tryParse(
        'https://www.youtube.com/watch?v=jNQXAC9IVRw&t=15s',
      );
      expect(watch, isNotNull);
      expect(watch!.videoId, 'jNQXAC9IVRw');
      expect(watch.kind, YtUrlKind.watch);
      expect(watch.startSeconds, 15);

      final shorts = ParsedYoutubeTarget.tryParse(
        'https://youtube.com/shorts/_cMxraX_5RE?feature=share',
      );
      expect(shorts, isNotNull);
      expect(shorts!.videoId, '_cMxraX_5RE');
      expect(shorts.kind, YtUrlKind.shorts);

      final music = ParsedYoutubeTarget.tryParse(
        'https://music.youtube.com/watch?v=aqz-KE-bpKQ',
      );
      expect(music, isNotNull);
      expect(music!.kind, YtUrlKind.music);

      final raw = ParsedYoutubeTarget.tryParse('jNQXAC9IVRw');
      expect(raw, isNotNull);
      expect(raw!.kind, YtUrlKind.rawId);
    });

    test('extracts YouTube link embedded inside mobile Share-sheet text', () {
      final shared = ParsedYoutubeTarget.tryParse(
        'Watch "Me at the zoo" on YouTube! https://youtu.be/jNQXAC9IVRw?si=abc123.',
      );
      expect(shared, isNotNull);
      expect(shared!.videoId, 'jNQXAC9IVRw');
      expect(shared.kind, YtUrlKind.shortLink);
    });
  });

  group('MediaStorageService disk persistence', () {
    test('allocates unique file paths, persists index, and deletes cleanly',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('yt_dl_storage_test_');
      try {
        final service =
            MediaStorageService(baseDirectoryResolver: () async => tempDir);

        final path1 = await service.allocateDestinationPath('Me_at_zoo.mp4');
        await File(path1).writeAsBytes(List<int>.filled(4096, 1), flush: true);

        final saved = await service.registerSavedFile(
          videoId: 'jNQXAC9IVRw',
          title: 'Me at the zoo',
          filePath: path1,
          formatBadge: '360p MP4',
          kind: SavedMediaKind.video,
        );
        expect(saved.sizeBytes, 4096);

        // Second allocation with same name gets _(2) suffix instead of clobbering
        final path2 = await service.allocateDestinationPath('Me_at_zoo.mp4');
        expect(path2, contains('Me_at_zoo_(2).mp4'));

        final loaded = await service.loadSavedItems();
        expect(loaded.length, 1);
        expect(loaded.first.title, 'Me at the zoo');

        await service.deleteSavedItem(saved);
        expect(await service.loadSavedItems(), isEmpty);
        expect(await File(path1).exists(), isFalse);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  testWidgets(
    'extracts video, renders inline tile progress + Cancel, and saves to Library',
    (tester) async {
      final extractor = _FakeExtractorService();
      final storage = _InMemoryStorageService();
      final vm = YtDownloaderViewModel(
        extractorService: extractor,
        storageService: storage,
      );
      addTearDown(vm.dispose);

      await tester.pumpWidget(YtDownloaderMobileApp(viewModel: vm));
      await tester.pump();

      // Enter URL and extract
      await tester.enterText(
        find.byKey(const ValueKey('yt_url_input')),
        'https://youtu.be/jNQXAC9IVRw',
      );
      await tester.pump();
      expect(find.textContaining('YOUTU.BE • jNQXAC9IVRw'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('yt_extract_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Me at the zoo'), findsOneWidget);

      const tileId = 'stream_18_v_mp4';
      final saveBtn = find.byKey(const ValueKey('download_btn_$tileId'));

      // ScrollListView down so the lazy stream tile builds into the viewport
      await tester.scrollUntilVisible(
        saveBtn,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('360p'), findsOneWidget);
      expect(saveBtn, findsOneWidget);

      // Start gated download to verify inline progress + Cancel inside tile
      extractor.downloadGate = Completer<void>();
      await tester.tap(saveBtn);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('inline_progress_$tileId')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cancel_download_$tileId')),
        findsOneWidget,
      );
      expect(find.textContaining('1.0 / 2.0 MB (50%)'), findsOneWidget);

      // Test cancelling inline
      await tester.tap(find.byKey(const ValueKey('cancel_download_$tileId')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('inline_progress_$tileId')),
        findsNothing,
      );
      expect(vm.savedItems, isEmpty);

      // Now run download to completion
      extractor.downloadGate = null;
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(vm.savedItems.length, 1);
      expect(storage.galleryVideoSaveCount, 1);

      // Switch to Library tab and verify saved item card renders
      await tester.tap(find.text('Library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Offline Downloads Library'), findsOneWidget);
      expect(find.text('360p MP4'), findsOneWidget);
      expect(find.text('IN GALLERY'), findsOneWidget);
    },
  );
}
