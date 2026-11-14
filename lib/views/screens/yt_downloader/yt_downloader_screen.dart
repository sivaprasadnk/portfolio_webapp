import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/yt_downloader/yt_models.dart';
import 'package:spnk/views/screens/yt_downloader/yt_service.dart';
import 'package:spnk/views/screens/yt_downloader/yt_web_helper.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class YtDownloaderScreen extends StatefulWidget {
  const YtDownloaderScreen({
    super.key,
    this.service,
    this.platformHelper,
  });

  static const routeName = '/yt-downloader';

  final YtService? service;
  final YtPlatformHelper? platformHelper;

  @override
  State<YtDownloaderScreen> createState() => _YtDownloaderScreenState();
}

enum _YtMediaTab {
  video('Video', Icons.videocam_rounded),
  audio('Audio', Icons.headphones_rounded),
  thumbnails('Thumbnails', Icons.image_rounded),
  tools('Captions & Tools', Icons.tune_rounded);

  const _YtMediaTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum _VideoContainerFilter {
  all('All Formats'),
  mp4('MP4'),
  webm('WEBM');

  const _VideoContainerFilter(this.label);
  final String label;
}

class _YtDownloaderScreenState extends State<YtDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  late final YtService _service;
  late final YtPlatformHelper _platformHelper;

  ParsedYoutubeTarget? _detectedTarget;
  YtVideoInfo? _videoInfo;
  bool _isFetching = false;
  String? _fetchError;

  _YtMediaTab _activeTab = _YtMediaTab.video;
  _VideoContainerFilter _containerFilter = _VideoContainerFilter.all;
  bool _mergeAudioForHdMp4 = true;

  // Embedded preview state
  bool _isPlayingPreview = false;
  String? _activeEmbedViewType;

  // Active download state
  bool _isDownloading = false;
  bool _cancelRequested = false;
  String? _activeDownloadId;
  String _downloadStageLabel = '';
  double? _downloadProgress; // null = indeterminate

  final List<YtDownloadRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? YtService();
    _platformHelper = widget.platformHelper ?? createYtPlatformHelper();
    _platformHelper.configurePageMeta();
    _urlController.addListener(_onInputChanged);

    final initialParam =
        Uri.base.queryParameters['url'] ?? Uri.base.queryParameters['v'];
    if (initialParam != null && initialParam.trim().isNotEmpty) {
      _urlController.text = initialParam.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchMedia();
      });
    }
  }

  void _onInputChanged() {
    final parsed = ParsedYoutubeTarget.tryParse(_urlController.text);
    if (parsed?.videoId != _detectedTarget?.videoId ||
        parsed?.kind != _detectedTarget?.kind) {
      setState(() {
        _detectedTarget = parsed;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onInputChanged);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedia([String? presetUrl]) async {
    if (presetUrl != null) {
      _urlController.text = presetUrl;
    }
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _fetchError = 'Paste a YouTube link or choose a sample video below.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isFetching = true;
      _fetchError = null;
      _isPlayingPreview = false;
      _activeEmbedViewType = null;
    });

    try {
      final info = await _service.fetchVideoInfo(raw);
      if (!mounted) return;
      setState(() {
        _videoInfo = info;
        _isFetching = false;
        if (!info.hasMediaStreams && _activeTab == _YtMediaTab.video) {
          _activeTab = _YtMediaTab.thumbnails;
        }
      });
      GamificationController.instance.addXp(
        15,
        reason: 'Analyzed YouTube Stream: ${info.videoId}',
        uniqueKey: 'yt_fetch_${info.videoId}',
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetching = false;
        _fetchError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetching = false;
        _fetchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _togglePreviewPlayer(YtVideoInfo info) {
    if (!_platformHelper.isWeb) {
      launchUrl(Uri.parse(info.watchUrl));
      return;
    }
    setState(() {
      if (_isPlayingPreview) {
        _isPlayingPreview = false;
      } else {
        _activeEmbedViewType ??= _platformHelper.registerEmbedPlayer(
          videoId: info.videoId,
          startSeconds: _detectedTarget?.startSeconds ?? 0,
        );
        _isPlayingPreview = true;
      }
    });
  }

  Future<Uint8List> _fetchBytes(
    String url, {
    int? expectedBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final webBytes = await _platformHelper.fetchBytesWithProgress(
      url: url,
      expectedBytes: expectedBytes,
      onProgress: onProgress,
    );
    if (webBytes != null) {
      return webBytes;
    }
    return _service.downloadBytesWithProgress(
      url,
      expectedBytes: expectedBytes,
      isCancelled: () => _cancelRequested,
      onProgress: onProgress,
    );
  }

  Future<void> _downloadStream(
    YtVideoInfo info,
    YtStreamOption stream, {
    bool convertToWav = false,
  }) async {
    if (_isDownloading) return;

    final taskKey = convertToWav ? 'wav_${stream.itag}' : 'stream_${stream.itag}';
    final shouldMuxMp4 = !convertToWav &&
        _mergeAudioForHdMp4 &&
        stream.canRemuxToMp4 &&
        info.bestM4aAudio != null &&
        _platformHelper.isWeb;

    final ext = convertToWav ? 'wav' : stream.fileExtension;
    final cleanQuality =
        stream.qualityLabel.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final fileName = '${info.sanitizedBaseName}_$cleanQuality.$ext';
    final badgeLabel = convertToWav
        ? 'WAV PCM'
        : (shouldMuxMp4
            ? '${stream.qualityLabel} MP4+AAC'
            : '${stream.qualityLabel} ${ext.toUpperCase()}');

    setState(() {
      _isDownloading = true;
      _cancelRequested = false;
      _activeDownloadId = taskKey;
      _downloadProgress = 0.0;
      _downloadStageLabel = shouldMuxMp4
          ? 'Step 1/3 • Downloading ${stream.qualityLabel} video stream...'
          : 'Downloading ${stream.qualityLabel} (${ext.toUpperCase()})...';
    });

    try {
      final primaryBytes = await _fetchBytes(
        stream.downloadUrl,
        expectedBytes: stream.contentLengthBytes,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            if (total != null && total > 0) {
              final ratio = (received / total).clamp(0.0, 1.0);
              _downloadProgress = shouldMuxMp4 ? ratio * 0.65 : ratio;
              final mbDone = (received / (1024 * 1024)).toStringAsFixed(1);
              final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
              _downloadStageLabel = shouldMuxMp4
                  ? 'Step 1/3 • Video: $mbDone / $mbTotal MB'
                  : 'Downloading: $mbDone / $mbTotal MB (${(ratio * 100).toInt()}%)';
            } else {
              _downloadProgress = null;
            }
          });
        },
      );

      if (_cancelRequested) throw const YtDownloadCancelledException();

      if (convertToWav) {
        setState(() {
          _downloadProgress = null;
          _downloadStageLabel = 'Decoding & encoding 16-bit lossless WAV...';
        });
        final wavBytes = await _platformHelper.convertAudioToWav(primaryBytes);
        if (wavBytes == null) {
          throw Exception('WAV conversion is supported in modern web browsers.');
        }
        final saved = await _platformHelper.saveBytesAsFile(
          bytes: wavBytes,
          fileName: fileName,
          mimeType: 'audio/wav',
        );
        if (!saved) {
          throw Exception('Could not save WAV file.');
        }
      } else if (shouldMuxMp4) {
        final audioTrack = info.bestM4aAudio!;
        setState(() {
          _downloadProgress = 0.68;
          _downloadStageLabel = 'Step 2/3 • Downloading AAC audio track...';
        });
        final audioBytes = await _fetchBytes(
          audioTrack.downloadUrl,
          expectedBytes: audioTrack.contentLengthBytes,
          onProgress: (received, total) {
            if (!mounted) return;
            if (total != null && total > 0) {
              setState(() {
                _downloadProgress =
                    0.65 + ((received / total).clamp(0.0, 1.0) * 0.22);
              });
            }
          },
        );

        if (_cancelRequested) throw const YtDownloadCancelledException();

        setState(() {
          _downloadProgress = null;
          _downloadStageLabel =
              'Step 3/3 • Merging HD Video + Audio into MP4...';
        });

        final muxedBytes = await _platformHelper.muxMp4VideoAndAudio(
          videoBytes: primaryBytes,
          audioBytes: audioBytes,
        );

        if (muxedBytes != null && muxedBytes.isNotEmpty) {
          await _platformHelper.saveBytesAsFile(
            bytes: muxedBytes,
            fileName: fileName,
            mimeType: 'video/mp4',
          );
        } else {
          // Graceful fallback: save video & audio tracks directly so nothing is lost
          await _platformHelper.saveBytesAsFile(
            bytes: primaryBytes,
            fileName: fileName,
            mimeType: stream.mimeType,
          );
          await _platformHelper.saveBytesAsFile(
            bytes: audioBytes,
            fileName: '${info.sanitizedBaseName}_audio.m4a',
            mimeType: 'audio/mp4',
          );
          _showSnack(
            'Saved HD video + M4A audio tracks (browser muxer unavailable).',
          );
        }
      } else {
        final saved = await _platformHelper.saveBytesAsFile(
          bytes: primaryBytes,
          fileName: fileName,
          mimeType: stream.mimeType,
        );
        if (!saved && !_platformHelper.isWeb) {
          await launchUrl(
            Uri.parse(stream.downloadUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      }

      if (!mounted) return;
      _recordDownload(
        info: info,
        badge: badgeLabel,
        fileName: fileName,
      );
      _showSnack('Downloaded $fileName');
    } on YtDownloadCancelledException {
      if (mounted) {
        _showSnack('Download cancelled.');
      }
    } catch (_) {
      // Fallback to in-place attachment download (hidden iframe on web — never opens a new tab)
      if (mounted && !convertToWav) {
        final opened = await _platformHelper.triggerDirectDownload(
          url: stream.downloadUrl,
          fileName: fileName,
        );
        if (!opened && !_platformHelper.isWeb) {
          await launchUrl(
            Uri.parse(stream.downloadUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        _recordDownload(
          info: info,
          badge: badgeLabel,
          fileName: fileName,
        );
        _showSnack('Downloading $fileName...');
      } else if (mounted) {
        _showSnack('Could not complete audio conversion.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _cancelRequested = false;
          _activeDownloadId = null;
          _downloadProgress = null;
          _downloadStageLabel = '';
        });
      }
    }
  }

  Future<void> _downloadThumbnail(
    YtVideoInfo info,
    YtThumbnailOption thumb,
  ) async {
    if (_isDownloading) return;
    final taskKey = 'thumb_${thumb.id}';
    final fileName = '${info.sanitizedBaseName}_${thumb.id}.jpg';

    setState(() {
      _isDownloading = true;
      _cancelRequested = false;
      _activeDownloadId = taskKey;
      _downloadProgress = null;
      _downloadStageLabel = 'Downloading ${thumb.label} thumbnail...';
    });

    try {
      final candidateUrls = <String>[
        thumb.url,
        for (final t in info.thumbnails)
          if (t.url != thumb.url) t.url,
      ];

      Uint8List? bytes;
      for (final candidate in candidateUrls) {
        try {
          bytes = await _fetchBytes(candidate);
          if (bytes.isNotEmpty) break;
        } catch (_) {
          // Try next highest available resolution if maxresdefault/sddefault is 404
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Thumbnail unavailable');
      }

      final saved = await _platformHelper.saveBytesAsFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'image/jpeg',
      );
      if (!saved && !_platformHelper.isWeb) {
        await launchUrl(
          Uri.parse(thumb.url),
          mode: LaunchMode.externalApplication,
        );
      }
      if (!mounted) return;
      _recordDownload(
        info: info,
        badge: 'JPG ${thumb.resolution}',
        fileName: fileName,
      );
      _showSnack('Thumbnail saved as $fileName');
    } catch (_) {
      if (mounted) {
        if (_platformHelper.isWeb) {
          _showSnack('Thumbnail could not be downloaded.');
        } else {
          await launchUrl(
            Uri.parse(thumb.url),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _activeDownloadId = null;
          _downloadStageLabel = '';
        });
      }
    }
  }

  Future<void> _downloadCaption(
    YtVideoInfo info,
    YtCaptionOption caption,
  ) async {
    if (_isDownloading) return;
    final fileName =
        '${info.sanitizedBaseName}_${caption.languageCode}.vtt';

    setState(() {
      _isDownloading = true;
      _activeDownloadId = 'cap_${caption.languageCode}';
      _downloadProgress = null;
      _downloadStageLabel = 'Downloading ${caption.label} subtitles...';
    });

    try {
      final bytes = await _fetchBytes(caption.downloadUrl);
      final saved = await _platformHelper.saveBytesAsFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'text/vtt',
      );
      if (!saved && !_platformHelper.isWeb) {
        await launchUrl(Uri.parse(caption.downloadUrl));
      }
      if (!mounted) return;
      _recordDownload(
        info: info,
        badge: 'SUBS (${caption.languageCode.toUpperCase()})',
        fileName: fileName,
      );
      _showSnack('Downloaded subtitles: $fileName');
    } catch (_) {
      if (mounted) {
        if (_platformHelper.isWeb) {
          await _platformHelper.triggerDirectDownload(
            url: caption.downloadUrl,
            fileName: fileName,
          );
        } else {
          await launchUrl(Uri.parse(caption.downloadUrl));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _activeDownloadId = null;
          _downloadStageLabel = '';
        });
      }
    }
  }

  Future<void> _exportMetadataJson(YtVideoInfo info) async {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'videoId': info.videoId,
      'title': info.title,
      'author': info.author,
      'authorUrl': info.authorUrl,
      'watchUrl': info.watchUrl,
      'durationSeconds': info.lengthSeconds,
      'formattedDuration': info.formattedDuration,
      'views': info.viewCount,
      'likes': info.likeCount,
      'dislikes': info.dislikeCount,
      'rating': info.rating,
      'publishedText': info.publishedText,
      'thumbnails': info.thumbnails
          .map((t) => {'id': t.id, 'resolution': t.resolution, 'url': t.url})
          .toList(),
      'videoFormats': info.videoStreams
          .map(
            (s) => {
              'itag': s.itag,
              'quality': s.qualityLabel,
              'container': s.fileExtension,
              'codecs': s.codecs,
              'sizeBytes': s.contentLengthBytes,
            },
          )
          .toList(),
      'audioFormats': info.audioStreams
          .map(
            (s) => {
              'itag': s.itag,
              'quality': s.qualityLabel,
              'container': s.fileExtension,
              'codecs': s.codecs,
              'sizeBytes': s.contentLengthBytes,
            },
          )
          .toList(),
    });

    final fileName = '${info.sanitizedBaseName}_metadata.json';
    final bytes = Uint8List.fromList(utf8.encode(payload));
    final saved = await _platformHelper.saveBytesAsFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/json',
    );
    if (!saved) {
      await Clipboard.setData(ClipboardData(text: payload));
      _showSnack('Metadata JSON copied to clipboard');
      return;
    }
    _recordDownload(info: info, badge: 'JSON META', fileName: fileName);
    _showSnack('Exported $fileName');
  }

  void _recordDownload({
    required YtVideoInfo info,
    required String badge,
    required String fileName,
  }) {
    setState(() {
      _history.removeWhere(
        (item) => item.videoId == info.videoId && item.formatBadge == badge,
      );
      _history.insert(
        0,
        YtDownloadRecord(
          videoId: info.videoId,
          title: info.title,
          formatBadge: badge,
          fileName: fileName,
          completedAt: DateTime.now(),
        ),
      );
      if (_history.length > 8) {
        _history.removeLast();
      }
    });
    GamificationController.instance.addXp(
      20,
      reason: 'Downloaded Media ($badge)',
      uniqueKey: 'yt_dl_${info.videoId}_$badge',
    );
  }

  Future<void> _openEngineSettingsDialog(
    ThemeState themeState,
    Color accent,
  ) async {
    final controller = TextEditingController(text: _service.customEndpoint);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: themeState.isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: themeState.cardBorderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.dns_rounded, color: accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Stream Engine Settings',
                style: context.displaySmall.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By default, YouTube Downloader auto-discovers healthy CORS-enabled Invidious nodes and official oEmbed endpoints. Optionally connect your own self-hosted Invidious or Cobalt API URL:',
                  style: context.bodySmall.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: context.primaryColor.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  style: context.bodyMedium.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'https://your-cobalt-or-invidious.app',
                    hintStyle: context.bodySmall.copyWith(
                      fontSize: 14,
                      color: context.primaryColor.withValues(alpha: 0.4),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_videoInfo != null &&
                    _videoInfo!.activeProviderNode.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Active stream node: ${_videoInfo!.activeProviderNode}',
                          style: context.bodySmall.copyWith(
                            fontSize: 12.5,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                _service.setCustomEndpoint('');
                Navigator.of(ctx).pop();
                _showSnack('Reset to automatic stream node discovery');
              },
              child: const Text('Reset Default'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor:
                    themeState.isDark ? const Color(0xFF090D16) : Colors.white,
              ),
              onPressed: () {
                _service.setCustomEndpoint(controller.text);
                Navigator.of(ctx).pop();
                _showSnack('Engine endpoint updated');
                if (_urlController.text.trim().isNotEmpty) {
                  _fetchMedia();
                }
              },
              child: const Text('Save & Apply'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileDevice;
    final canPop = Navigator.of(context).canPop();

    return PortfolioStyleBackground(
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final accent = themeState.accentColor;
            final secondary = themeState.secondaryAccent;

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: canPop
                    ? IconButton(
                        tooltip: 'Back to Portfolio',
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: context.primaryColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    : IconButton(
                        tooltip: 'Portfolio Home',
                        icon: Icon(
                          Icons.home_outlined,
                          color: context.primaryColor.withValues(alpha: 0.8),
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/'),
                      ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.55),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'YouTube Downloader',
                        overflow: TextOverflow.ellipsis,
                        style: context.displaySmall.copyWith(
                          fontSize: isMobile ? 18.5 : 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (!isMobile) const StyleSwitcherBar(compact: true),
                  IconButton(
                    tooltip: 'Stream Engine Settings',
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: context.primaryColor.withValues(alpha: 0.82),
                    ),
                    onPressed: () =>
                        _openEngineSettingsDialog(themeState, accent),
                  ),
                  IconButton(
                    tooltip: themeState.isDark ? 'Light Mode' : 'Dark Mode',
                    icon: Icon(
                      themeState.isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 20,
                      color: context.primaryColor.withValues(alpha: 0.82),
                    ),
                    onPressed: () {
                      context.read<ThemeBloc>().add(
                            ToggleTheme(
                              isDarkTheme: themeState.isDark,
                              currentTheme: themeState.themeData,
                            ),
                          );
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 24,
                    vertical: isMobile ? 12 : 22,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildUrlSearchCard(
                          themeState: themeState,
                          accent: accent,
                          secondary: secondary,
                          isMobile: isMobile,
                        ),
                        if (_isDownloading) ...[
                          const SizedBox(height: 16),
                          _buildActiveDownloadBanner(themeState, accent),
                        ],
                        if (_fetchError != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorCard(themeState),
                        ],
                        if (_isFetching) ...[
                          const SizedBox(height: 24),
                          _buildLoadingCard(themeState, accent),
                        ] else if (_videoInfo != null) ...[
                          const SizedBox(height: 20),
                          _buildVideoWorkbench(
                            info: _videoInfo!,
                            themeState: themeState,
                            accent: accent,
                            secondary: secondary,
                            isMobile: isMobile,
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          _buildEmptyFeatureHighlights(
                            themeState: themeState,
                            accent: accent,
                            secondary: secondary,
                            isMobile: isMobile,
                          ),
                        ],
                        if (_history.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSessionHistoryCard(themeState, accent),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUrlSearchCard({
    required ThemeState themeState,
    required Color accent,
    required Color secondary,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: themeState.cardSurfaceColor,
        borderRadius: BorderRadius.circular(themeState.cardRadius),
        border: Border.all(
          color: themeState.cardBorderColor,
          width: 1.15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'PASTE YOUTUBE VIDEO, SHORTS, OR MUSIC LINK',
                style: context.bodySmall.copyWith(
                  fontSize: 12.5,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              if (_detectedTarget != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${_detectedTarget!.kind.badge} • ${_detectedTarget!.videoId}',
                    style: context.bodySmall.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile) ...[
            _buildUrlTextField(themeState, accent),
            const SizedBox(height: 10),
            _buildAnalyzeButton(themeState, accent),
          ] else
            Row(
              children: [
                Expanded(child: _buildUrlTextField(themeState, accent)),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: _buildAnalyzeButton(themeState, accent),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Try instant sample:',
                style: context.bodySmall.copyWith(
                  fontSize: 12.5,
                  color: context.primaryColor.withValues(alpha: 0.62),
                ),
              ),
              ...YtSamplePreset.presets.map((preset) {
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _isFetching ? null : () => _fetchMedia(preset.url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: themeState.isDark ? 0.12 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${preset.label} (${preset.tag})',
                          style: context.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTextField(ThemeState themeState, Color accent) {
    return TextField(
      key: const Key('yt_url_input'),
      controller: _urlController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _fetchMedia(),
      style: context.bodyMedium.copyWith(fontSize: 16),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'https://www.youtube.com/watch?v=... or youtu.be/...',
        hintStyle: context.bodySmall.copyWith(
          fontSize: 14.5,
          color: context.primaryColor.withValues(alpha: 0.42),
        ),
        prefixIcon: Icon(
          Icons.link_rounded,
          size: 20,
          color: accent,
        ),
        filled: true,
        hoverColor: Colors.transparent,
        fillColor: context.primaryColor
            .withValues(alpha: themeState.isDark ? 0.05 : 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeState.cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeState.cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Paste URL',
              icon: Icon(
                Icons.content_paste_rounded,
                size: 18,
                color: context.primaryColor.withValues(alpha: 0.68),
              ),
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                final clip = data?.text?.trim() ?? '';
                if (clip.isNotEmpty) {
                  _urlController.text = clip;
                  if (ParsedYoutubeTarget.tryParse(clip) != null) {
                    _fetchMedia(clip);
                  }
                }
              },
            ),
            if (_urlController.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear',
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.primaryColor.withValues(alpha: 0.68),
                ),
                onPressed: () {
                  _urlController.clear();
                  setState(() {
                    _fetchError = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(ThemeState themeState, Color accent) {
    return ElevatedButton.icon(
      key: const Key('yt_fetch_button'),
      onPressed: _isFetching ? null : () => _fetchMedia(),
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor:
            themeState.isDark ? const Color(0xFF090D16) : Colors.white,
        disabledBackgroundColor: accent.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      icon: _isFetching
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : const Icon(Icons.bolt_rounded, size: 20),
      label: Text(
        _isFetching ? 'Fetching...' : 'Fetch Media',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveDownloadBanner(ThemeState themeState, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: themeState.isDark ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _downloadStageLabel,
                  style: context.bodySmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _cancelRequested = true;
                  });
                  _platformHelper.cancelActiveFetch();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 6,
              backgroundColor: context.primaryColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeState themeState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fetchError!,
              style: context.bodySmall.copyWith(
                fontSize: 14,
                color: context.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeState themeState, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
      decoration: BoxDecoration(
        color: themeState.cardSurfaceColor,
        borderRadius: BorderRadius.circular(themeState.cardRadius),
        border: Border.all(color: themeState.cardBorderColor),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: accent),
          const SizedBox(height: 16),
          Text(
            'Extracting HD video streams, audio tracks & metadata...',
            textAlign: TextAlign.center,
            style: context.bodyMedium.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoWorkbench({
    required YtVideoInfo info,
    required ThemeState themeState,
    required Color accent,
    required Color secondary,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: themeState.cardSurfaceColor,
        borderRadius: BorderRadius.circular(themeState.cardRadius),
        border: Border.all(color: themeState.cardBorderColor, width: 1.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMediaHeader(
            info: info,
            themeState: themeState,
            accent: accent,
            secondary: secondary,
          ),
          if (info.streamWarning != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info.streamWarning!,
                      style: context.bodySmall.copyWith(
                        fontSize: 13,
                        color: context.primaryColor.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _openEngineSettingsDialog(themeState, accent),
                    child: Text(
                      'Configure',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          _buildMediaTabBar(themeState, accent, info),
          const SizedBox(height: 18),
          switch (_activeTab) {
            _YtMediaTab.video =>
              _buildVideoStreamsTab(info, themeState, accent, secondary),
            _YtMediaTab.audio =>
              _buildAudioStreamsTab(info, themeState, accent, secondary),
            _YtMediaTab.thumbnails =>
              _buildThumbnailsTab(info, themeState, accent),
            _YtMediaTab.tools =>
              _buildCaptionsAndToolsTab(info, themeState, accent, secondary),
          },
        ],
      ),
    );
  }

  Widget _buildMediaHeader({
    required YtVideoInfo info,
    required ThemeState themeState,
    required Color accent,
    required Color secondary,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final previewWidget = AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isPlayingPreview && _activeEmbedViewType != null)
                  _platformHelper.buildEmbedPlayer(_activeEmbedViewType!)
                else ...[
                  Image.network(
                    info.hdThumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(
                      info.primaryThumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: const Color(0xFF0F172A),
                        child: Center(
                          child: Icon(
                            Icons.ondemand_video_rounded,
                            size: 44,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.68),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _togglePreviewPlayer(info),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 34,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_isPlayingPreview)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      tooltip: 'Close Player',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.72),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => _togglePreviewPlayer(info),
                    ),
                  ),
              ],
            ),
          ),
        );

        final detailsWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaBadge(
                  label: info.urlKind.badge,
                  color: const Color(0xFFEF4444),
                ),
                if (info.activeProviderNode.isNotEmpty)
                  _MetaBadge(
                    label: 'STREAM READY',
                    color: const Color(0xFF10B981),
                  ),
                if (info.publishedText.isNotEmpty)
                  _MetaBadge(
                    label: info.publishedText.toUpperCase(),
                    color: secondary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              info.title,
              style: context.displaySmall.copyWith(
                fontSize: wide ? 22 : 19,
                fontWeight: FontWeight.bold,
                height: 1.22,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: info.authorUrl.isNotEmpty
                  ? () => launchUrl(Uri.parse(info.authorUrl))
                  : null,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 15,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      info.author,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _StatChip(
                  icon: Icons.visibility_outlined,
                  label: '${YtVideoInfo.formatCompactCount(info.viewCount)} views',
                ),
                _StatChip(
                  icon: Icons.thumb_up_outlined,
                  label: '${YtVideoInfo.formatCompactCount(info.likeCount)} likes',
                ),
                if (info.rating != null)
                  _StatChip(
                    icon: Icons.star_rounded,
                    label: '${info.rating!.toStringAsFixed(1)} / 5.0',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _togglePreviewPlayer(info),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    _isPlayingPreview
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _isPlayingPreview ? 'Stop Preview' : 'Preview Video',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: info.watchUrl));
                    _showSnack('YouTube link copied');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    side: BorderSide(color: themeState.cardBorderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text(
                    'Copy URL',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Open on YouTube',
                  onPressed: () => launchUrl(Uri.parse(info.watchUrl)),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: themeState.cardBorderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 17,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 285, child: previewWidget),
              const SizedBox(width: 22),
              Expanded(child: detailsWidget),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            previewWidget,
            const SizedBox(height: 16),
            detailsWidget,
          ],
        );
      },
    );
  }

  Widget _buildMediaTabBar(
    ThemeState themeState,
    Color accent,
    YtVideoInfo info,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.primaryColor
            .withValues(alpha: themeState.isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeState.cardBorderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _YtMediaTab.values.map((tab) {
            final selected = _activeTab == tab;
            final countLabel = switch (tab) {
              _YtMediaTab.video => '${info.videoStreams.length}',
              _YtMediaTab.audio =>
                '${info.audioStreams.length + (info.audioStreams.isNotEmpty ? 1 : 0)}',
              _YtMediaTab.thumbnails => '${info.thumbnails.length}',
              _YtMediaTab.tools => '${info.captions.length + 2}',
            };

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => setState(() => _activeTab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 16,
                        color: selected
                            ? (themeState.isDark
                                ? const Color(0xFF090D16)
                                : Colors.white)
                            : context.primaryColor.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${tab.label} ($countLabel)',
                        style: context.bodySmall.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? (themeState.isDark
                                  ? const Color(0xFF090D16)
                                  : Colors.white)
                              : context.primaryColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVideoStreamsTab(
    YtVideoInfo info,
    ThemeState themeState,
    Color accent,
    Color secondary,
  ) {
    final filtered = info.videoStreams.where((s) {
      return switch (_containerFilter) {
        _VideoContainerFilter.all => true,
        _VideoContainerFilter.mp4 => s.fileExtension == 'mp4',
        _VideoContainerFilter.webm => s.fileExtension == 'webm',
      };
    }).toList();

    if (info.videoStreams.isEmpty) {
      return _buildNoStreamsNotice(themeState, accent);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 6,
              children: _VideoContainerFilter.values.map((f) {
                final selected = _containerFilter == f;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _containerFilter = f),
                  selectedColor: accent.withValues(alpha: 0.22),
                  labelStyle: context.bodySmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: selected ? accent : context.primaryColor,
                  ),
                );
              }).toList(),
            ),
            if (info.bestM4aAudio != null && _platformHelper.isWeb)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    setState(() => _mergeAudioForHdMp4 = !_mergeAudioForHdMp4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _mergeAudioForHdMp4
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 19,
                        color: accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-merge AAC Audio into HD MP4',
                        style: context.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...filtered.map((stream) {
          final hasSound = stream.isCombined ||
              (_mergeAudioForHdMp4 &&
                  stream.canRemuxToMp4 &&
                  info.bestM4aAudio != null &&
                  _platformHelper.isWeb);
          final isActiveTask = _activeDownloadId == 'stream_${stream.itag}';

          return _FormatDownloadTile(
            badge: stream.tierBadge,
            badgeColor: stream.resolutionHeight >= 1080 ? secondary : accent,
            title:
                '${stream.qualityLabel} • ${stream.fileExtension.toUpperCase()}',
            subtitle:
                '${stream.codecShortLabel} • ${stream.fps}fps • ${hasSound ? "Video + Audio" : "Video Only"}',
            trailingMeta: stream.formattedSize,
            buttonLabel: isActiveTask ? 'Downloading' : 'Download',
            isBusy: _isDownloading,
            themeState: themeState,
            accent: accent,
            onDownload: () => _downloadStream(info, stream),
          );
        }),
      ],
    );
  }

  Widget _buildAudioStreamsTab(
    YtVideoInfo info,
    ThemeState themeState,
    Color accent,
    Color secondary,
  ) {
    if (info.audioStreams.isEmpty) {
      return _buildNoStreamsNotice(themeState, accent);
    }

    final bestSourceForWav = info.bestM4aAudio ?? info.audioStreams.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_platformHelper.isWeb)
          _FormatDownloadTile(
            badge: 'LOSSLESS WAV',
            badgeColor: secondary,
            title: 'Studio WAV • 16-bit PCM',
            subtitle: 'Decoded in-browser from HQ audio stream (Web Audio API)',
            trailingMeta: 'WAV',
            buttonLabel: _activeDownloadId == 'wav_${bestSourceForWav.itag}'
                ? 'Converting'
                : 'Convert & Save',
            isBusy: _isDownloading,
            themeState: themeState,
            accent: accent,
            onDownload: () => _downloadStream(
              info,
              bestSourceForWav,
              convertToWav: true,
            ),
          ),
        ...info.audioStreams.map((stream) {
          final isActiveTask = _activeDownloadId == 'stream_${stream.itag}';
          return _FormatDownloadTile(
            badge: stream.tierBadge,
            badgeColor: accent,
            title:
                '${stream.qualityLabel} • ${stream.fileExtension.toUpperCase()}',
            subtitle:
                '${stream.codecShortLabel} Audio Track (${stream.mimeType})',
            trailingMeta: stream.formattedSize,
            buttonLabel: isActiveTask ? 'Downloading' : 'Download',
            isBusy: _isDownloading,
            themeState: themeState,
            accent: accent,
            onDownload: () => _downloadStream(info, stream),
          );
        }),
      ],
    );
  }

  Widget _buildThumbnailsTab(
    YtVideoInfo info,
    ThemeState themeState,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: info.thumbnails.map((thumb) {
        final isActiveTask = _activeDownloadId == 'thumb_${thumb.id}';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.primaryColor
                .withValues(alpha: themeState.isDark ? 0.04 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeState.cardBorderColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: Image.network(
                    thumb.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: const Color(0xFF1E293B),
                      child: Icon(Icons.image_outlined, color: accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thumb.label,
                      style: context.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${thumb.resolution} • Direct JPEG',
                      style: context.bodySmall.copyWith(
                        fontSize: 13,
                        color: context.primaryColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isDownloading
                    ? null
                    : () => _downloadThumbnail(info, thumb),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: themeState.isDark
                      ? const Color(0xFF090D16)
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 17),
                label: Text(
                  isActiveTask ? 'Saving...' : 'Save JPG',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCaptionsAndToolsTab(
    YtVideoInfo info,
    ThemeState themeState,
    Color accent,
    Color secondary,
  ) {
    final embedSnippet =
        '<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/${info.videoId}" title="${info.title.replaceAll('"', '&quot;')}" frameborder="0" allowfullscreen></iframe>';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormatDownloadTile(
          badge: 'JSON',
          badgeColor: accent,
          title: 'Export Full Video Metadata (.json)',
          subtitle:
              'Includes video stats, channel info, thumbnails & stream manifest',
          trailingMeta: 'UTF-8',
          buttonLabel: 'Export JSON',
          isBusy: _isDownloading,
          themeState: themeState,
          accent: accent,
          onDownload: () => _exportMetadataJson(info),
        ),
        _FormatDownloadTile(
          badge: 'HTML',
          badgeColor: secondary,
          title: 'Privacy-Enhanced Responsive Embed Code',
          subtitle: 'youtube-nocookie.com iframe snippet ready for websites',
          trailingMeta: 'IFRAME',
          buttonLabel: 'Copy Code',
          isBusy: false,
          themeState: themeState,
          accent: accent,
          onDownload: () {
            Clipboard.setData(ClipboardData(text: embedSnippet));
            _showSnack('HTML iframe embed code copied');
          },
        ),
        if (info.captions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'SUBTITLE & CAPTION TRACKS (.VTT)',
            style: context.bodySmall.copyWith(
              fontSize: 12,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          ...info.captions.map((cap) {
            return _FormatDownloadTile(
              badge: cap.languageCode.toUpperCase(),
              badgeColor: const Color(0xFF10B981),
              title: cap.label,
              subtitle: 'WebVTT Subtitle Track (.vtt)',
              trailingMeta: 'VTT',
              buttonLabel: 'Download',
              isBusy: _isDownloading,
              themeState: themeState,
              accent: accent,
              onDownload: () => _downloadCaption(info, cap),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildNoStreamsNotice(ThemeState themeState, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeState.cardBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_sync_rounded, size: 34, color: accent),
          const SizedBox(height: 10),
          Text(
            'Direct media streams are temporarily unavailable from public relays for this video.',
            textAlign: TextAlign.center,
            style: context.bodyMedium.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 6),
          Text(
            'You can still download Ultra HD Thumbnails, export JSON metadata, preview the video, or connect a custom Cobalt/Invidious node in Settings.',
            textAlign: TextAlign.center,
            style: context.bodySmall.copyWith(
              fontSize: 13.5,
              color: context.primaryColor.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeatureHighlights({
    required ThemeState themeState,
    required Color accent,
    required Color secondary,
    required bool isMobile,
  }) {
    final features = [
      (
        Icons.hd_rounded,
        '4K & 1080p60 Video',
        'Extract crisp MP4 (H.264) & WebM (VP9) streams with automatic client-side AAC audio muxing.',
        accent,
      ),
      (
        Icons.graphic_eq_rounded,
        'M4A, Opus & Studio WAV',
        'Save direct high-bitrate audio streams or convert in-browser to lossless 16-bit PCM WAV.',
        secondary,
      ),
      (
        Icons.collections_rounded,
        'MaxRes Thumbnails & Subtitles',
        'Grab 1280×720 HD cover art, WebVTT caption tracks, and structured JSON video manifests.',
        const Color(0xFF10B981),
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: features.map((f) {
        return SizedBox(
          width: isMobile ? double.infinity : 268,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: themeState.cardSurfaceColor,
              borderRadius: BorderRadius.circular(themeState.cardRadius),
              border: Border.all(color: themeState.cardBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: f.$4.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.$1, color: f.$4, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  f.$2,
                  style: context.displaySmall.copyWith(
                    fontSize: 17.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  f.$3,
                  style: context.bodySmall.copyWith(
                    fontSize: 13.5,
                    height: 1.38,
                    color: context.primaryColor.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSessionHistoryCard(ThemeState themeState, Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: themeState.cardSurfaceColor,
        borderRadius: BorderRadius.circular(themeState.cardRadius),
        border: Border.all(color: themeState.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT DOWNLOADS (${_history.length})',
                style: context.bodySmall.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              TextButton(
                onPressed: () => setState(_history.clear),
                child: Text(
                  'Clear',
                  style: context.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: context.primaryColor.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._history.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _fetchMedia(
                  'https://www.youtube.com/watch?v=${item.videoId}',
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeState.cardBorderColor),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 56,
                          height: 32,
                          child: Image.network(
                            item.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: const Color(0xFF1E293B),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.bodySmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.bodySmall.copyWith(
                                fontSize: 12,
                                color: context.primaryColor
                                    .withValues(alpha: 0.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MetaBadge(label: item.formatBadge, color: accent),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FormatDownloadTile extends StatelessWidget {
  const _FormatDownloadTile({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.trailingMeta,
    required this.buttonLabel,
    required this.isBusy,
    required this.themeState,
    required this.accent,
    required this.onDownload,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String trailingMeta;
  final String buttonLabel;
  final bool isBusy;
  final ThemeState themeState;
  final Color accent;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileDevice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: context.primaryColor
            .withValues(alpha: themeState.isDark ? 0.04 : 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeState.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 68),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.48)),
            ),
            child: Text(
              badge,
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.bodyMedium.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: context.primaryColor.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 10),
            Text(
              trailingMeta,
              style: context.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.primaryColor.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor:
                  themeState.isDark ? const Color(0xFF090D16) : Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.25),
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 11 : 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 17),
            label: Text(
              buttonLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: context.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: context.primaryColor.withValues(alpha: 0.65),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: context.bodySmall.copyWith(
            fontSize: 13.5,
            color: context.primaryColor.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}
