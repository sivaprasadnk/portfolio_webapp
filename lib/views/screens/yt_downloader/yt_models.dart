enum YtUrlKind {
  watch('VIDEO'),
  shorts('SHORTS'),
  live('LIVE'),
  music('YT MUSIC'),
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
    this.startSeconds = 0,
  });

  final String videoId;
  final YtUrlKind kind;
  final int startSeconds;

  String get canonicalWatchUrl => 'https://www.youtube.com/watch?v=$videoId';

  static final RegExp _idPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  static ParsedYoutubeTarget? tryParse(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    if (_idPattern.hasMatch(trimmed)) {
      return ParsedYoutubeTarget(
        videoId: trimmed,
        kind: YtUrlKind.rawId,
      );
    }

    final normalized =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final startSec = _parseStartTime(
      uri.queryParameters['t'] ?? uri.queryParameters['start'],
    );

    // youtu.be/<id>
    if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
      if (segments.isNotEmpty && _idPattern.hasMatch(segments.first)) {
        return ParsedYoutubeTarget(
          videoId: segments.first,
          kind: YtUrlKind.shortLink,
          startSeconds: startSec,
        );
      }
      return null;
    }

    final isYoutubeHost = host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtube-nocookie.com' ||
        host.endsWith('.youtube-nocookie.com');

    if (!isYoutubeHost) return null;

    final isMusic = host.startsWith('music.');

    // ?v=<id>
    final vParam = uri.queryParameters['v'];
    if (vParam != null && _idPattern.hasMatch(vParam)) {
      return ParsedYoutubeTarget(
        videoId: vParam,
        kind: isMusic ? YtUrlKind.music : YtUrlKind.watch,
        startSeconds: startSec,
      );
    }

    // /shorts/<id>, /live/<id>, /embed/<id>, /v/<id>
    if (segments.length >= 2) {
      final prefix = segments[0].toLowerCase();
      final candidate = segments[1];
      if (_idPattern.hasMatch(candidate)) {
        if (prefix == 'shorts') {
          return ParsedYoutubeTarget(
            videoId: candidate,
            kind: YtUrlKind.shorts,
            startSeconds: startSec,
          );
        }
        if (prefix == 'live') {
          return ParsedYoutubeTarget(
            videoId: candidate,
            kind: YtUrlKind.live,
            startSeconds: startSec,
          );
        }
        if (prefix == 'embed' || prefix == 'v') {
          return ParsedYoutubeTarget(
            videoId: candidate,
            kind: YtUrlKind.embed,
            startSeconds: startSec,
          );
        }
      }
    }

    return null;
  }

  static int _parseStartTime(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final direct = int.tryParse(raw.replaceAll('s', ''));
    if (direct != null && direct >= 0) return direct;

    final match =
        RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$').firstMatch(raw);
    if (match == null) return 0;
    final h = int.tryParse(match.group(1) ?? '') ?? 0;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    final s = int.tryParse(match.group(3) ?? '') ?? 0;
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
  });

  final String itag;
  final String qualityLabel;
  final String container; // mp4, m4a, webm
  final String codecs;
  final String mimeType;
  final String downloadUrl;
  final bool isAudioOnly;
  final bool isCombined;
  final int resolutionHeight;
  final int fps;
  final int bitrate;
  final int? contentLengthBytes;

  String get fileExtension {
    final lower = container.toLowerCase();
    if (lower.isNotEmpty) return lower;
    if (isAudioOnly) {
      return mimeType.contains('webm') ? 'webm' : 'm4a';
    }
    return mimeType.contains('webm') ? 'webm' : 'mp4';
  }

  String get codecShortLabel {
    final c = codecs.toLowerCase();
    if (c.contains('av01')) return 'AV1';
    if (c.contains('avc1')) return 'H.264';
    if (c.contains('vp9')) return 'VP9';
    if (c.contains('opus')) return 'OPUS';
    if (c.contains('mp4a')) return 'AAC';
    return container.toUpperCase();
  }

  String get tierBadge {
    if (isAudioOnly) {
      if (bitrate >= 140000) return 'HQ AUDIO';
      return 'AUDIO';
    }
    if (resolutionHeight >= 2160) return '4K UHD';
    if (resolutionHeight >= 1440) return '2K QHD';
    if (resolutionHeight >= 1080) return 'FULL HD';
    if (resolutionHeight >= 720) return 'HD';
    return 'SD';
  }

  String get formattedSize {
    final bytes = contentLengthBytes;
    if (bytes == null || bytes <= 0) return 'Stream';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  bool get canRemuxToMp4 =>
      !isAudioOnly && !isCombined && fileExtension == 'mp4';
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
        id: 'maxres',
        label: 'MaxRes Ultra HD',
        resolution: '1280 × 720',
        url: 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg',
      ),
      YtThumbnailOption(
        id: 'sd',
        label: 'Standard Definition',
        resolution: '640 × 480',
        url: 'https://i.ytimg.com/vi/$videoId/sddefault.jpg',
      ),
      YtThumbnailOption(
        id: 'hq',
        label: 'High Quality',
        resolution: '480 × 360',
        url: 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      ),
      YtThumbnailOption(
        id: 'mq',
        label: 'Medium Compact',
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
    required this.downloadUrl,
  });

  final String label;
  final String languageCode;
  final String downloadUrl;
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

  YtStreamOption? get bestM4aAudio {
    for (final a in audioStreams) {
      if (a.fileExtension == 'm4a' || a.codecs.contains('mp4a')) {
        return a;
      }
    }
    return audioStreams.isNotEmpty ? audioStreams.first : null;
  }

  String get sanitizedBaseName {
    final cleaned = title
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    if (cleaned.isEmpty) return 'youtube_$videoId';
    return cleaned.length > 64 ? cleaned.substring(0, 64) : cleaned;
  }

  String get formattedDuration {
    if (lengthSeconds <= 0) return 'LIVE / CLIP';
    final hours = lengthSeconds ~/ 3600;
    final minutes = (lengthSeconds % 3600) ~/ 60;
    final seconds = lengthSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  static String formatCompactCount(int? value) {
    if (value == null || value < 0) return '—';
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
      tag: '19s • Fast Test',
    ),
    YtSamplePreset(
      label: 'Big Buck Bunny 4K',
      videoId: 'aqz-KE-bpKQ',
      tag: '4K 60fps',
    ),
    YtSamplePreset(
      label: 'Blender Spring',
      videoId: 'WhWc3b3KhnY',
      tag: 'Open Movie',
    ),
  ];
}

class YtDownloadRecord {
  const YtDownloadRecord({
    required this.videoId,
    required this.title,
    required this.formatBadge,
    required this.fileName,
    required this.completedAt,
  });

  final String videoId;
  final String title;
  final String formatBadge;
  final String fileName;
  final DateTime completedAt;

  String get thumbnailUrl => 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';
}

