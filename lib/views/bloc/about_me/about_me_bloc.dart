import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/use_case/get_about_me.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/about_me/about_me_event.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';

class AboutMeBloc extends Bloc<AboutMeEvent, AboutMeState> {
  AboutMeBloc() : super(const AboutMeState()) {
    on(onAboutMe);
  }

  Future<void> onAboutMe(FetchAboutMe event, Emitter<AboutMeState> emit) async {
    emit(state.copyWith(isLoading: true));
    final details = await locator<GetAboutMe>().call();
    emit(state.copyWith(isLoading: false, content: details.content));
  }
}
