import 'package:equatable/equatable.dart';
import 'package:spnk/utils/screen_type.dart';

class ScreenState extends Equatable {
  final Screen selectedScreen;

  const ScreenState({
    this.selectedScreen = Screen.home,
  });

  ScreenState copyWith({Screen? screen}) {
    return ScreenState(
      selectedScreen: screen ?? selectedScreen,
    );
  }

  @override
  List<Object?> get props => [selectedScreen];
}
