import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:spnk/views/screens/yt_downloader/yt_models.dart';

class YtDownloadCancelledException implements Exception {
  const YtDownloadCancelledException();
}

class YtService {
  YtService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String _customEndpoint = '';
  List<String>? _cachedInvidiousNodes;

  static const List<String> _fallbackInvidiousNodes = [
    'https://yt.chocolatemoo53.com',
  ];

  String get customEndpoint => _customEndpoint;

  void setCustomEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    _customEndpoint = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Future<YtVideoInfo> fetchVideoInfo(String rawInput) async {
    final parsed = ParsedYoutubeTarget.tryParse(rawInput);
    if (parsed == null) {
      throw const FormatException(
        'Please enter a valid YouTube video, Shorts, Music, or youtu.be link.',
      );
    }

    final videoId = parsed.videoId;

    // Run metadata, community votes, and stream extraction concurrently
    final results = await Future.wait<Object?>([
      _fetchOEmbed(videoId),
      _fetchVotes(videoId),
      _fetchStreams(videoId),
    ]);

    final oembed = results[0] as _OEmbedResult?;
    final votes = results[1] as _VotesResult?;
    final streamBundle = results[2] as _StreamBundleResult;

    final resolvedTitle = streamBundle.title.isNotEmpty
        ? streamBundle.title
        : (oembed?.title ?? '');
    final resolvedAuthor = streamBundle.author.isNotEmpty
        ? streamBundle.author
        : (oembed?.authorName ?? '');

    if (resolvedTitle.isEmpty && !streamBundle.hasAnyStreams) {
      throw Exception(
        'Video not found or unavailable. Check that the YouTube URL is public.',
      );
    }

    return YtVideoInfo(
      videoId: videoId,
      title: resolvedTitle.isNotEmpty ? resolvedTitle : 'YouTube Video ($videoId)',
      author: resolvedAuthor.isNotEmpty ? resolvedAuthor : 'YouTube Creator',
      urlKind: parsed.kind,
      authorUrl: oembed?.authorUrl ?? streamBundle.authorUrl,
      description: streamBundle.description,
      publishedText: streamBundle.publishedText,
      lengthSeconds: streamBundle.lengthSeconds,
      viewCount: streamBundle.viewCount ?? votes?.viewCount,
      likeCount: streamBundle.likeCount ?? votes?.likes,
      dislikeCount: votes?.dislikes,
      rating: votes?.rating,
      videoStreams: streamBundle.videoStreams,
      audioStreams: streamBundle.audioStreams,
      captions: streamBundle.captions,
      thumbnails: YtThumbnailOption.buildForVideo(videoId),
      activeProviderNode: streamBundle.providerHost,
      streamWarning: streamBundle.warningMessage,
    );
  }

  Future<Uint8List> downloadBytesWithProgress(
    String url, {
    int? expectedBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    final streamed = await _client.send(request).timeout(
          const Duration(seconds: 90),
        );

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Download failed with HTTP ${streamed.statusCode}.');
    }

    final total = streamed.contentLength ?? expectedBytes;
    final builder = BytesBuilder(copy: false);
    var received = 0;

    await for (final chunk in streamed.stream) {
      if (isCancelled != null && isCancelled()) {
        throw const YtDownloadCancelledException();
      }
      builder.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }

    return builder.takeBytes();
  }

  Future<_OEmbedResult?> _fetchOEmbed(String videoId) async {
    final watchUrl =
        Uri.encodeComponent('https://www.youtube.com/watch?v=$videoId');
    final endpoints = [
      'https://www.youtube.com/oembed?url=$watchUrl&format=json',
      'https://noembed.com/embed?url=$watchUrl',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await _client
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final map = jsonDecode(response.body) as Map<String, dynamic>;
          final title = (map['title'] as String?)?.trim() ?? '';
          if (title.isNotEmpty) {
            return _OEmbedResult(
              title: title,
              authorName: (map['author_name'] as String?)?.trim() ?? '',
              authorUrl: (map['author_url'] as String?)?.trim() ?? '',
            );
          }
        }
      } catch (_) {
        // Try fallback oEmbed mirror
      }
    }
    return null;
  }

  Future<_VotesResult?> _fetchVotes(String videoId) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              'https://returnyoutubedislikeapi.com/votes?videoId=$videoId',
            ),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        return _VotesResult(
          viewCount: (map['viewCount'] as num?)?.toInt(),
          likes: (map['likes'] as num?)?.toInt(),
          dislikes: (map['dislikes'] as num?)?.toInt(),
          rating: (map['rating'] as num?)?.toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> _resolveInvidiousNodes() async {
    if (_cachedInvidiousNodes != null && _cachedInvidiousNodes!.isNotEmpty) {
      return _cachedInvidiousNodes!;
    }

    final discovered = <String>[];
    try {
      final response = await _client
          .get(
            Uri.parse('https://api.invidious.io/instances.json?sort_by=health'),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is List && entry.length >= 2 && entry[1] is Map) {
              final meta = entry[1] as Map<String, dynamic>;
              final type = meta['type'] as String?;
              final apiEnabled = meta['api'] == true;
              final uri = (meta['uri'] as String?)?.trim() ?? '';
              if (type == 'https' && apiEnabled && uri.startsWith('https://')) {
                final clean = uri.endsWith('/')
                    ? uri.substring(0, uri.length - 1)
                    : uri;
                if (!discovered.contains(clean)) {
                  discovered.add(clean);
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    for (final fallback in _fallbackInvidiousNodes) {
      if (!discovered.contains(fallback)) {
        discovered.add(fallback);
      }
    }

    _cachedInvidiousNodes = discovered;
    return discovered;
  }

  Future<_StreamBundleResult> _fetchStreams(String videoId) async {
    // 1. If user configured a custom endpoint, try it first (supports Cobalt & Invidious)
    if (_customEndpoint.isNotEmpty) {
      final customInvidious =
          await _tryFetchFromInvidiousNode(_customEndpoint, videoId);
      if (customInvidious != null) return customInvidious;

      final customCobalt =
          await _tryFetchFromCobaltNode(_customEndpoint, videoId);
      if (customCobalt != null) return customCobalt;
    }

    // 2. Query discovered + fallback Invidious API nodes
    final nodes = await _resolveInvidiousNodes();
    for (final node in nodes.take(4)) {
      final result = await _tryFetchFromInvidiousNode(node, videoId);
      if (result != null && result.hasAnyStreams) {
        return result;
      }
    }

    return const _StreamBundleResult(
      warningMessage:
          'Public media stream nodes are temporarily busy. Thumbnails, preview player, and metadata tools remain ready, or connect a custom API node in Engine Settings.',
    );
  }

  Future<_StreamBundleResult?> _tryFetchFromInvidiousNode(
    String baseUrl,
    String videoId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/videos/$videoId?local=true');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 9));
      if (response.statusCode != 200) return null;

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final title = (map['title'] as String?)?.trim() ?? '';
      final author = (map['author'] as String?)?.trim() ?? '';
      final authorUrl = (map['authorUrl'] as String?)?.trim() ?? '';
      final description = (map['description'] as String?)?.trim() ?? '';
      final publishedText = (map['publishedText'] as String?)?.trim() ?? '';
      final lengthSeconds = (map['lengthSeconds'] as num?)?.toInt() ?? 0;
      final viewCount = (map['viewCount'] as num?)?.toInt();
      final likeCount = (map['likeCount'] as num?)?.toInt();

      final videoMap = <String, YtStreamOption>{};
      final audioMap = <String, YtStreamOption>{};

      // Parse progressive combined streams if present
      final formatStreams = map['formatStreams'];
      if (formatStreams is List) {
        for (final raw in formatStreams) {
          if (raw is! Map<String, dynamic>) continue;
          final option = _parseInvidiousStream(
            raw,
            baseUrl: baseUrl,
            videoId: videoId,
            isCombined: true,
          );
          if (option != null) {
            final key = 'combined_${option.qualityLabel}_${option.container}';
            videoMap[key] = option;
          }
        }
      }

      // Parse adaptive HD video & HQ audio streams
      final adaptiveFormats = map['adaptiveFormats'];
      if (adaptiveFormats is List) {
        for (final raw in adaptiveFormats) {
          if (raw is! Map<String, dynamic>) continue;
          final option = _parseInvidiousStream(
            raw,
            baseUrl: baseUrl,
            videoId: videoId,
            isCombined: false,
          );
          if (option == null) continue;

          if (option.isAudioOnly) {
            final existing = audioMap[option.itag];
            if (existing == null ||
                (option.contentLengthBytes ?? 0) >
                    (existing.contentLengthBytes ?? 0)) {
              audioMap[option.itag] = option;
            }
          } else {
            final key = '${option.qualityLabel}_${option.fileExtension}';
            final existing = videoMap[key];
            if (existing == null || _preferVideoCodec(option, existing)) {
              videoMap[key] = option;
            }
          }
        }
      }

      final videoList = videoMap.values.toList()
        ..sort((a, b) {
          if (a.isCombined != b.isCombined) {
            return a.isCombined ? -1 : 1;
          }
          final resCmp = b.resolutionHeight.compareTo(a.resolutionHeight);
          if (resCmp != 0) return resCmp;
          final fpsCmp = b.fps.compareTo(a.fps);
          if (fpsCmp != 0) return fpsCmp;
          if (a.fileExtension != b.fileExtension) {
            return a.fileExtension == 'mp4' ? -1 : 1;
          }
          return b.bitrate.compareTo(a.bitrate);
        });

      final audioList = audioMap.values.toList()
        ..sort((a, b) {
          // Prefer M4A 128kbps first for broad device compatibility, then highest bitrate
          final aIsM4a = a.fileExtension == 'm4a' && a.bitrate >= 100000;
          final bIsM4a = b.fileExtension == 'm4a' && b.bitrate >= 100000;
          if (aIsM4a != bIsM4a) return aIsM4a ? -1 : 1;
          return b.bitrate.compareTo(a.bitrate);
        });

      final captions = <YtCaptionOption>[];
      final rawCaptions = map['captions'];
      if (rawCaptions is List) {
        for (final c in rawCaptions) {
          if (c is! Map<String, dynamic>) continue;
          final label = (c['label'] as String?)?.trim() ?? '';
          final lang =
              (c['language_code'] as String? ?? c['languageCode'] as String?)
                      ?.trim() ??
                  'en';
          final relUrl = (c['url'] as String?)?.trim() ?? '';
          if (label.isNotEmpty && relUrl.isNotEmpty) {
            final dlUrl =
                relUrl.startsWith('http') ? relUrl : '$baseUrl$relUrl';
            captions.add(
              YtCaptionOption(
                label: label,
                languageCode: lang,
                downloadUrl: dlUrl,
              ),
            );
          }
        }
      }

      final hostLabel = Uri.tryParse(baseUrl)?.host ?? baseUrl;
      return _StreamBundleResult(
        title: title,
        author: author,
        authorUrl:
            authorUrl.startsWith('/') ? 'https://www.youtube.com$authorUrl' : authorUrl,
        description: description,
        publishedText: publishedText,
        lengthSeconds: lengthSeconds,
        viewCount: viewCount,
        likeCount: likeCount,
        videoStreams: videoList,
        audioStreams: audioList,
        captions: captions,
        providerHost: hostLabel,
      );
    } catch (_) {
      return null;
    }
  }

  YtStreamOption? _parseInvidiousStream(
    Map<String, dynamic> raw, {
    required String baseUrl,
    required String videoId,
    required bool isCombined,
  }) {
    final itag = raw['itag']?.toString() ?? '';
    if (itag.isEmpty) return null;

    final mimeRaw = (raw['type'] as String?)?.trim() ?? '';
    final isAudio = mimeRaw.startsWith('audio/');
    final codecsMatch = RegExp(r'codecs="([^"]+)"').firstMatch(mimeRaw);
    final codecs = codecsMatch?.group(1) ?? (raw['encoding'] as String? ?? '');

    var container = (raw['container'] as String?)?.trim().toLowerCase() ?? '';
    if (container.isEmpty) {
      if (mimeRaw.contains('webm')) {
        container = 'webm';
      } else if (isAudio) {
        container = 'm4a';
      } else {
        container = 'mp4';
      }
    }

    final bitrate = int.tryParse(raw['bitrate']?.toString() ?? '') ?? 0;
    final clen = int.tryParse(raw['clen']?.toString() ?? '');
    final fps = (raw['fps'] as num?)?.toInt() ?? 30;

    var qualityLabel = (raw['qualityLabel'] as String?)?.trim() ?? '';
    var resolutionHeight = 0;

    if (isAudio) {
      final kbps = bitrate > 0 ? (bitrate / 1000).round() : 128;
      qualityLabel = '$kbps kbps';
    } else {
      final heightMatch = RegExp(r'(\d{3,4})p').firstMatch(qualityLabel);
      if (heightMatch != null) {
        resolutionHeight = int.tryParse(heightMatch.group(1)!) ?? 0;
      }
      if (qualityLabel.isEmpty) {
        final resStr = (raw['resolution'] as String?)?.trim() ?? '';
        qualityLabel = resStr.isNotEmpty ? resStr : 'Video';
      }
    }

    // Route directly to the CORS-enabled Invidious Companion / ytproxy-go host
    // when available so browsers avoid un-CORSed 302 hops and support Range streaming.
    final proxyDownloadUrl = _resolveDirectStreamUrl(
      raw,
      baseUrl: baseUrl,
      videoId: videoId,
      itag: itag,
    );

    return YtStreamOption(
      itag: itag,
      qualityLabel: qualityLabel,
      container: container,
      codecs: codecs,
      mimeType: mimeRaw.split(';').first.trim(),
      downloadUrl: proxyDownloadUrl,
      isAudioOnly: isAudio,
      isCombined: isCombined,
      resolutionHeight: resolutionHeight,
      fps: fps,
      bitrate: bitrate,
      contentLengthBytes: clen,
    );
  }

  String _resolveDirectStreamUrl(
    Map<String, dynamic> raw, {
    required String baseUrl,
    required String videoId,
    required String itag,
  }) {
    final rawUrl = (raw['url'] as String?)?.trim() ?? '';
    final rawUri = Uri.tryParse(rawUrl);
    final issuer = rawUri?.queryParameters['issuer']?.trim() ?? '';

    if (rawUri != null && rawUri.path.contains('/videoplayback')) {
      if (issuer.isNotEmpty) {
        return rawUri.replace(scheme: 'https', host: issuer).toString();
      }
      if (rawUrl.startsWith(baseUrl)) {
        return rawUrl;
      }
    }

    if (issuer.isNotEmpty) {
      return 'https://$issuer/companion/latest_version?id=$videoId&itag=$itag&local=true';
    }
    return '$baseUrl/latest_version?id=$videoId&itag=$itag&local=true';
  }

  bool _preferVideoCodec(YtStreamOption candidate, YtStreamOption current) {
    // Prefer H.264 (avc1) over AV1 (av01) for universal MP4 playback & remuxing
    final candH264 = candidate.codecs.contains('avc1');
    final currH264 = current.codecs.contains('avc1');
    if (candH264 != currH264) return candH264;
    return candidate.bitrate > current.bitrate;
  }

  Future<_StreamBundleResult?> _tryFetchFromCobaltNode(
    String baseUrl,
    String videoId,
  ) async {
    try {
      final watchUrl = 'https://www.youtube.com/watch?v=$videoId';
      final videoResp = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'url': watchUrl,
              'videoQuality': '1080',
              'downloadMode': 'auto',
            }),
          )
          .timeout(const Duration(seconds: 9));

      if (videoResp.statusCode != 200) return null;
      final vMap = jsonDecode(videoResp.body) as Map<String, dynamic>;
      final vUrl = (vMap['url'] as String?)?.trim() ?? '';
      if (vUrl.isEmpty) return null;

      final videos = <YtStreamOption>[
        YtStreamOption(
          itag: 'cobalt_1080',
          qualityLabel: '1080p HD',
          container: 'mp4',
          codecs: 'avc1 + mp4a',
          mimeType: 'video/mp4',
          downloadUrl: vUrl,
          isAudioOnly: false,
          isCombined: true,
          resolutionHeight: 1080,
        ),
      ];

      final audios = <YtStreamOption>[];
      try {
        final audioResp = await _client
            .post(
              Uri.parse(baseUrl),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'url': watchUrl,
                'downloadMode': 'audio',
                'audioFormat': 'mp3',
              }),
            )
            .timeout(const Duration(seconds: 7));
        if (audioResp.statusCode == 200) {
          final aMap = jsonDecode(audioResp.body) as Map<String, dynamic>;
          final aUrl = (aMap['url'] as String?)?.trim() ?? '';
          if (aUrl.isNotEmpty) {
            audios.add(
              YtStreamOption(
                itag: 'cobalt_mp3',
                qualityLabel: '320 kbps',
                container: 'mp3',
                codecs: 'mp3',
                mimeType: 'audio/mpeg',
                downloadUrl: aUrl,
                isAudioOnly: true,
                isCombined: false,
                bitrate: 320000,
              ),
            );
          }
        }
      } catch (_) {}

      return _StreamBundleResult(
        videoStreams: videos,
        audioStreams: audios,
        providerHost: Uri.tryParse(baseUrl)?.host ?? baseUrl,
      );
    } catch (_) {
      return null;
    }
  }
}

class _OEmbedResult {
  const _OEmbedResult({
    required this.title,
    required this.authorName,
    required this.authorUrl,
  });

  final String title;
  final String authorName;
  final String authorUrl;
}

class _VotesResult {
  const _VotesResult({
    this.viewCount,
    this.likes,
    this.dislikes,
    this.rating,
  });

  final int? viewCount;
  final int? likes;
  final int? dislikes;
  final double? rating;
}

class _StreamBundleResult {
  const _StreamBundleResult({
    this.title = '',
    this.author = '',
    this.authorUrl = '',
    this.description = '',
    this.publishedText = '',
    this.lengthSeconds = 0,
    this.viewCount,
    this.likeCount,
    this.videoStreams = const [],
    this.audioStreams = const [],
    this.captions = const [],
    this.providerHost = '',
    this.warningMessage,
  });

  final String title;
  final String author;
  final String authorUrl;
  final String description;
  final String publishedText;
  final int lengthSeconds;
  final int? viewCount;
  final int? likeCount;
  final List<YtStreamOption> videoStreams;
  final List<YtStreamOption> audioStreams;
  final List<YtCaptionOption> captions;
  final String providerHost;
  final String? warningMessage;

  bool get hasAnyStreams =>
      videoStreams.isNotEmpty || audioStreams.isNotEmpty;
}

