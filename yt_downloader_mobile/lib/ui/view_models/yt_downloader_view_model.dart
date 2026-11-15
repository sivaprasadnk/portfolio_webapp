import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/services/media_storage_service.dart';
import '../../data/services/yt_extractor_service.dart';
import '../../domain/models/yt_models.dart';
import '../core/app_theme.dart';

enum YtMediaTab {
  video('Video'),
  audio('Audio'),
  thumbnails('Covers'),
  tools('Tools');

  const YtMediaTab(this.label);
  final String label;
}

enum YtContainerFilter {
  all('All'),
  mp4('MP4'),
  webm('WebM');

  const YtContainerFilter(this.label);
  final String label;
}

class YtActionFeedback {
  const YtActionFeedback({
    required this.message,
    this.isError = false,
    this.wasCancelled = false,
    this.savedItem,
  });

  final String message;
  final bool isError;
  final bool wasCancelled;
  final SavedMediaItem? savedItem;
}

class YtDownloaderViewModel extends ChangeNotifier {
  YtDownloaderViewModel({
    YtExtractorService? extractorService,
    MediaStorageService? storageService,
  })  : _extractor = extractorService ?? YtExtractorService(),
        _storage = storageService ?? MediaStorageService();

  final YtExtractorService _extractor;
  final MediaStorageService _storage;

  YtThemeConfig _themeConfig = const YtThemeConfig();
  YtThemeConfig get themeConfig => _themeConfig;

  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  SavedMediaKind? _libraryFilterKind;
  SavedMediaKind? get libraryFilterKind => _libraryFilterKind;

  String _rawUrlInput = '';
  String get rawUrlInput => _rawUrlInput;

  ParsedYoutubeTarget? _parsedTarget;
  ParsedYoutubeTarget? get parsedTarget => _parsedTarget;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  YtVideoInfo? _videoInfo;
  YtVideoInfo? get videoInfo => _videoInfo;

  YtMediaTab _activeTab = YtMediaTab.video;
  YtMediaTab get activeTab => _activeTab;

  YtContainerFilter _containerFilter = YtContainerFilter.all;
  YtContainerFilter get containerFilter => _containerFilter;

  bool _autoSaveToGallery = true;
  bool get autoSaveToGallery => _autoSaveToGallery;

  String _customEndpoint = '';
  String get customEndpoint => _customEndpoint;

  // Inline per-tile download progress state (rendered directly inside the active tile)
  String? _activeDownloadId;
  String? get activeDownloadId => _activeDownloadId;

  double? _downloadProgress;
  double? get downloadProgress => _downloadProgress;

  String _downloadStageLabel = '';
  String get downloadStageLabel => _downloadStageLabel;

  YtCancelToken? _activeCancelToken;

  List<SavedMediaItem> _savedItems = const [];
  List<SavedMediaItem> get savedItems => _savedItems;

  List<SavedMediaItem> get filteredSavedItems {
    if (_libraryFilterKind == null) return _savedItems;
    return _savedItems.where((e) => e.kind == _libraryFilterKind).toList();
  }

  List<YtStreamOption> get filteredVideoStreams {
    final streams = _videoInfo?.videoStreams ?? const [];
    switch (_containerFilter) {
      case YtContainerFilter.all:
        return streams;
      case YtContainerFilter.mp4:
        return streams
            .where((s) => s.container.toLowerCase() == 'mp4')
            .toList();
      case YtContainerFilter.webm:
        return streams
            .where((s) => s.container.toLowerCase() == 'webm')
            .toList();
    }
  }

  static String streamTileId(YtStreamOption s) =>
      'stream_${s.itag}_${s.isAudioOnly ? 'a' : 'v'}_${s.container}';

  static String thumbnailTileId(YtThumbnailOption t) => 'thumb_${t.id}';

  static String captionTileId(YtCaptionOption c) =>
      'caption_${c.languageCode}_${c.label}';

  static const String metadataTileId = 'tool_metadata_json';

  Future<void> initialize() async {
    _savedItems = await _storage.loadSavedItems();
    notifyListeners();

    _storage.listenForSharedText((sharedText) {
      final parsed = ParsedYoutubeTarget.tryParse(sharedText);
      if (parsed != null) {
        _selectedNavIndex = 0;
        updateUrlInput(sharedText);
        fetchMedia(sharedText);
      }
    });

    final initialShared = await _storage.consumeInitialSharedText();
    if (initialShared != null) {
      final parsed = ParsedYoutubeTarget.tryParse(initialShared);
      if (parsed != null) {
        _selectedNavIndex = 0;
        updateUrlInput(initialShared);
        await fetchMedia(initialShared);
      }
    }
  }

  void setSelectedNavIndex(int index) {
    if (_selectedNavIndex == index) return;
    _selectedNavIndex = index;
    notifyListeners();
  }

  void setLibraryFilterKind(SavedMediaKind? kind) {
    if (_libraryFilterKind == kind) return;
    _libraryFilterKind = kind;
    notifyListeners();
  }

  void updateUrlInput(String value) {
    _rawUrlInput = value;
    _parsedTarget = ParsedYoutubeTarget.tryParse(value);
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void clearInput() {
    _rawUrlInput = '';
    _parsedTarget = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setActiveTab(YtMediaTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void setContainerFilter(YtContainerFilter filter) {
    if (_containerFilter == filter) return;
    _containerFilter = filter;
    notifyListeners();
  }

  void setAutoSaveToGallery(bool enabled) {
    if (_autoSaveToGallery == enabled) return;
    _autoSaveToGallery = enabled;
    notifyListeners();
  }

  void setCustomEndpoint(String endpoint) {
    _customEndpoint = endpoint.trim();
    notifyListeners();
  }

  void updateTheme(YtThemeConfig next) {
    _themeConfig = next;
    notifyListeners();
  }

  Future<void> fetchMedia([String? explicitInput]) async {
    if (explicitInput != null) {
      _rawUrlInput = explicitInput;
      _parsedTarget = ParsedYoutubeTarget.tryParse(explicitInput);
    }

    final target = _parsedTarget ?? ParsedYoutubeTarget.tryParse(_rawUrlInput);
    if (target == null) {
      _errorMessage =
          'Enter or paste a valid YouTube Watch, Shorts, Music, Live, or youtu.be link.';
      notifyListeners();
      return;
    }

    _parsedTarget = target;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _extractor.extractVideo(
        target,
        customEndpoint: _customEndpoint,
      );
      _videoInfo = info;
      if (target.kind == YtUrlKind.music && info.audioStreams.isNotEmpty) {
        _activeTab = YtMediaTab.audio;
      } else if (!info.hasMediaStreams) {
        _activeTab = YtMediaTab.thumbnails;
      } else if (_activeTab == YtMediaTab.thumbnails ||
          _activeTab == YtMediaTab.tools) {
        _activeTab = YtMediaTab.video;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void cancelActiveDownload() {
    _activeCancelToken?.cancel();
  }

  Future<YtActionFeedback> downloadStream(YtStreamOption stream) async {
    final info = _videoInfo;
    if (info == null) {
      return const YtActionFeedback(
        message: 'Extract a video first.',
        isError: true,
      );
    }
    if (_activeDownloadId != null) {
      return const YtActionFeedback(
        message: 'Another download is currently in progress.',
        isError: true,
      );
    }

    final tileId = streamTileId(stream);
    final cancelToken = YtCancelToken();
    _activeCancelToken = cancelToken;
    _activeDownloadId = tileId;
    _downloadProgress = 0.0;
    _downloadStageLabel = 'Connecting...';
    notifyListeners();

    final qualitySlug = stream.qualityLabel
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '')
        .toLowerCase();
    final desiredName =
        '${info.sanitizedBaseName}_${qualitySlug.isEmpty ? stream.itag : qualitySlug}.${stream.fileExtension}';

    try {
      final destPath = await _storage.allocateDestinationPath(desiredName);
      var lastNotifiedMs = 0;

      await _extractor.downloadStreamToFile(
        stream,
        destPath,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final isComplete = total != null && total > 0 && received >= total;
          if (!isComplete && now - lastNotifiedMs < 90) return;
          lastNotifiedMs = now;

          final recvMb = (received / (1024 * 1024)).toStringAsFixed(1);
          if (total != null && total > 0) {
            final pct = (received / total).clamp(0.0, 1.0);
            final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
            _downloadProgress = pct;
            _downloadStageLabel =
                '$recvMb / $totalMb MB (${(pct * 100).round()}%)';
          } else {
            _downloadProgress = null;
            _downloadStageLabel = '$recvMb MB downloaded';
          }
          notifyListeners();
        },
      );

      var exportedToGallery = false;
      if (_autoSaveToGallery &&
          !stream.isAudioOnly &&
          stream.fileExtension == 'mp4') {
        _downloadStageLabel = 'Saving to Gallery...';
        notifyListeners();
        try {
          await _storage.saveVideoToGallery(destPath);
          exportedToGallery = true;
        } catch (_) {
          exportedToGallery = false;
        }
      }

      final badge =
          '${stream.qualityLabel} ${stream.fileExtension.toUpperCase()}';
      final saved = await _storage.registerSavedFile(
        videoId: info.videoId,
        title: info.title,
        filePath: destPath,
        formatBadge: badge,
        kind: stream.isAudioOnly ? SavedMediaKind.audio : SavedMediaKind.video,
        savedToGallery: exportedToGallery,
      );
      _savedItems = await _storage.loadSavedItems();

      return YtActionFeedback(
        message: exportedToGallery
            ? 'Saved ${saved.formatBadge} to Gallery & Library'
            : 'Saved ${saved.formatBadge} to Library (${saved.formattedSize})',
        savedItem: saved,
      );
    } on YtDownloadCancelledException {
      return const YtActionFeedback(
        message: 'Download cancelled.',
        wasCancelled: true,
      );
    } catch (e) {
      return YtActionFeedback(
        message: 'Download failed: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      _activeCancelToken = null;
      _activeDownloadId = null;
      _downloadProgress = null;
      _downloadStageLabel = '';
      notifyListeners();
    }
  }

  Future<YtActionFeedback> downloadThumbnail(YtThumbnailOption option) async {
    final info = _videoInfo;
    if (info == null) {
      return const YtActionFeedback(
        message: 'Extract a video first.',
        isError: true,
      );
    }
    if (_activeDownloadId != null) {
      return const YtActionFeedback(
        message: 'Another download is currently in progress.',
        isError: true,
      );
    }

    final tileId = thumbnailTileId(option);
    final cancelToken = YtCancelToken();
    _activeCancelToken = cancelToken;
    _activeDownloadId = tileId;
    _downloadProgress = null;
    _downloadStageLabel = 'Fetching HD cover...';
    notifyListeners();

    final desiredName = '${info.sanitizedBaseName}_${option.id}.jpg';

    try {
      final destPath = await _storage.allocateDestinationPath(desiredName);
      await _extractor.downloadThumbnailToFile(
        option,
        info.videoId,
        destPath,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          if (total != null && total > 0) {
            _downloadProgress = (received / total).clamp(0.0, 1.0);
          }
          notifyListeners();
        },
      );

      var exportedToGallery = false;
      if (_autoSaveToGallery) {
        _downloadStageLabel = 'Saving to Gallery...';
        notifyListeners();
        try {
          await _storage.saveImageToGallery(destPath);
          exportedToGallery = true;
        } catch (_) {
          exportedToGallery = false;
        }
      }

      final saved = await _storage.registerSavedFile(
        videoId: info.videoId,
        title: info.title,
        filePath: destPath,
        formatBadge: '${option.resolution} JPG',
        kind: SavedMediaKind.thumbnail,
        savedToGallery: exportedToGallery,
      );
      _savedItems = await _storage.loadSavedItems();

      return YtActionFeedback(
        message: exportedToGallery
            ? 'Saved cover image to Gallery & Library'
            : 'Saved cover image to Library',
        savedItem: saved,
      );
    } on YtDownloadCancelledException {
      return const YtActionFeedback(
        message: 'Cover download cancelled.',
        wasCancelled: true,
      );
    } catch (e) {
      return YtActionFeedback(
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      _activeCancelToken = null;
      _activeDownloadId = null;
      _downloadProgress = null;
      _downloadStageLabel = '';
      notifyListeners();
    }
  }

  Future<YtActionFeedback> downloadCaption(YtCaptionOption caption) async {
    final info = _videoInfo;
    if (info == null) {
      return const YtActionFeedback(
        message: 'Extract a video first.',
        isError: true,
      );
    }
    if (_activeDownloadId != null) {
      return const YtActionFeedback(
        message: 'Another download is currently in progress.',
        isError: true,
      );
    }

    _activeDownloadId = captionTileId(caption);
    _downloadProgress = null;
    _downloadStageLabel = 'Saving subtitles...';
    notifyListeners();

    final desiredName =
        '${info.sanitizedBaseName}_${caption.languageCode}.vtt';

    try {
      final destPath = await _storage.allocateDestinationPath(desiredName);
      await _extractor.downloadCaptionToFile(caption, destPath);

      final saved = await _storage.registerSavedFile(
        videoId: info.videoId,
        title: info.title,
        filePath: destPath,
        formatBadge: '${caption.languageCode.toUpperCase()} VTT',
        kind: SavedMediaKind.subtitle,
      );
      _savedItems = await _storage.loadSavedItems();

      return YtActionFeedback(
        message: 'Saved ${caption.label} subtitles to Library',
        savedItem: saved,
      );
    } catch (e) {
      return YtActionFeedback(
        message: 'Subtitle export failed: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      _activeDownloadId = null;
      _downloadProgress = null;
      _downloadStageLabel = '';
      notifyListeners();
    }
  }

  Future<YtActionFeedback> exportMetadataJson() async {
    final info = _videoInfo;
    if (info == null) {
      return const YtActionFeedback(
        message: 'Extract a video first.',
        isError: true,
      );
    }

    _activeDownloadId = metadataTileId;
    _downloadStageLabel = 'Writing JSON...';
    notifyListeners();

    try {
      final destPath = await _storage.allocateDestinationPath(
        '${info.sanitizedBaseName}_metadata.json',
      );
      final payload = {
        'videoId': info.videoId,
        'url': info.watchUrl,
        'title': info.title,
        'author': info.author,
        'authorUrl': info.authorUrl,
        'publishedText': info.publishedText,
        'lengthSeconds': info.lengthSeconds,
        'formattedDuration': info.formattedDuration,
        'viewCount': info.viewCount,
        'likeCount': info.likeCount,
        'dislikeCount': info.dislikeCount,
        'rating': info.rating,
        'providerNode': info.activeProviderNode,
        'videoStreamCount': info.videoStreams.length,
        'audioStreamCount': info.audioStreams.length,
        'description': info.description,
        'exportedAt': DateTime.now().toIso8601String(),
      };
      final formatted = const JsonEncoder.withIndent('  ').convert(payload);
      final file = File(destPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(formatted, flush: true);

      final saved = await _storage.registerSavedFile(
        videoId: info.videoId,
        title: info.title,
        filePath: destPath,
        formatBadge: 'META JSON',
        kind: SavedMediaKind.metadata,
      );
      _savedItems = await _storage.loadSavedItems();

      return YtActionFeedback(
        message: 'Saved video metadata JSON to Library',
        savedItem: saved,
      );
    } catch (e) {
      return YtActionFeedback(
        message: 'Metadata export failed: $e',
        isError: true,
      );
    } finally {
      _activeDownloadId = null;
      _downloadStageLabel = '';
      notifyListeners();
    }
  }

  Future<void> shareCurrentVideoLink() async {
    final info = _videoInfo;
    if (info == null) return;
    await _storage.shareText('${info.title}\n${info.watchUrl}');
  }

  Future<YtActionFeedback> shareSavedItem(SavedMediaItem item) async {
    try {
      await _storage.shareFile(item.filePath, title: item.title);
      return YtActionFeedback(message: 'Shared ${item.fileName}');
    } catch (e) {
      return YtActionFeedback(
        message: 'Unable to open share sheet: $e',
        isError: true,
      );
    }
  }

  Future<YtActionFeedback> saveItemToGallery(SavedMediaItem item) async {
    try {
      if (item.kind == SavedMediaKind.video) {
        await _storage.saveVideoToGallery(item.filePath);
      } else if (item.kind == SavedMediaKind.thumbnail) {
        await _storage.saveImageToGallery(item.filePath);
      } else {
        await _storage.shareFile(item.filePath, title: item.title);
        return YtActionFeedback(
          message: 'Opened ${item.fileName} in system sheet',
        );
      }
      await _storage.markSavedToGallery(item);
      _savedItems = await _storage.loadSavedItems();
      notifyListeners();
      return YtActionFeedback(
        message: 'Saved ${item.fileName} to Gallery (${MediaStorageService.galleryAlbumName})',
      );
    } catch (e) {
      return YtActionFeedback(
        message:
            'Could not save directly to Gallery (try Share -> Save to Files): $e',
        isError: true,
      );
    }
  }

  Future<void> openDeviceGallery() async {
    try {
      await _storage.openGallery();
    } catch (_) {}
  }

  Future<void> deleteSavedItem(SavedMediaItem item) async {
    await _storage.deleteSavedItem(item);
    _savedItems = await _storage.loadSavedItems();
    notifyListeners();
  }

  Future<void> clearLibrary() async {
    await _storage.clearLibrary();
    _savedItems = const [];
    notifyListeners();
  }

  Future<void> reloadVideoFromLibrary(SavedMediaItem item) async {
    _selectedNavIndex = 0;
    final url = 'https://www.youtube.com/watch?v=${item.videoId}';
    updateUrlInput(url);
    await fetchMedia(url);
  }

  @override
  void dispose() {
    _activeCancelToken?.cancel();
    _extractor.dispose();
    super.dispose();
  }
}

