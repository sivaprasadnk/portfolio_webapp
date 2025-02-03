import 'package:spnk/utils/screen_type.dart';

abstract class ScreenEvent {
  ScreenEvent();
}

class UpdateScreen extends ScreenEvent {
  final Screen screen;
  UpdateScreen({this.screen = Screen.home});
}
