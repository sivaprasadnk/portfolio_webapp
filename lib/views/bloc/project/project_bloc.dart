import 'package:bloc/bloc.dart';
import 'package:spnk/domain/use_case/get_project_details.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/project/project_event.dart';
import 'package:spnk/views/bloc/project/project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc() : super(const ProjectState()) {
    on<FetchProjects>(_getProjects);
    on<ShowNextIcon>(_showNextIcon);
    on<ShowPrevIcon>(_showPrevIcon);
  }

  Future<void> _getProjects(
    FetchProjects event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final list = await locator<GetProjectDetails>().call();
    emit(state.copyWith(isLoading: false, list: list));
  }

  void _showNextIcon(ShowNextIcon event, Emitter<ProjectState> emit) {
    emit(state.copyWith(showNext: event.showNext));
  }

  void _showPrevIcon(ShowPrevIcon event, Emitter<ProjectState> emit) {
    emit(state.copyWith(showPrev: event.showPrev));
  }
}
