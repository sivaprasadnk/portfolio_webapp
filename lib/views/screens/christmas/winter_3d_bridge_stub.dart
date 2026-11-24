import 'package:flutter/widgets.dart';
import 'package:spnk/views/screens/christmas/winter_3d_bridge.dart';

Winter3dBridge createPlatformWinter3dBridge() => _StubWinter3dBridge();

class _StubWinter3dBridge implements Winter3dBridge {
  @override
  bool get isSupported => false;

  @override
  String? mountView() => null;

  @override
  Widget buildView() => const SizedBox.shrink();

  @override
  void syncState(String jsonPayload) {}

  @override
  String raycast(double normX, double normY) => '';

  @override
  void dispose() {}
}
