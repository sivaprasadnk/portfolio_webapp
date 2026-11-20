import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:spnk/views/screens/racing/racing_3d_bridge.dart';
import 'package:web/web.dart' as web;

@JS('spnk3dIsAvailable')
external JSBoolean _spnk3dIsAvailable();

@JS('spnk3dMount')
external JSNumber _spnk3dMount(web.HTMLElement container);

@JS('spnk3dSetTrackData')
external void _spnk3dSetTrackData(JSNumber id, JSString jsonStr);

@JS('spnk3dSyncState')
external void _spnk3dSyncState(JSNumber id, JSString jsonStr);

@JS('spnk3dRaycastPaddock')
external JSString _spnk3dRaycastPaddock(
  JSNumber id,
  JSNumber normX,
  JSNumber normY,
);

@JS('spnk3dDispose')
external void _spnk3dDispose(JSNumber id);

Racing3dBridge createPlatformRacing3dBridge() => _WebRacing3dBridge();

class _WebRacing3dBridge implements Racing3dBridge {
  static int _viewCounter = 0;

  int? _instanceId;
  String? _viewType;
  String? _pendingTrackJson;
  bool? _cachedSupported;

  @override
  bool get isSupported {
    if (_cachedSupported != null) return _cachedSupported!;
    try {
      _cachedSupported = _spnk3dIsAvailable().toDart;
    } catch (_) {
      _cachedSupported = false;
    }
    return _cachedSupported!;
  }

  @override
  String? mountView() {
    if (!isSupported) return null;
    if (_viewType != null) return _viewType;

    _viewCounter++;
    final viewType = 'spnk-racing-3d-canvas-$_viewCounter';

    final container = web.document.createElement('div') as web.HTMLDivElement
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'relative'
      ..style.overflow = 'hidden'
      ..style.pointerEvents = 'none';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        if (_instanceId == null) {
          try {
            final mountedId = _spnk3dMount(container).toDartInt;
            if (mountedId > 0) {
              _instanceId = mountedId;
              if (_pendingTrackJson != null) {
                _spnk3dSetTrackData(
                  mountedId.toJS,
                  _pendingTrackJson!.toJS,
                );
              }
            }
          } catch (_) {}
        }
        return container;
      },
    );

    _viewType = viewType;
    return viewType;
  }

  @override
  Widget buildView() {
    final vt = _viewType ?? mountView();
    if (vt == null) return const SizedBox.shrink();
    return HtmlElementView(viewType: vt);
  }

  @override
  void setTrackData(String jsonPayload) {
    _pendingTrackJson = jsonPayload;
    final id = _instanceId;
    if (id != null && id > 0) {
      try {
        _spnk3dSetTrackData(id.toJS, jsonPayload.toJS);
      } catch (_) {}
    }
  }

  @override
  void syncState(String jsonPayload) {
    final id = _instanceId;
    if (id == null || id <= 0) return;
    try {
      _spnk3dSyncState(id.toJS, jsonPayload.toJS);
    } catch (_) {}
  }

  @override
  Offset? raycastPaddock(double normX, double normY) {
    final id = _instanceId;
    if (id == null || id <= 0) return null;
    try {
      final raw = _spnk3dRaycastPaddock(id.toJS, normX.toJS, normY.toJS).toDart;
      if (raw.isEmpty) return null;
      final parts = raw.split(',');
      if (parts.length != 2) return null;
      final wx = double.tryParse(parts[0]);
      final wy = double.tryParse(parts[1]);
      if (wx == null || wy == null) return null;
      return Offset(wx, wy);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    final id = _instanceId;
    _instanceId = null;
    if (id != null && id > 0) {
      try {
        _spnk3dDispose(id.toJS);
      } catch (_) {}
    }
  }
}
