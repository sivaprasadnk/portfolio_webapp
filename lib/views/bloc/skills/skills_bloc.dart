import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/use_case/get_skills_details.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/skills/skills_event.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';

class SkillDetailsBloc extends Bloc<SkillDetailsEvent, SkillsState> {
  SkillDetailsBloc() : super(const SkillsState()) {
    on(_getSkillDetails);
  }

  Future<void> _getSkillDetails(
    FetchSkillDetailsEvent event,
    Emitter<SkillsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final list = await locator<GetSkillsDetails>().call();
    emit(state.copyWith(isLoading: false, details: list));
  }
}
