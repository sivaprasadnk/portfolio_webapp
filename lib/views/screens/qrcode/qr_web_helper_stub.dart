import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:spnk/views/screens/qrcode/qr_web_helper.dart';

QrPlatformHelper createQrPlatformHelper() => _StubQrPlatformHelper();

class _StubQrPlatformHelper implements QrPlatformHelper {
  @override
  bool get isWeb => false;

  @override
  Future<bool> downloadPngBytes(Uint8List pngBytes, String fileName) async {
    return false;
  }

  @override
  String registerCameraView() => 'stub-camera-view';

  @override
  Future<String?> startCamera({
    required String viewType,
    required bool useFrontCamera,
  }) async {
    return 'Camera scanning is available in the web browser.';
  }

  @override
  void stopCamera(String viewType) {}

  @override
  String? decodeCurrentVideoFrame(String viewType) => null;

  @override
  Future<QrImageScanOutcome> pickAndDecodeImage() async {
    return const QrImageScanOutcome(
      status: QrImageScanStatus.error,
      errorMessage: 'Image scanning is only supported on web.',
    );
  }

  @override
  Widget buildCameraPreview(String viewType) {
    return const SizedBox.shrink();
  }
}

