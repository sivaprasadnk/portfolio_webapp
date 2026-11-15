import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;

import '../../domain/models/yt_models.dart';

class YtCancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}

class YtDownloadCancelledException implements Exception {
  const YtDownloadCancelledException();

  @override
  String toString() => 'Download cancelled';
}

class YtExtractorService {
  YtExtractorService({
    http.Client? httpClient,
    yte.YoutubeExplode? youtubeExplode,
  })  : _http = httpClient ?? http.Client(),
        _yt = youtubeExplode ?? yte.YoutubeExplode();

  final http.Client _http;
  final yte.YoutubeExplode _yt;

  static const int _rangeChunkSize = 4 * 1024 * 1024; // 4 MB chunks

  static const List<String> _fallbackInvidiousNodes = [
    'https://yt.chocolatemoo53.com',
    'https://inv.nadeko.net',
    'https://yewtu.be',
    'https://invidious.nerdvpn.de',
  ];

  List<String>? _cachedDiscoveredNodes;

  Future<YtVideoInfo> extractVideo(
    ParsedYoutubeTarget target, {
    String customEndpoint = '',
  }) async {
    final trimmedCustom = customEndpoint.trim();
    final votesFuture = _fetchVotes(target.videoId);

    // 1. Honor explicit user-configured custom Invidious / Cobalt endpoint first
    if (trimmedCustom.isNotEmpty) {
      final customResult = await _tryCustomNode(trimmedCustom, target);
      if (customResult != null) {
        final votes = await votesFuture;
        return _mergeVotes(customResult, votes);
      }
    }

    // 2. Engine 1: Native On-Device YoutubeExplode (Direct YouTube InnerTube API)
    try {
      final nativeInfo = await _extractWithYoutubeExplode(target);
      final votes = await votesFuture;
      return _mergeVotes(nativeInfo, votes);
    } catch (_) {
      // Fall through seamlessly to Engine 2 (Invidious + Companion Direct Nodes)
    }

    // 3. Engine 2: Invidious + Companion /videoplayback + oEmbed fallback
    final oembedFuture = _fetchOEmbed(target.videoId);
    final nodes = await _getCandidateInvidiousNodes();
    for (final node in nodes) {
      final info = await _tryInvidiousNode(node, target);
      if (info != null && info.hasMediaStreams) {
        final votes = await votesFuture;
        return _mergeVotes(info, votes);
      }
    }

    final oembed = await oembedFuture;
    final votes = await votesFuture;
    if (oembed != null) {
      return YtVideoInfo(
        videoId: target.videoId,
        title: (oembed['title'] as String?)?.trim().isNotEmpty == true
            ? (oembed['title'] as String).trim()
            : 'YouTube Video (${target.videoId})',
        author: (oembed['author_name'] as String?)?.trim() ?? 'YouTube Creator',
        authorUrl: (oembed['author_url'] as String?)?.trim() ?? '',
        urlKind: target.kind,
        viewCount: votes?['viewCount'] as int?,
        likeCount: votes?['likes'] as int?,
        dislikeCount: votes?['dislikes'] as int?,
        rating: (votes?['rating'] as num?)?.toDouble(),
        thumbnails: YtThumbnailOption.buildForVideo(target.videoId),
        activeProviderNode: 'YouTube oEmbed Metadata',
        streamWarning:
            'Direct video/audio streams were restricted for this clip, '
            'but HD thumbnails and metadata are ready to save.',
      );
    }

    throw Exception(
      'Unable to extract media streams for ${target.videoId}. '
      'Check your internet connection or verify the video is public.',
    );
  }

  Future<YtVideoInfo> _extractWithYoutubeExplode(
    ParsedYoutubeTarget target,
  ) async {
    final videoFuture = _yt.videos.get(target.videoId);
    final manifestFuture = _yt.videos.streamsClient.getManifest(target.videoId);
    final captionsFuture = _yt.videos.closedCaptions
        .getManifest(
          target.videoId,
          formats: const [yte.ClosedCaptionFormat.vtt],
        )
        .then<yte.ClosedCaptionManifest?>((m) => m)
        .catchError((_) => null);

    final video = await videoFuture.timeout(const Duration(seconds: 15));
    final manifest = await manifestFuture.timeout(const Duration(seconds: 18));
    final captionManifest = await captionsFuture.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );

    final videoStreams = <YtStreamOption>[];
    final seenVideoKeys = <String>{};

    for (final s in manifest.muxed) {
      final height = s.videoResolution.height;
      final fps = s.framerate.framesPerSecond.round();
      final label = s.qualityLabel.trim().isNotEmpty
          ? s.qualityLabel.trim()
          : '${height}p';
      final key = 'muxed_${s.tag}_${s.container.name}_$label';
      if (!seenVideoKeys.add(key)) continue;

      videoStreams.add(
        YtStreamOption(
          itag: '${s.tag}',
          qualityLabel: label,
          container: s.container.name,
          codecs:
              s.codec.parameters['codecs'] ?? '${s.videoCodec}, ${s.audioCodec}',
          mimeType: s.codec.mimeType,
          downloadUrl: s.url.toString(),
          isAudioOnly: false,
          isCombined: true,
          resolutionHeight: height,
          fps: fps > 0 ? fps : 30,
          bitrate: s.bitrate.bitsPerSecond,
          contentLengthBytes: s.size.totalBytes > 0 ? s.size.totalBytes : null,
          nativeStreamInfo: s,
        ),
      );
    }

    for (final s in manifest.videoOnly) {
      final height = s.videoResolution.height;
      if (height <= 0) continue;
      final fps = s.framerate.framesPerSecond.round();
      final label = s.qualityLabel.trim().isNotEmpty
          ? s.qualityLabel.trim()
          : '${height}p';
      final codecShort = s.videoCodec.split('.').first;
      final key = 'vo_${height}_${fps}_${s.container.name}_$codecShort';
      if (!seenVideoKeys.add(key)) continue;

      videoStreams.add(
        YtStreamOption(
          itag: '${s.tag}',
          qualityLabel: label,
          container: s.container.name,
          codecs: s.codec.parameters['codecs'] ?? s.videoCodec,
          mimeType: s.codec.mimeType,
          downloadUrl: s.url.toString(),
          isAudioOnly: false,
          isCombined: false,
          resolutionHeight: height,
          fps: fps > 0 ? fps : 30,
          bitrate: s.bitrate.bitsPerSecond,
          contentLengthBytes: s.size.totalBytes > 0 ? s.size.totalBytes : null,
          nativeStreamInfo: s,
        ),
      );
    }

    videoStreams.sort(_compareVideoStreams);

    final audioStreams = <YtStreamOption>[];
    final seenAudioTags = <int>{};
    for (final s in manifest.audioOnly) {
      if (!seenAudioTags.add(s.tag)) continue;
      final bps = s.bitrate.bitsPerSecond;
      final kbps = (bps / 1000).round();
      final container = s.container.name == 'mp4' ? 'm4a' : s.container.name;

      audioStreams.add(
        YtStreamOption(
          itag: '${s.tag}',
          qualityLabel: kbps > 0 ? '$kbps kbps' : 'Audio Track',
          container: container,
          codecs: s.codec.parameters['codecs'] ?? s.audioCodec,
          mimeType: s.codec.mimeType,
          downloadUrl: s.url.toString(),
          isAudioOnly: true,
          isCombined: false,
          bitrate: bps,
          contentLengthBytes: s.size.totalBytes > 0 ? s.size.totalBytes : null,
          nativeStreamInfo: s,
        ),
      );
    }

    audioStreams.sort(_compareAudioStreams);

    final captions = <YtCaptionOption>[];
    if (captionManifest != null) {
      final seenLangs = <String>{};
      for (final track in captionManifest.tracks) {
        final key = '${track.language.code}_${track.isAutoGenerated}';
        if (!seenLangs.add(key)) continue;
        captions.add(
          YtCaptionOption(
            label: track.isAutoGenerated
                ? '${track.language.name} (Auto)'
                : track.language.name,
            languageCode: track.language.code,
            downloadUrl: track.url.toString(),
            nativeTrackInfo: track,
          ),
        );
      }
    }

    final publishDate = video.publishDate ?? video.uploadDate;
    final publishedText = (video.uploadDateRaw?.trim().isNotEmpty ?? false)
        ? video.uploadDateRaw!.trim()
        : (publishDate != null
            ? '${publishDate.year}-'
                '${publishDate.month.toString().padLeft(2, '0')}-'
                '${publishDate.day.toString().padLeft(2, '0')}'
            : '');

    final resolvedKind =
        video.isLive && target.kind == YtUrlKind.watch ? YtUrlKind.live : target.kind;

    return YtVideoInfo(
      videoId: target.videoId,
      title: video.title,
      author: video.author,
      authorUrl: 'https://www.youtube.com/channel/${video.channelId.value}',
      urlKind: resolvedKind,
      description: video.description,
      publishedText: publishedText,
      lengthSeconds: video.duration?.inSeconds ?? 0,
      viewCount: video.engagement.viewCount,
      likeCount: video.engagement.likeCount,
      dislikeCount: video.engagement.dislikeCount,
      rating: video.engagement.avgRating >= 0
          ? video.engagement.avgRating.toDouble()
          : null,
      videoStreams: videoStreams,
      audioStreams: audioStreams,
      captions: captions,
      thumbnails: YtThumbnailOption.buildForVideo(target.videoId),
      activeProviderNode: 'On-Device YouTube Engine',
    );
  }

  Future<void> downloadStreamToFile(
    YtStreamOption stream,
    String destPath, {
    required YtCancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    if (cancelToken.isCancelled) {
      throw const YtDownloadCancelledException();
    }

    final file = File(destPath);
    await file.parent.create(recursive: true);

    if (stream.nativeStreamInfo != null) {
      try {
        await _pipeYoutubeExplodeStream(
          stream.nativeStreamInfo!,
          file,
          expectedBytes: stream.contentLengthBytes,
          cancelToken: cancelToken,
          onProgress: onProgress,
        );
        return;
      } on YtDownloadCancelledException {
        await _safeDelete(file);
        rethrow;
      } catch (_) {
        await _safeDelete(file);
        if (stream.downloadUrl.isEmpty) rethrow;
      }
    }

    await downloadUrlToFile(
      stream.downloadUrl,
      destPath,
      expectedBytes: stream.contentLengthBytes,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
  }

  Future<void> _pipeYoutubeExplodeStream(
    yte.StreamInfo streamInfo,
    File destFile, {
    required int? expectedBytes,
    required YtCancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    final sink = destFile.openWrite();
    final completer = Completer<void>();
    var received = 0;
    StreamSubscription<List<int>>? sub;

    void abortOnCancel() {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.completeError(const YtDownloadCancelledException());
      }
    }

    cancelToken.addListener(abortOnCancel);

    try {
      final byteStream = _yt.videos.streamsClient.get(streamInfo);
      sub = byteStream.listen(
        (chunk) {
          if (cancelToken.isCancelled) {
            abortOnCancel();
            return;
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, expectedBytes);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object error, StackTrace st) {
          if (!completer.isCompleted) completer.completeError(error, st);
        },
        cancelOnError: true,
      );

      await completer.future;
      await sink.flush();
    } finally {
      await sub?.cancel();
      await sink.close();
    }
  }

  Future<void> downloadUrlToFile(
    String url,
    String destPath, {
    int? expectedBytes,
    required YtCancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    if (cancelToken.isCancelled) {
      throw const YtDownloadCancelledException();
    }

    final file = File(destPath);
    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    final downloadClient = http.Client();
    cancelToken.addListener(downloadClient.close);

    try {
      if (expectedBytes != null && expectedBytes > 0) {
        var offset = 0;
        while (offset < expectedBytes) {
          if (cancelToken.isCancelled) {
            throw const YtDownloadCancelledException();
          }
          final end = (offset + _rangeChunkSize - 1 < expectedBytes)
              ? offset + _rangeChunkSize - 1
              : expectedBytes - 1;

          final req = http.Request('GET', Uri.parse(url));
          req.headers['Range'] = 'bytes=$offset-$end';
          final res = await downloadClient.send(req);

          if (res.statusCode != 200 && res.statusCode != 206) {
            throw Exception('Stream returned HTTP ${res.statusCode}');
          }

          final fullBody = res.statusCode == 200 && offset == 0;
          await for (final chunk in res.stream) {
            if (cancelToken.isCancelled) {
              throw const YtDownloadCancelledException();
            }
            sink.add(chunk);
            offset += chunk.length;
            onProgress?.call(offset, expectedBytes);
          }

          if (fullBody) break;
        }
      } else {
        final req = http.Request('GET', Uri.parse(url));
        final res = await downloadClient.send(req);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('Download failed (HTTP ${res.statusCode})');
        }
        final total = res.contentLength;
        var received = 0;
        await for (final chunk in res.stream) {
          if (cancelToken.isCancelled) {
            throw const YtDownloadCancelledException();
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
      }
      await sink.flush();
    } catch (e) {
      await sink.close();
      await _safeDelete(file);
      if (cancelToken.isCancelled || e is YtDownloadCancelledException) {
        throw const YtDownloadCancelledException();
      }
      rethrow;
    } finally {
      await sink.close();
      downloadClient.close();
    }
  }

  Future<void> downloadThumbnailToFile(
    YtThumbnailOption option,
    String videoId,
    String destPath, {
    required YtCancelToken cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    final candidates = <String>{
      option.url,
      'https://i.ytimg.com/vi/$videoId/sddefault.jpg',
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      'https://i.ytimg.com/vi/$videoId/mqdefault.jpg',
    };

    for (final candidateUrl in candidates) {
      if (cancelToken.isCancelled) {
        throw const YtDownloadCancelledException();
      }
      try {
        final res = await _http
            .get(Uri.parse(candidateUrl))
            .timeout(const Duration(seconds: 12));
        if (cancelToken.isCancelled) {
          throw const YtDownloadCancelledException();
        }
        if (res.statusCode == 200 && res.bodyBytes.length > 1200) {
          final file = File(destPath);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(res.bodyBytes, flush: true);
          onProgress?.call(res.bodyBytes.length, res.bodyBytes.length);
          return;
        }
      } on YtDownloadCancelledException {
        rethrow;
      } catch (_) {
        // Try next resolution candidate
      }
    }

    throw Exception('Could not fetch thumbnail image for $videoId.');
  }

  Future<void> downloadCaptionToFile(
    YtCaptionOption caption,
    String destPath,
  ) async {
    String content = '';
    if (caption.nativeTrackInfo != null) {
      try {
        content =
            await _yt.videos.closedCaptions.getSubTitles(caption.nativeTrackInfo!);
      } catch (_) {
        content = '';
      }
    }

    if (content.trim().isEmpty && caption.downloadUrl.isNotEmpty) {
      final res = await _http
          .get(Uri.parse(caption.downloadUrl))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        content = utf8.decode(res.bodyBytes, allowMalformed: true);
      }
    }

    if (content.trim().isEmpty) {
      throw Exception('Subtitle track was empty or unavailable.');
    }

    final file = File(destPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  Future<YtVideoInfo?> _tryCustomNode(
    String rawEndpoint,
    ParsedYoutubeTarget target,
  ) async {
    final cleanBase = rawEndpoint.endsWith('/')
        ? rawEndpoint.substring(0, rawEndpoint.length - 1)
        : rawEndpoint;

    // Try as Invidious API first
    final invResult = await _tryInvidiousNode(cleanBase, target);
    if (invResult != null) return invResult;

    // Try as Cobalt v7/v10 style POST JSON API
    try {
      final res = await _http
          .post(
            Uri.parse(cleanBase),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'url': target.canonicalWatchUrl}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final directUrl = (data['url'] as String?) ?? '';
        if (directUrl.isNotEmpty) {
          final oembed = await _fetchOEmbed(target.videoId);
          return YtVideoInfo(
            videoId: target.videoId,
            title: (data['filename'] as String?) ??
                (oembed?['title'] as String?) ??
                'YouTube Video (${target.videoId})',
            author: (oembed?['author_name'] as String?) ?? 'YouTube Creator',
            urlKind: target.kind,
            videoStreams: [
              YtStreamOption(
                itag: 'cobalt',
                qualityLabel: 'HD MP4',
                container: 'mp4',
                codecs: 'avc1, mp4a',
                mimeType: 'video/mp4',
                downloadUrl: directUrl,
                isAudioOnly: false,
                isCombined: true,
                resolutionHeight: 1080,
              ),
            ],
            thumbnails: YtThumbnailOption.buildForVideo(target.videoId),
            activeProviderNode: Uri.parse(cleanBase).host,
          );
        }
      }
    } catch (_) {
      // Ignore custom Cobalt parse errors
    }
    return null;
  }

  Future<List<String>> _getCandidateInvidiousNodes() async {
    if (_cachedDiscoveredNodes != null) return _cachedDiscoveredNodes!;
    final result = <String>[..._fallbackInvidiousNodes];
    try {
      final res = await _http
          .get(Uri.parse('https://api.invidious.io/instances.json?sort_by=health'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as List<dynamic>;
        for (final entry in decoded) {
          if (entry is List && entry.length >= 2 && entry[1] is Map) {
            final meta = entry[1] as Map<String, dynamic>;
            final type = meta['type'] as String?;
            final api = meta['api'] == true;
            final uri = meta['uri'] as String?;
            if (type == 'https' && api && uri != null && uri.isNotEmpty) {
              final clean = uri.endsWith('/')
                  ? uri.substring(0, uri.length - 1)
                  : uri;
              if (!result.contains(clean)) {
                result.add(clean);
              }
            }
          }
        }
      }
    } catch (_) {
      // Fall back to static list
    }
    _cachedDiscoveredNodes = result.take(6).toList();
    return _cachedDiscoveredNodes!;
  }

  Future<YtVideoInfo?> _tryInvidiousNode(
    String baseUrl,
    ParsedYoutubeTarget target,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/videos/${target.videoId}?local=true',
      );
      final res = await _http.get(uri).timeout(const Duration(seconds: 9));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final title = (data['title'] as String?)?.trim();
      if (title == null || title.isEmpty) return null;

      final videoStreams = <YtStreamOption>[];
      final audioStreams = <YtStreamOption>[];

      final formatStreams = data['formatStreams'] as List<dynamic>? ?? const [];
      for (final raw in formatStreams) {
        if (raw is! Map<String, dynamic>) continue;
        final url = _resolveDirectStreamUrl(baseUrl, raw);
        if (url.isEmpty) continue;
        final type = (raw['type'] as String?) ?? 'video/mp4';
        final container = (raw['container'] as String?) ??
            (type.contains('webm') ? 'webm' : 'mp4');
        final qualityLabel =
            (raw['qualityLabel'] as String?) ?? (raw['quality'] as String?) ?? '360p';
        final height = _parseHeight(qualityLabel, raw['resolution'] as String?);
        final clen = _parseContentLength(raw['clen'], url);

        videoStreams.add(
          YtStreamOption(
            itag: '${raw['itag'] ?? '18'}',
            qualityLabel: qualityLabel,
            container: container,
            codecs: (raw['encoding'] as String?) ?? type,
            mimeType: type.split(';').first,
            downloadUrl: url,
            isAudioOnly: false,
            isCombined: true,
            resolutionHeight: height,
            fps: (raw['fps'] as num?)?.toInt() ?? 30,
            bitrate: _parseInt(raw['bitrate']),
            contentLengthBytes: clen,
          ),
        );
      }

      final adaptive = data['adaptiveFormats'] as List<dynamic>? ?? const [];
      for (final raw in adaptive) {
        if (raw is! Map<String, dynamic>) continue;
        final url = _resolveDirectStreamUrl(baseUrl, raw);
        if (url.isEmpty) continue;
        final type = (raw['type'] as String?) ?? '';
        final isAudio = type.startsWith('audio/');
        final container = (raw['container'] as String?) ??
            (type.contains('webm')
                ? 'webm'
                : (isAudio ? 'm4a' : 'mp4'));
        final bitrate = _parseInt(raw['bitrate']);
        final clen = _parseContentLength(raw['clen'], url);

        if (isAudio) {
          final kbps = bitrate > 0 ? '${(bitrate / 1000).round()} kbps' : 'Audio';
          audioStreams.add(
            YtStreamOption(
              itag: '${raw['itag'] ?? '140'}',
              qualityLabel: kbps,
              container: container == 'mp4' ? 'm4a' : container,
              codecs: (raw['encoding'] as String?) ?? type,
              mimeType: type.split(';').first,
              downloadUrl: url,
              isAudioOnly: true,
              isCombined: false,
              bitrate: bitrate,
              contentLengthBytes: clen,
            ),
          );
        } else {
          final qualityLabel = (raw['qualityLabel'] as String?) ?? 'HD';
          final height =
              _parseHeight(qualityLabel, raw['resolution'] as String?);
          videoStreams.add(
            YtStreamOption(
              itag: '${raw['itag'] ?? '137'}',
              qualityLabel: qualityLabel,
              container: container,
              codecs: (raw['encoding'] as String?) ?? type,
              mimeType: type.split(';').first,
              downloadUrl: url,
              isAudioOnly: false,
              isCombined: false,
              resolutionHeight: height,
              fps: (raw['fps'] as num?)?.toInt() ?? 30,
              bitrate: bitrate,
              contentLengthBytes: clen,
            ),
          );
        }
      }

      videoStreams.sort(_compareVideoStreams);
      audioStreams.sort(_compareAudioStreams);

      final captions = <YtCaptionOption>[];
      final rawCaptions = data['captions'] as List<dynamic>? ?? const [];
      for (final c in rawCaptions) {
        if (c is! Map<String, dynamic>) continue;
        final relUrl = (c['url'] as String?) ?? '';
        if (relUrl.isEmpty) continue;
        final fullUrl = relUrl.startsWith('http') ? relUrl : '$baseUrl$relUrl';
        captions.add(
          YtCaptionOption(
            label: (c['label'] as String?) ?? 'Subtitles',
            languageCode: (c['language_code'] as String?) ?? 'en',
            downloadUrl: fullUrl,
          ),
        );
      }

      return YtVideoInfo(
        videoId: target.videoId,
        title: title,
        author: (data['author'] as String?) ?? 'YouTube Creator',
        authorUrl: (data['authorUrl'] as String?) != null
            ? 'https://www.youtube.com${data['authorUrl']}'
            : '',
        urlKind: target.kind,
        description: (data['description'] as String?) ?? '',
        publishedText: (data['publishedText'] as String?) ?? '',
        lengthSeconds: (data['lengthSeconds'] as num?)?.toInt() ?? 0,
        viewCount: (data['viewCount'] as num?)?.toInt(),
        likeCount: (data['likeCount'] as num?)?.toInt(),
        videoStreams: videoStreams,
        audioStreams: audioStreams,
        captions: captions,
        thumbnails: YtThumbnailOption.buildForVideo(target.videoId),
        activeProviderNode: Uri.parse(baseUrl).host,
      );
    } catch (_) {
      return null;
    }
  }

  String _resolveDirectStreamUrl(String baseUrl, Map<String, dynamic> raw) {
    final rawUrl = (raw['url'] as String?)?.trim() ?? '';
    if (rawUrl.isEmpty) return '';

    final fullUrl = rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
        ? rawUrl
        : '$baseUrl${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';

    final parsed = Uri.tryParse(fullUrl);
    if (parsed == null) return fullUrl;

    // Rewrite companion issuer redirect directly to /videoplayback to avoid 302 hops
    final issuer = parsed.queryParameters['issuer'];
    if (issuer != null &&
        issuer.isNotEmpty &&
        parsed.path.contains('videoplayback')) {
      final cleanParams = Map<String, String>.from(parsed.queryParameters)
        ..remove('issuer');
      return Uri(
        scheme: 'https',
        host: issuer,
        path: '/videoplayback',
        queryParameters: cleanParams,
      ).toString();
    }

    if (parsed.host.endsWith('googlevideo.com')) {
      final itag = '${raw['itag'] ?? parsed.queryParameters['itag'] ?? ''}';
      final id = parsed.queryParameters['id'];
      if (itag.isNotEmpty && id != null) {
        return '$baseUrl/latest_version?id=$id&itag=$itag&local=true';
      }
    }

    return fullUrl;
  }

  Future<Map<String, dynamic>?> _fetchVotes(String videoId) async {
    try {
      final res = await _http
          .get(
            Uri.parse(
              'https://returnyoutubedislikeapi.com/votes?videoId=$videoId',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchOEmbed(String videoId) async {
    final watchUrl =
        Uri.encodeComponent('https://www.youtube.com/watch?v=$videoId');
    final endpoints = [
      'https://www.youtube.com/oembed?url=$watchUrl&format=json',
      'https://noembed.com/embed?url=$watchUrl',
    ];
    for (final ep in endpoints) {
      try {
        final res =
            await _http.get(Uri.parse(ep)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }

  YtVideoInfo _mergeVotes(YtVideoInfo info, Map<String, dynamic>? votes) {
    if (votes == null) return info;
    return YtVideoInfo(
      videoId: info.videoId,
      title: info.title,
      author: info.author,
      authorUrl: info.authorUrl,
      urlKind: info.urlKind,
      description: info.description,
      publishedText: info.publishedText,
      lengthSeconds: info.lengthSeconds,
      viewCount: info.viewCount ?? (votes['viewCount'] as num?)?.toInt(),
      likeCount: info.likeCount ?? (votes['likes'] as num?)?.toInt(),
      dislikeCount: info.dislikeCount ?? (votes['dislikes'] as num?)?.toInt(),
      rating: info.rating ?? (votes['rating'] as num?)?.toDouble(),
      videoStreams: info.videoStreams,
      audioStreams: info.audioStreams,
      captions: info.captions,
      thumbnails: info.thumbnails,
      activeProviderNode: info.activeProviderNode,
      streamWarning: info.streamWarning,
    );
  }

  static int _compareVideoStreams(YtStreamOption a, YtStreamOption b) {
    if (a.isCombined != b.isCombined) {
      return a.isCombined ? -1 : 1;
    }
    final resCmp = b.resolutionHeight.compareTo(a.resolutionHeight);
    if (resCmp != 0) return resCmp;
    final fpsCmp = b.fps.compareTo(a.fps);
    if (fpsCmp != 0) return fpsCmp;
    final aMp4 = a.container == 'mp4';
    final bMp4 = b.container == 'mp4';
    if (aMp4 != bMp4) return aMp4 ? -1 : 1;
    final aH264 = a.codecShortLabel == 'H.264';
    final bH264 = b.codecShortLabel == 'H.264';
    if (aH264 != bH264) return aH264 ? -1 : 1;
    return b.bitrate.compareTo(a.bitrate);
  }

  static int _compareAudioStreams(YtStreamOption a, YtStreamOption b) {
    final aStdM4a = a.container == 'm4a' && a.bitrate >= 100000;
    final bStdM4a = b.container == 'm4a' && b.bitrate >= 100000;
    if (aStdM4a != bStdM4a) return aStdM4a ? -1 : 1;
    return b.bitrate.compareTo(a.bitrate);
  }

  static int _parseHeight(String label, String? res) {
    final m1 = RegExp(r'(\d{3,4})p').firstMatch(label);
    if (m1 != null) return int.tryParse(m1.group(1)!) ?? 0;
    if (res != null) {
      final parts = res.split('x');
      if (parts.length == 2) return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  static int _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static int? _parseContentLength(Object? clen, String url) {
    final direct = _parseInt(clen);
    if (direct > 0) return direct;
    final uri = Uri.tryParse(url);
    final qClen = _parseInt(uri?.queryParameters['clen']);
    return qClen > 0 ? qClen : null;
  }

  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void dispose() {
    _yt.close();
    _http.close();
  }
}

