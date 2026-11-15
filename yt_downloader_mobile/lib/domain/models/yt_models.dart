import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;

enum YtUrlKind {
  watch('VIDEO'),
  shorts('SHORTS'),
  music('YT MUSIC'),
  live('LIVE'),
  shortLink('YOUTU.BE'),
  embed('EMBED'),
  rawId('VIDEO ID');

  const YtUrlKind(this.badge);
  final String badge;
}

class ParsedYoutubeTarget {
  const ParsedYoutubeTarget({
    required this.videoId,
    required this.kind,
    this.playlistId,
    this.startSeconds = 0,
  });

  final String videoId;
  final YtUrlKind kind;
  final String? playlistId;
  final int startSeconds;

  String get canonicalWatchUrl => 'https://www.youtube.com/watch?v=$videoId';

  static final RegExp _rawIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  static final RegExp _urlInTextRegex = RegExp(r'https?://[^\s<>"]+');

  static ParsedYoutubeTarget? tryParse(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    if (_rawIdRegex.hasMatch(trimmed)) {
      return ParsedYoutubeTarget(
        videoId: trimmed,
        kind: YtUrlKind.rawId,
      );
    }

    // Support shared strings from Android/iOS share sheets like:
    // "Watch this video! https://youtu.be/jNQXAC9IVRw?si=abc"
    final urlMatches = _urlInTextRegex.allMatches(trimmed);
    if (urlMatches.isNotEmpty) {
      for (final match in urlMatches) {
        final candidate = match.group(0)!;
        final parsed = _tryParseSingleUrl(candidate);
        if (parsed != null) return parsed;
      }
    }

    return _tryParseSingleUrl(trimmed);
  }

  static ParsedYoutubeTarget? _tryParseSingleUrl(String candidateInput) {
    var normalized = candidateInput.trim();
    // Strip trailing punctuation if copied from chat message
    normalized = normalized.replaceAll(RegExp(r'[).,!?;]+$'), '');
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final playlistId = uri.queryParameters['list'];
    final startSeconds = _parseTimestamp(
      uri.queryParameters['t'] ?? uri.queryParameters['start'],
    );

    if (host == 'youtu.be') {
      if (segments.isNotEmpty && _rawIdRegex.hasMatch(segments.first)) {
        return ParsedYoutubeTarget(
          videoId: segments.first,
          kind: YtUrlKind.shortLink,
          playlistId: playlistId,
          startSeconds: startSeconds,
        );
      }
      return null;
    }

    final isYoutubeDomain = host == 'youtube.com' ||
        host == 'm.youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtube-nocookie.com';
    if (!isYoutubeDomain) return null;

    final isMusic = host == 'music.youtube.com';

    final vParam = uri.queryParameters['v'];
    if (vParam != null && _rawIdRegex.hasMatch(vParam)) {
      return ParsedYoutubeTarget(
        videoId: vParam,
        kind: isMusic ? YtUrlKind.music : YtUrlKind.watch,
        playlistId: playlistId,
        startSeconds: startSeconds,
      );
    }

    if (segments.length >= 2) {
      final prefix = segments[0].toLowerCase();
      final candidate = segments[1];
      if (_rawIdRegex.hasMatch(candidate)) {
        switch (prefix) {
          case 'shorts':
            return ParsedYoutubeTarget(
              videoId: candidate,
              kind: YtUrlKind.shorts,
              playlistId: playlistId,
              startSeconds: startSeconds,
            );
          case 'live':
            return ParsedYoutubeTarget(
              videoId: candidate,
              kind: YtUrlKind.live,
              playlistId: playlistId,
              startSeconds: startSeconds,
            );
          case 'embed':
          case 'v':
            return ParsedYoutubeTarget(
              videoId: candidate,
              kind: YtUrlKind.embed,
              playlistId: playlistId,
              startSeconds: startSeconds,
            );
        }
      }
    }

    return null;
  }

  static int _parseTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final direct = int.tryParse(raw.replaceAll('s', ''));
    if (direct != null && direct >= 0) return direct;

    final match =
        RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$').firstMatch(raw);
    if (match == null) return 0;
    final h = int.tryParse(match.group(1) ?? '0') ?? 0;
    final m = int.tryParse(match.group(2) ?? '0') ?? 0;
    final s = int.tryParse(match.group(3) ?? '0') ?? 0;
    return h * 3600 + m * 60 + s;
  }
}

class YtStreamOption {
  const YtStreamOption({
    required this.itag,
    required this.qualityLabel,
    required this.container,
    required this.codecs,
    required this.mimeType,
    required this.downloadUrl,
    required this.isAudioOnly,
    required this.isCombined,
    this.resolutionHeight = 0,
    this.fps = 30,
    this.bitrate = 0,
    this.contentLengthBytes,
    this.nativeStreamInfo,
  });

  final String itag;
  final String qualityLabel;
  final String container;
  final String codecs;
  final String mimeType;
  final String downloadUrl;
  final bool isAudioOnly;
  final bool isCombined;
  final int resolutionHeight;
  final int fps;
  final int bitrate;
  final int? contentLengthBytes;
  final yte.StreamInfo? nativeStreamInfo;

  String get fileExtension {
    if (isAudioOnly) {
      if (container.contains('mp4') || container == 'm4a') return 'm4a';
      if (container.contains('webm')) return 'webm';
      if (container.contains('mp3')) return 'mp3';
      return 'm4a';
    }
    if (container.contains('webm')) return 'webm';
    return 'mp4';
  }

  String get formattedSize {
    final bytes = contentLengthBytes;
    if (bytes == null || bytes <= 0) return 'Stream';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get codecShortLabel {
    final c = codecs.toLowerCase();
    if (c.contains('av01')) return 'AV1';
    if (c.contains('avc1') || c.contains('h264')) return 'H.264';
    if (c.contains('vp9') || c.contains('vp09')) return 'VP9';
    if (c.contains('opus')) return 'OPUS';
    if (c.contains('mp4a') || c.contains('aac')) return 'AAC';
    return container.toUpperCase();
  }

  String get tierBadge {
    if (isAudioOnly) {
      if (bitrate >= 140000) return 'HQ AUDIO';
      if (bitrate >= 100000) return 'STD AUDIO';
      return 'LITE AUDIO';
    }
    if (resolutionHeight >= 2160) return '4K UHD';
    if (resolutionHeight >= 1440) return '2K QHD';
    if (resolutionHeight >= 1080) return 'FULL HD';
    if (resolutionHeight >= 720) return 'HD';
    return 'SD';
  }
}

class YtThumbnailOption {
  const YtThumbnailOption({
    required this.id,
    required this.label,
    required this.resolution,
    required this.url,
  });

  final String id;
  final String label;
  final String resolution;
  final String url;

  static List<YtThumbnailOption> buildForVideo(String videoId) {
    return [
      YtThumbnailOption(
        id: 'maxresdefault',
        label: 'Max Resolution HD',
        resolution: '1280 × 720',
        url: 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg',
      ),
      YtThumbnailOption(
        id: 'sddefault',
        label: 'Standard HD',
        resolution: '640 × 480',
        url: 'https://i.ytimg.com/vi/$videoId/sddefault.jpg',
      ),
      YtThumbnailOption(
        id: 'hqdefault',
        label: 'High Quality',
        resolution: '480 × 360',
        url: 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      ),
      YtThumbnailOption(
        id: 'mqdefault',
        label: 'Medium Quality',
        resolution: '320 × 180',
        url: 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg',
      ),
    ];
  }
}

class YtCaptionOption {
  const YtCaptionOption({
    required this.label,
    required this.languageCode,
    this.downloadUrl = '',
    this.nativeTrackInfo,
  });

  final String label;
  final String languageCode;
  final String downloadUrl;
  final yte.ClosedCaptionTrackInfo? nativeTrackInfo;
}

class YtVideoInfo {
  const YtVideoInfo({
    required this.videoId,
    required this.title,
    required this.author,
    required this.urlKind,
    this.authorUrl = '',
    this.description = '',
    this.publishedText = '',
    this.lengthSeconds = 0,
    this.viewCount,
    this.likeCount,
    this.dislikeCount,
    this.rating,
    this.videoStreams = const [],
    this.audioStreams = const [],
    this.captions = const [],
    this.thumbnails = const [],
    this.activeProviderNode = '',
    this.streamWarning,
  });

  final String videoId;
  final String title;
  final String author;
  final YtUrlKind urlKind;
  final String authorUrl;
  final String description;
  final String publishedText;
  final int lengthSeconds;
  final int? viewCount;
  final int? likeCount;
  final int? dislikeCount;
  final double? rating;
  final List<YtStreamOption> videoStreams;
  final List<YtStreamOption> audioStreams;
  final List<YtCaptionOption> captions;
  final List<YtThumbnailOption> thumbnails;
  final String activeProviderNode;
  final String? streamWarning;

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get primaryThumbnailUrl =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  String get hdThumbnailUrl =>
      'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';

  bool get hasMediaStreams =>
      videoStreams.isNotEmpty || audioStreams.isNotEmpty;

  String get formattedDuration {
    if (lengthSeconds <= 0) return 'LIVE / CLIP';
    final hours = lengthSeconds ~/ 3600;
    final minutes = (lengthSeconds % 3600) ~/ 60;
    final seconds = lengthSeconds % 60;
    final secPad = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final minPad = minutes.toString().padLeft(2, '0');
      return '$hours:$minPad:$secPad';
    }
    return '$minutes:$secPad';
  }

  String get sanitizedBaseName {
    final cleaned = title
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    if (cleaned.isEmpty) return 'youtube_$videoId';
    return cleaned.length > 64 ? cleaned.substring(0, 64) : cleaned;
  }

  static String formatCompactCount(int? value) {
    if (value == null) return '—';
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

enum SavedMediaKind {
  video('VIDEO'),
  audio('AUDIO'),
  thumbnail('IMAGE'),
  subtitle('SUBTITLE'),
  metadata('JSON');

  const SavedMediaKind(this.badge);
  final String badge;
}

class SavedMediaItem {
  const SavedMediaItem({
    required this.id,
    required this.videoId,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.formatBadge,
    required this.sizeBytes,
    required this.kind,
    required this.savedAt,
    this.savedToGallery = false,
  });

  final String id;
  final String videoId;
  final String title;
  final String fileName;
  final String filePath;
  final String formatBadge;
  final int sizeBytes;
  final SavedMediaKind kind;
  final DateTime savedAt;
  final bool savedToGallery;

  String get thumbnailUrl => 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

  String get formattedSize {
    if (sizeBytes <= 0) return '0 KB';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  SavedMediaItem copyWith({bool? savedToGallery}) {
    return SavedMediaItem(
      id: id,
      videoId: videoId,
      title: title,
      fileName: fileName,
      filePath: filePath,
      formatBadge: formatBadge,
      sizeBytes: sizeBytes,
      kind: kind,
      savedAt: savedAt,
      savedToGallery: savedToGallery ?? this.savedToGallery,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoId': videoId,
        'title': title,
        'fileName': fileName,
        'filePath': filePath,
        'formatBadge': formatBadge,
        'sizeBytes': sizeBytes,
        'kind': kind.name,
        'savedAt': savedAt.toIso8601String(),
        'savedToGallery': savedToGallery,
      };

  factory SavedMediaItem.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'video';
    final resolvedKind = SavedMediaKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => SavedMediaKind.video,
    );
    return SavedMediaItem(
      id: json['id'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? 'Saved Media',
      fileName: json['fileName'] as String? ?? 'media.bin',
      filePath: json['filePath'] as String? ?? '',
      formatBadge: json['formatBadge'] as String? ?? 'FILE',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      kind: resolvedKind,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      savedToGallery: json['savedToGallery'] == true,
    );
  }
}

class YtSamplePreset {
  const YtSamplePreset({
    required this.label,
    required this.videoId,
    required this.tag,
  });

  final String label;
  final String videoId;
  final String tag;

  String get url => 'https://www.youtube.com/watch?v=$videoId';

  static const List<YtSamplePreset> presets = [
    YtSamplePreset(
      label: 'Me at the zoo',
      videoId: 'jNQXAC9IVRw',
      tag: '0:19 Classic',
    ),
    YtSamplePreset(
      label: 'Blender Sprite Fright',
      videoId: '_cMxraX_5RE',
      tag: '4K Open Movie',
    ),
    YtSamplePreset(
      label: 'Big Buck Bunny 60fps',
      videoId: 'aqz-KE-bpKQ',
      tag: 'HD Animation',
    ),
  ];
}

