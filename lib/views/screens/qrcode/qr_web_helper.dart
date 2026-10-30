import 'dart:typed_data';
import 'package:flutter/widgets.dart';

export 'qr_web_helper_stub.dart'
    if (dart.library.js_interop) 'qr_web_helper_web.dart';

abstract class QrPlatformHelper {
  bool get isWeb;

  Future<bool> downloadPngBytes(Uint8List pngBytes, String fileName);

  String registerCameraView();

  Future<String?> startCamera({
    required String viewType,
    required bool useFrontCamera,
  });

  void stopCamera(String viewType);

  String? decodeCurrentVideoFrame(String viewType);

  Future<QrImageScanOutcome> pickAndDecodeImage();

  Widget buildCameraPreview(String viewType);
}

enum QrImageScanStatus {
  found,
  notFound,
  cancelled,
  error,
}

class QrImageScanOutcome {
  const QrImageScanOutcome({
    required this.status,
    this.data,
    this.errorMessage,
  });

  final QrImageScanStatus status;
  final String? data;
  final String? errorMessage;
}

