import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/yt_downloader/yt_web_helper.dart';
import 'package:web/web.dart' as web;

@JS('spnkYtDownloadBlob')
external bool _spnkYtDownloadBlob(
  JSUint8Array bytes,
  JSString fileName,
  JSString mimeType,
);

@JS('spnkYtTriggerDirectLink')
external bool _spnkYtTriggerDirectLink(
  JSString url,
  JSString fileName,
);

@JS('spnkYtMuxMp4')
external JSPromise<JSUint8Array?> _spnkYtMuxMp4(
  JSUint8Array videoBytes,
  JSUint8Array audioBytes,
);

@JS('spnkYtDecodeToWav')
external JSPromise<JSUint8Array?> _spnkYtDecodeToWav(
  JSUint8Array audioBytes,
);

YtPlatformHelper createYtPlatformHelper() => _WebYtPlatformHelper();

class _WebYtPlatformHelper implements YtPlatformHelper {
  _WebYtPlatformHelper() {
    _ensureBridgeInjected();
  }

  static int _embedCounter = 0;

  @override
  bool get isWeb => true;

  @override
  void configurePageMeta() {
    _ensureBridgeInjected();
    final doc = web.document;
    doc.title = 'YouTube Downloader • SPNK Studio';
    final existingIcon =
        doc.querySelector("link[rel*='icon']") as web.HTMLLinkElement?;
    if (existingIcon != null) {
      existingIcon
        ..type = 'image/svg+xml'
        ..href = 'yt-downloader/favicon.svg?v=1';
    }
  }

  void _ensureBridgeInjected() {
    final doc = web.document;
    if (doc.getElementById('spnk-yt-bridge-script') != null) return;

    final script = doc.createElement('script') as web.HTMLScriptElement
      ..id = 'spnk-yt-bridge-script'
      ..text = r'''
window._spnkToBlobUrl = async function(url, mimeType) {
  var resp = await fetch(url);
  if (!resp.ok) throw new Error('Failed to load ' + url);
  var buf = await resp.arrayBuffer();
  var blob = new Blob([buf], { type: mimeType });
  return URL.createObjectURL(blob);
};

window._spnkEnsureFfmpeg = async function() {
  if (window._spnkFfmpegReady && window._spnkFfmpegInstance) {
    return window._spnkFfmpegInstance;
  }
  if (!window.FFmpegWASM) {
    await new Promise(function(resolve, reject) {
      var existing = document.getElementById('spnk-ffmpeg-umd');
      if (existing && window.FFmpegWASM) {
        resolve();
        return;
      }
      var s = document.createElement('script');
      s.id = 'spnk-ffmpeg-umd';
      s.src = 'https://cdn.jsdelivr.net/npm/@ffmpeg/ffmpeg@0.12.10/dist/umd/ffmpeg.js';
      s.onload = function() { resolve(); };
      s.onerror = function() { reject(new Error('Could not load FFmpeg script')); };
      document.head.appendChild(s);
    });
  }
  var workerUrl = await window._spnkToBlobUrl(
    'https://cdn.jsdelivr.net/npm/@ffmpeg/ffmpeg@0.12.10/dist/umd/814.ffmpeg.js',
    'text/javascript'
  );
  var coreUrl = await window._spnkToBlobUrl(
    'https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.12.6/dist/esm/ffmpeg-core.js',
    'text/javascript'
  );
  var wasmUrl = await window._spnkToBlobUrl(
    'https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.12.6/dist/esm/ffmpeg-core.wasm',
    'application/wasm'
  );
  var ffmpeg = new window.FFmpegWASM.FFmpeg();
  await ffmpeg.load({
    classWorkerURL: workerUrl,
    coreURL: coreUrl,
    wasmURL: wasmUrl
  });
  window._spnkFfmpegInstance = ffmpeg;
  window._spnkFfmpegReady = true;
  return ffmpeg;
};

window.spnkYtDownloadBlob = function(bytes, fileName, mimeType) {
  try {
    var blob = new Blob([bytes], { type: mimeType || 'application/octet-stream' });
    var blobUrl = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = blobUrl;
    a.download = fileName || 'download.bin';
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(function() { URL.revokeObjectURL(blobUrl); }, 20000);
    return true;
  } catch (e) {
    return false;
  }
};

window.spnkYtTriggerDirectLink = function(url, fileName) {
  try {
    var a = document.createElement('a');
    a.href = url;
    if (fileName) a.download = fileName;
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    a.remove();
    return true;
  } catch (e) {
    return false;
  }
};

window.spnkYtMuxMp4 = async function(videoBytes, audioBytes) {
  try {
    var ffmpeg = await window._spnkEnsureFfmpeg();
    var ts = String(Date.now());
    var vName = 'v_' + ts + '.mp4';
    var aName = 'a_' + ts + '.m4a';
    var oName = 'out_' + ts + '.mp4';
    await ffmpeg.writeFile(vName, new Uint8Array(videoBytes));
    await ffmpeg.writeFile(aName, new Uint8Array(audioBytes));
    var code = await ffmpeg.exec([
      '-i', vName,
      '-i', aName,
      '-c', 'copy',
      '-movflags', '+faststart',
      oName
    ]);
    var outData = null;
    if (code === 0) {
      var raw = await ffmpeg.readFile(oName);
      outData = raw instanceof Uint8Array ? raw : new Uint8Array(raw);
    }
    try { await ffmpeg.deleteFile(vName); } catch (_) {}
    try { await ffmpeg.deleteFile(aName); } catch (_) {}
    try { await ffmpeg.deleteFile(oName); } catch (_) {}
    return outData;
  } catch (e) {
    return null;
  }
};

window.spnkYtDecodeToWav = async function(audioBytes) {
  var AudioCtx = window.AudioContext || window.webkitAudioContext;
  if (!AudioCtx) return null;
  var ctx = new AudioCtx();
  try {
    var copy = new Uint8Array(audioBytes.length);
    copy.set(audioBytes);
    var audioBuffer = await ctx.decodeAudioData(copy.buffer);
    var numChannels = Math.min(2, audioBuffer.numberOfChannels);
    var sampleRate = audioBuffer.sampleRate;
    var numFrames = audioBuffer.length;
    var bytesPerSample = 2;
    var blockAlign = numChannels * bytesPerSample;
    var dataSize = numFrames * blockAlign;
    var buffer = new ArrayBuffer(44 + dataSize);
    var view = new DataView(buffer);

    function writeStr(offset, str) {
      for (var i = 0; i < str.length; i++) {
        view.setUint8(offset + i, str.charCodeAt(i));
      }
    }
    writeStr(0, 'RIFF');
    view.setUint32(4, 36 + dataSize, true);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, numChannels, true);
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, sampleRate * blockAlign, true);
    view.setUint16(32, blockAlign, true);
    view.setUint16(34, 16, true);
    writeStr(36, 'data');
    view.setUint32(40, dataSize, true);

    var channels = [];
    for (var c = 0; c < numChannels; c++) {
      channels.push(audioBuffer.getChannelData(c));
    }
    var offset = 44;
    for (var i = 0; i < numFrames; i++) {
      for (var ch = 0; ch < numChannels; ch++) {
        var sample = Math.max(-1, Math.min(1, channels[ch][i]));
        view.setInt16(offset, sample < 0 ? sample * 0x8000 : sample * 0x7FFF, true);
        offset += 2;
      }
    }
    return new Uint8Array(buffer);
  } catch (e) {
    return null;
  } finally {
    try { await ctx.close(); } catch (_) {}
  }
};
''';
    doc.head?.appendChild(script);
  }

  @override
  Future<bool> saveBytesAsFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    _ensureBridgeInjected();
    try {
      return _spnkYtDownloadBlob(
        bytes.toJS,
        fileName.toJS,
        mimeType.toJS,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> triggerDirectDownload({
    required String url,
    required String fileName,
  }) async {
    _ensureBridgeInjected();
    try {
      return _spnkYtTriggerDirectLink(url.toJS, fileName.toJS);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List?> muxMp4VideoAndAudio({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
  }) async {
    _ensureBridgeInjected();
    try {
      final result =
          await _spnkYtMuxMp4(videoBytes.toJS, audioBytes.toJS).toDart;
      return result?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> convertAudioToWav(Uint8List encodedAudioBytes) async {
    _ensureBridgeInjected();
    try {
      final result = await _spnkYtDecodeToWav(encodedAudioBytes.toJS).toDart;
      return result?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  String registerEmbedPlayer({
    required String videoId,
    int startSeconds = 0,
  }) {
    _embedCounter++;
    final viewType = 'spnk-yt-embed-$videoId-$_embedCounter';
    final startQuery = startSeconds > 0 ? '&start=$startSeconds' : '';
    final embedUrl =
        'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&rel=0$startQuery';

    final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..src = embedUrl
      ..allowFullscreen = true
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0'
      ..style.borderRadius = '14px'
      ..style.backgroundColor = '#000000';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iframe,
    );

    return viewType;
  }

  @override
  Widget buildEmbedPlayer(String viewType) {
    return HtmlElementView(viewType: viewType);
  }
}

