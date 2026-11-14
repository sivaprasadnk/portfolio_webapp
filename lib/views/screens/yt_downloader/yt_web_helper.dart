import 'dart:typed_data';
import 'package:flutter/widgets.dart';

export 'yt_web_helper_stub.dart'
    if (dart.library.js_interop) 'yt_web_helper_web.dart';

abstract class YtPlatformHelper {
  bool get isWeb;

  void configurePageMeta();

  Future<Uint8List?> fetchBytesWithProgress({
    required String url,
    int? expectedBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  });

  void cancelActiveFetch();

  Future<bool> saveBytesAsFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });

  Future<bool> triggerDirectDownload({
    required String url,
    required String fileName,
  });

  Future<Uint8List?> muxMp4VideoAndAudio({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
  });

  Future<Uint8List?> convertAudioToWav(Uint8List encodedAudioBytes);

  String registerEmbedPlayer({
    required String videoId,
    int startSeconds = 0,
  });

  Widget buildEmbedPlayer(String viewType);
}

