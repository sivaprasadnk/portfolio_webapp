import 'package:flutter/widgets.dart';

import 'winter_3d_bridge_stub.dart'
    if (dart.library.js_interop) 'winter_3d_bridge_web.dart';

/// Platform abstraction for mounting and driving the Three.js 3D Winter Village.
abstract class Winter3dBridge {
  bool get isSupported;
  String? mountView();
  Widget buildView();
  void syncState(String jsonPayload);
  String raycast(double normX, double normY);
  void dispose();
}

Winter3dBridge createWinter3dBridge() => createPlatformWinter3dBridge();
