import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/qrcode/qr_web_helper.dart';
import 'package:web/web.dart' as web;

@JS('spnkStartCamera')
external JSPromise<JSString> _spnkStartCamera(
  web.HTMLVideoElement video,
  JSString facingMode,
);

@JS('spnkStopCamera')
external void _spnkStopCamera(web.HTMLVideoElement video);

@JS('spnkDecodeVideoFrame')
external JSString _spnkDecodeVideoFrame(web.HTMLVideoElement video);

@JS('spnkPickAndDecodeQrImage')
external JSPromise<JSString> _spnkPickAndDecodeQrImage();

QrPlatformHelper createQrPlatformHelper() => _WebQrPlatformHelper();

class _WebQrPlatformHelper implements QrPlatformHelper {
  _WebQrPlatformHelper() {
    _ensureJsBridgeInjected();
  }

  static int _viewCounter = 0;
  final Map<String, web.HTMLVideoElement> _videoElements = {};

  @override
  bool get isWeb => true;

  void _ensureJsBridgeInjected() {
    final doc = web.document;
    if (doc.getElementById('spnk-jsqr-lib') == null) {
      final jsqrScript = doc.createElement('script') as web.HTMLScriptElement
        ..id = 'spnk-jsqr-lib'
        ..src = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js'
        ..async = true;
      doc.head?.appendChild(jsqrScript);
    }

    if (doc.getElementById('spnk-qr-bridge-script') == null) {
      final bridgeScript = doc.createElement('script') as web.HTMLScriptElement
        ..id = 'spnk-qr-bridge-script'
        ..text = '''
window._spnkScanCanvas = window._spnkScanCanvas || document.createElement('canvas');

window.spnkStartCamera = async function(video, facingMode) {
  try {
    window.spnkStopCamera(video);
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      return '__ERROR__:Camera API is not available in this browser or context (HTTPS required).';
    }
    var stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: { ideal: facingMode || 'environment' },
          width: { ideal: 720 },
          height: { ideal: 720 }
        },
        audio: false
      });
    } catch (_) {
      stream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: false
      });
    }
    video.srcObject = stream;
    video.setAttribute('playsinline', 'true');
    await video.play();
    return 'OK';
  } catch (err) {
    var msg = (err && err.message) ? err.message : String(err);
    if (err && err.name === 'NotAllowedError') {
      return '__ERROR__:Camera permission was denied. Please allow camera access in your browser.';
    }
    if (err && err.name === 'NotFoundError') {
      return '__ERROR__:No camera device found on this device.';
    }
    return '__ERROR__:' + msg;
  }
};

window.spnkStopCamera = function(video) {
  try {
    if (video && video.srcObject) {
      var tracks = video.srcObject.getTracks();
      for (var i = 0; i < tracks.length; i++) {
        tracks[i].stop();
      }
      video.srcObject = null;
    }
  } catch (_) {}
};

window.spnkDecodeVideoFrame = function(video) {
  try {
    if (!video || video.readyState < 2 || !video.videoWidth || !video.videoHeight) {
      return '';
    }
    var canvas = window._spnkScanCanvas;
    var w = video.videoWidth;
    var h = video.videoHeight;
    if (canvas.width !== w) canvas.width = w;
    if (canvas.height !== h) canvas.height = h;
    var ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(video, 0, 0, w, h);
    if (typeof window.jsQR === 'function') {
      var imageData = ctx.getImageData(0, 0, w, h);
      var code = window.jsQR(imageData.data, w, h, { inversionAttempts: 'attemptBoth' });
      if (code && code.data) {
        return String(code.data);
      }
    }
  } catch (_) {}
  return '';
};

window.spnkPickAndDecodeQrImage = function() {
  return new Promise(function(resolve) {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    var settled = false;
    function finish(val) {
      if (!settled) {
        settled = true;
        resolve(val || '');
      }
    }
    input.onchange = function(e) {
      var file = e.target && e.target.files && e.target.files[0];
      if (!file) {
        finish('__CANCELLED__');
        return;
      }
      var reader = new FileReader();
      reader.onerror = function() { finish('__ERROR__:Could not read image file.'); };
      reader.onload = function(ev) {
        var img = new Image();
        img.onerror = function() { finish('__ERROR__:Invalid image file.'); };
        img.onload = async function() {
          try {
            var scales = [1, 0.5, 1.5];
            var canvas = document.createElement('canvas');
            var ctx = canvas.getContext('2d', { willReadFrequently: true });
            for (var i = 0; i < scales.length; i++) {
              var s = scales[i];
              var w = Math.max(1, Math.round(img.naturalWidth * s));
              var h = Math.max(1, Math.round(img.naturalHeight * s));
              if (w > 2200 || h > 2200) {
                var ratio = Math.min(2200 / w, 2200 / h);
                w = Math.round(w * ratio);
                h = Math.round(h * ratio);
              }
              canvas.width = w;
              canvas.height = h;
              ctx.fillStyle = '#FFFFFF';
              ctx.fillRect(0, 0, w, h);
              ctx.drawImage(img, 0, 0, w, h);
              if (typeof window.jsQR === 'function') {
                var imageData = ctx.getImageData(0, 0, w, h);
                var code = window.jsQR(imageData.data, w, h, { inversionAttempts: 'attemptBoth' });
                if (code && code.data) {
                  finish(String(code.data));
                  return;
                }
              }
            }
            if ('BarcodeDetector' in window) {
              try {
                var detector = new window.BarcodeDetector({ formats: ['qr_code'] });
                var barcodes = await detector.detect(img);
                if (barcodes && barcodes.length > 0 && barcodes[0].rawValue) {
                  finish(String(barcodes[0].rawValue));
                  return;
                }
              } catch (_) {}
            }
            finish('__NOT_FOUND__');
          } catch (err) {
            finish('__ERROR__:' + (err && err.message ? err.message : String(err)));
          }
        };
        img.src = ev.target.result;
      };
      reader.readAsDataURL(file);
    };
    input.oncancel = function() {
      finish('__CANCELLED__');
    };
    input.click();
  });
};
''';
      doc.head?.appendChild(bridgeScript);
    }
  }

  @override
  Future<bool> downloadPngBytes(Uint8List pngBytes, String fileName) async {
    try {
      final base64Data = base64Encode(pngBytes);
      final anchor =
          web.document.createElement('a') as web.HTMLAnchorElement
            ..href = 'data:image/png;base64,$base64Data'
            ..download = fileName
            ..style.display = 'none';
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String registerCameraView() {
    _ensureJsBridgeInjected();
    _viewCounter++;
    final viewType = 'spnk-qr-camera-view-$_viewCounter';
    final video = web.document.createElement('video') as web.HTMLVideoElement
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.borderRadius = '12px'
      ..style.backgroundColor = '#000000';
    video.setAttribute('playsinline', 'true');
    video.setAttribute('webkit-playsinline', 'true');

    _videoElements[viewType] = video;

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => video,
    );

    return viewType;
  }

  @override
  Future<String?> startCamera({
    required String viewType,
    required bool useFrontCamera,
  }) async {
    _ensureJsBridgeInjected();
    final video = _videoElements[viewType];
    if (video == null) {
      return 'Camera view not initialized.';
    }
    final facing = useFrontCamera ? 'user' : 'environment';
    final result = (await _spnkStartCamera(video, facing.toJS).toDart).toDart;
    if (result == 'OK') {
      return null;
    }
    if (result.startsWith('__ERROR__:')) {
      return result.substring('__ERROR__:'.length);
    }
    return result;
  }

  @override
  void stopCamera(String viewType) {
    final video = _videoElements[viewType];
    if (video != null) {
      try {
        _spnkStopCamera(video);
      } catch (_) {}
    }
  }

  @override
  String? decodeCurrentVideoFrame(String viewType) {
    final video = _videoElements[viewType];
    if (video == null) return null;
    try {
      final decoded = _spnkDecodeVideoFrame(video).toDart;
      if (decoded.isNotEmpty) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<QrImageScanOutcome> pickAndDecodeImage() async {
    _ensureJsBridgeInjected();
    try {
      final raw = (await _spnkPickAndDecodeQrImage().toDart).toDart;
      if (raw == '__CANCELLED__' || raw.isEmpty) {
        return const QrImageScanOutcome(status: QrImageScanStatus.cancelled);
      }
      if (raw == '__NOT_FOUND__') {
        return const QrImageScanOutcome(status: QrImageScanStatus.notFound);
      }
      if (raw.startsWith('__ERROR__:')) {
        return QrImageScanOutcome(
          status: QrImageScanStatus.error,
          errorMessage: raw.substring('__ERROR__:'.length),
        );
      }
      return QrImageScanOutcome(
        status: QrImageScanStatus.found,
        data: raw,
      );
    } catch (e) {
      return QrImageScanOutcome(
        status: QrImageScanStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Widget buildCameraPreview(String viewType) {
    return HtmlElementView(viewType: viewType);
  }
}

