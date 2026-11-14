import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:spnk/views/screens/yt_downloader/yt_web_helper.dart';

YtPlatformHelper createYtPlatformHelper() => _StubYtPlatformHelper();

class _StubYtPlatformHelper implements YtPlatformHelper {
  @override
  bool get isWeb => false;

  @override
  void configurePageMeta() {}

  @override
  Future<bool> saveBytesAsFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return false;
  }

  @override
  Future<bool> triggerDirectDownload({
    required String url,
    required String fileName,
  }) async {
    return false;
  }

  @override
  Future<Uint8List?> muxMp4VideoAndAudio({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
  }) async {
    return null;
  }

  @override
  Future<Uint8List?> convertAudioToWav(Uint8List encodedAudioBytes) async {
    return null;
  }

  @override
  String registerEmbedPlayer({
    required String videoId,
    int startSeconds = 0,
  }) {
    return 'stub-yt-embed-$videoId';
  }

  @override
  Widget buildEmbedPlayer(String viewType) {
    return const SizedBox.shrink();
  }
}

