import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:spnk/views/screens/christmas/winter_3d_bridge.dart';
import 'package:web/web.dart' as web;

@JS('spnkWinterIsAvailable')
external JSBoolean _spnkWinterIsAvailable();

@JS('spnkWinterMount')
external JSNumber _spnkWinterMount(web.HTMLElement container);

@JS('spnkWinterSyncState')
external void _spnkWinterSyncState(JSNumber id, JSString jsonStr);

@JS('spnkWinterRaycast')
external JSString _spnkWinterRaycast(
  JSNumber id,
  JSNumber normX,
  JSNumber normY,
);

@JS('spnkWinterDispose')
external void _spnkWinterDispose(JSNumber id);

Winter3dBridge createPlatformWinter3dBridge() => _WebWinter3dBridge();

class _WebWinter3dBridge implements Winter3dBridge {
  static int _viewCounter = 0;

  int? _instanceId;
  String? _viewType;
  String? _pendingStateJson;
  bool? _cachedSupported;

  @override
  bool get isSupported {
    if (_cachedSupported != null) return _cachedSupported!;
    try {
      _cachedSupported = _spnkWinterIsAvailable().toDart;
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
    final viewType = 'spnk-winter-3d-canvas-$_viewCounter';

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
            final mountedId = _spnkWinterMount(container).toDartInt;
            if (mountedId > 0) {
              _instanceId = mountedId;
              if (_pendingStateJson != null) {
                _spnkWinterSyncState(mountedId.toJS, _pendingStateJson!.toJS);
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
  void syncState(String jsonPayload) {
    _pendingStateJson = jsonPayload;
    final id = _instanceId;
    if (id == null || id <= 0) return;
    try {
      _spnkWinterSyncState(id.toJS, jsonPayload.toJS);
    } catch (_) {}
  }

  @override
  String raycast(double normX, double normY) {
    final id = _instanceId;
    if (id == null || id <= 0) return '';
    try {
      return _spnkWinterRaycast(id.toJS, normX.toJS, normY.toJS).toDart;
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    final id = _instanceId;
    _instanceId = null;
    if (id != null && id > 0) {
      try {
        _spnkWinterDispose(id.toJS);
      } catch (_) {}
    }
  }
}
