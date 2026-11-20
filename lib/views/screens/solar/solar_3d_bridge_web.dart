import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:spnk/views/screens/solar/solar_3d_bridge.dart';
import 'package:web/web.dart' as web;

@JS('spnkSolarIsAvailable')
external JSBoolean _spnkSolarIsAvailable();

@JS('spnkSolarMount')
external JSNumber _spnkSolarMount(web.HTMLElement container);

@JS('spnkSolarSetSystemData')
external void _spnkSolarSetSystemData(JSNumber id, JSString jsonStr);

@JS('spnkSolarSyncState')
external void _spnkSolarSyncState(JSNumber id, JSString jsonStr);

@JS('spnkSolarRaycast')
external JSString _spnkSolarRaycast(
  JSNumber id,
  JSNumber normX,
  JSNumber normY,
);

@JS('spnkSolarDispose')
external void _spnkSolarDispose(JSNumber id);

Solar3dBridge createPlatformSolar3dBridge() => _WebSolar3dBridge();

class _WebSolar3dBridge implements Solar3dBridge {
  static int _viewCounter = 0;

  int? _instanceId;
  String? _viewType;
  String? _pendingSystemJson;
  bool? _cachedSupported;

  @override
  bool get isSupported {
    if (_cachedSupported != null) return _cachedSupported!;
    try {
      _cachedSupported = _spnkSolarIsAvailable().toDart;
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
    final viewType = 'spnk-solar-3d-canvas-$_viewCounter';

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
            final mountedId = _spnkSolarMount(container).toDartInt;
            if (mountedId > 0) {
              _instanceId = mountedId;
              if (_pendingSystemJson != null) {
                _spnkSolarSetSystemData(
                  mountedId.toJS,
                  _pendingSystemJson!.toJS,
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
  void setSystemData(String jsonPayload) {
    _pendingSystemJson = jsonPayload;
    final id = _instanceId;
    if (id != null && id > 0) {
      try {
        _spnkSolarSetSystemData(id.toJS, jsonPayload.toJS);
      } catch (_) {}
    }
  }

  @override
  void syncState(String jsonPayload) {
    final id = _instanceId;
    if (id == null || id <= 0) return;
    try {
      _spnkSolarSyncState(id.toJS, jsonPayload.toJS);
    } catch (_) {}
  }

  @override
  String raycast(double normX, double normY) {
    final id = _instanceId;
    if (id == null || id <= 0) return '';
    try {
      return _spnkSolarRaycast(id.toJS, normX.toJS, normY.toJS).toDart;
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
        _spnkSolarDispose(id.toJS);
      } catch (_) {}
    }
  }
}
