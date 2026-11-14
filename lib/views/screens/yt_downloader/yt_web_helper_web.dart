import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/yt_downloader/yt_service.dart';
import 'package:spnk/views/screens/yt_downloader/yt_web_helper.dart';
import 'package:web/web.dart' as web;

@JS('spnkYtFetchStream')
external JSPromise<JSUint8Array> _spnkYtFetchStream(
  JSString url,
  JSNumber expectedBytes,
  JSFunction onProgress,
);

@JS('spnkYtAbortFetch')
external void _spnkYtAbortFetch();

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
window._spnkActiveAbortCtrl = null;

window.spnkYtAbortFetch = function() {
  if (window._spnkActiveAbortCtrl) {
    try { window._spnkActiveAbortCtrl.abort(); } catch (_) {}
    window._spnkActiveAbortCtrl = null;
  }
};

window.spnkYtFetchStream = async function(url, expectedBytes, onProgress) {
  var ctrl = new AbortController();
  window._spnkActiveAbortCtrl = ctrl;
  var CHUNK_SIZE = 4 * 1024 * 1024; // 4 MB Range chunks prevent CDN throttling
  var lastNotify = 0;

  function report(received, total, force) {
    if (!onProgress) return;
    var now = Date.now();
    if (force || now - lastNotify >= 55) {
      lastNotify = now;
      try { onProgress(received, total || 0); } catch (_) {}
    }
  }

  async function readFullStream(resp, knownTotal) {
    if (!resp.body || !resp.body.getReader) {
      var buf = await resp.arrayBuffer();
      var arr = new Uint8Array(buf);
      report(arr.byteLength, arr.byteLength, true);
      return arr;
    }
    var reader = resp.body.getReader();
    var parts = [];
    var received = 0;
    while (true) {
      var step = await reader.read();
      if (step.done) break;
      var val = step.value;
      if (val && val.byteLength > 0) {
        parts.push(val);
        received += val.byteLength;
        report(received, knownTotal || 0, false);
      }
    }
    var merged = new Uint8Array(received);
    var pos = 0;
    for (var i = 0; i < parts.length; i++) {
      merged.set(parts[i], pos);
      pos += parts[i].byteLength;
    }
    report(received, received, true);
    return merged;
  }

  try {
    if (!expectedBytes || expectedBytes <= 0) {
      var singleResp = await fetch(url, { signal: ctrl.signal });
      if (!singleResp.ok) {
        throw new Error('HTTP ' + singleResp.status);
      }
      var clHeader = parseInt(singleResp.headers.get('content-length') || '0', 10);
      return await readFullStream(singleResp, clHeader > 0 ? clHeader : 0);
    }

    var total = expectedBytes;
    var output = null;
    var offset = 0;

    while (offset < total) {
      if (ctrl.signal.aborted) {
        throw new Error('ABORTED');
      }
      var end = Math.min(offset + CHUNK_SIZE - 1, total - 1);
      var resp = await fetch(url, {
        headers: { 'Range': 'bytes=' + offset + '-' + end },
        signal: ctrl.signal
      });
      if (!resp.ok) {
        throw new Error('HTTP ' + resp.status);
      }

      if (offset === 0) {
        if (resp.status === 200) {
          // Server ignored Range header; stream entire body in single pass
          return await readFullStream(resp, total);
        }
        var cr = resp.headers.get('content-range') || '';
        var crMatch = cr.match(/\/(\d+)$/);
        if (crMatch && crMatch[1]) {
          var parsedTotal = parseInt(crMatch[1], 10);
          if (parsedTotal > 0) total = parsedTotal;
        }
        output = new Uint8Array(total);
      }

      if (!resp.body || !resp.body.getReader) {
        var chunkBuf = new Uint8Array(await resp.arrayBuffer());
        if (chunkBuf.byteLength === 0) {
          throw new Error('Unexpected empty chunk');
        }
        output.set(chunkBuf.subarray(0, Math.min(chunkBuf.byteLength, total - offset)), offset);
        offset += chunkBuf.byteLength;
        report(Math.min(offset, total), total, true);
      } else {
        var reader = resp.body.getReader();
        var chunkRead = 0;
        while (true) {
          var step = await reader.read();
          if (step.done) break;
          var val = step.value;
          if (val && val.byteLength > 0) {
            var writable = Math.min(val.byteLength, total - offset);
            if (writable > 0) {
              output.set(val.subarray(0, writable), offset);
            }
            offset += val.byteLength;
            chunkRead += val.byteLength;
            report(Math.min(offset, total), total, false);
          }
        }
        if (chunkRead === 0) {
          throw new Error('Unexpected EOF while streaming');
        }
        report(Math.min(offset, total), total, true);
      }
    }

    return output;
  } catch (err) {
    if (ctrl.signal.aborted || (err && err.name === 'AbortError')) {
      throw new Error('ABORTED');
    }
    throw err;
  } finally {
    if (window._spnkActiveAbortCtrl === ctrl) {
      window._spnkActiveAbortCtrl = null;
    }
  }
};

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
    setTimeout(function() { URL.revokeObjectURL(blobUrl); }, 30000);
    return true;
  } catch (e) {
    return false;
  }
};

window.spnkYtTriggerDirectLink = function(url, fileName) {
  try {
    var dlUrl = url;
    if (fileName && dlUrl.indexOf('title=') === -1) {
      dlUrl += (dlUrl.indexOf('?') === -1 ? '?' : '&') + 'title=' + encodeURIComponent(fileName);
    }
    // Hidden iframe triggers Content-Disposition: attachment download in-place without opening a new tab
    var iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.setAttribute('aria-hidden', 'true');
    iframe.src = dlUrl;
    document.body.appendChild(iframe);
    setTimeout(function() {
      try { iframe.remove(); } catch (_) {}
    }, 90000);
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
  Future<Uint8List?> fetchBytesWithProgress({
    required String url,
    int? expectedBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    _ensureBridgeInjected();
    final progressCallback = ((JSNumber received, JSNumber total) {
      final r = received.toDartInt;
      final t = total.toDartInt;
      onProgress?.call(r, t > 0 ? t : expectedBytes);
    }).toJS;

    try {
      final jsBytes = await _spnkYtFetchStream(
        url.toJS,
        (expectedBytes ?? 0).toJS,
        progressCallback,
      ).toDart;
      return jsBytes.toDart;
    } catch (e) {
      if (e.toString().contains('ABORTED')) {
        throw const YtDownloadCancelledException();
      }
      rethrow;
    }
  }

  @override
  void cancelActiveFetch() {
    _ensureBridgeInjected();
    try {
      _spnkYtAbortFetch();
    } catch (_) {}
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
