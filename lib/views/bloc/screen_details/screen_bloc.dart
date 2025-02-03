import 'package:bloc/bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/screen_details/screen_state.dart';

class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  ScreenBloc() : super(const ScreenState()) {
    on<UpdateScreen>(_updateScreen);
  }

  void _updateScreen(UpdateScreen event, Emitter<ScreenState> emit) {
    emit(state.copyWith(screen: event.screen));
  }
}
