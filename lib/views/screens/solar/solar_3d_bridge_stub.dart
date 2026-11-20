import 'package:flutter/widgets.dart';
import 'package:spnk/views/screens/solar/solar_3d_bridge.dart';

Solar3dBridge createPlatformSolar3dBridge() => _StubSolar3dBridge();

class _StubSolar3dBridge implements Solar3dBridge {
  @override
  bool get isSupported => false;

  @override
  String? mountView() => null;

  @override
  Widget buildView() => const SizedBox.shrink();

  @override
  void setSystemData(String jsonPayload) {}

  @override
  void syncState(String jsonPayload) {}

  @override
  String raycast(double normX, double normY) => '';

  @override
  void dispose() {}
}
