import 'package:flutter/widgets.dart';

import 'solar_3d_bridge_stub.dart'
    if (dart.library.js_interop) 'solar_3d_bridge_web.dart';

/// Platform abstraction for mounting and driving the Three.js 3D Solar System.
abstract class Solar3dBridge {
  bool get isSupported;
  String? mountView();
  Widget buildView();
  void setSystemData(String jsonPayload);
  void syncState(String jsonPayload);
  String raycast(double normX, double normY);
  void dispose();
}

Solar3dBridge createSolar3dBridge() => createPlatformSolar3dBridge();
