import 'package:flutter/widgets.dart';

import 'racing_3d_bridge_stub.dart'
    if (dart.library.js_interop) 'racing_3d_bridge_web.dart';

abstract class Racing3dBridge {
  bool get isSupported;
  String? mountView();
  Widget buildView();
  void setTrackData(String jsonPayload);
  void syncState(String jsonPayload);
  Offset? raycastPaddock(double normX, double normY);
  void dispose();
}

Racing3dBridge createRacing3dBridge() => createPlatformRacing3dBridge();
