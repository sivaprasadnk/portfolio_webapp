import 'package:flutter/widgets.dart';
import 'package:spnk/views/screens/racing/racing_3d_bridge.dart';

Racing3dBridge createPlatformRacing3dBridge() => _StubRacing3dBridge();

class _StubRacing3dBridge implements Racing3dBridge {
  @override
  bool get isSupported => false;

  @override
  String? mountView() => null;

  @override
  Widget buildView() => const SizedBox.shrink();

  @override
  void setTrackData(String jsonPayload) {}

  @override
  void syncState(String jsonPayload) {}

  @override
  Offset? raycastPaddock(double normX, double normY) => null;

  @override
  void dispose() {}
}
