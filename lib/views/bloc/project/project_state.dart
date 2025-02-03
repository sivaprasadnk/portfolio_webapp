import 'package:equatable/equatable.dart';
import 'package:spnk/domain/entity/project_details.dart';

class ProjectState extends Equatable {
  final List<ProjectDetails> projectList;
  final bool showNextIcon;
  final bool showPrevIcon;
  final bool isLoading;


  const ProjectState({
    this.projectList = const [],
    this.showNextIcon = true,
    this.showPrevIcon = false,
    this.isLoading = true,
  });

  ProjectState copyWith({
    List<ProjectDetails>? list,
    bool? showNext,
    bool? showPrev,
    bool? isLoading,
  }) {
    return ProjectState(
      projectList: list ?? projectList,
      showNextIcon: showNext ?? showNextIcon,
      showPrevIcon: showPrev ?? showPrevIcon,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        projectList,
        showNextIcon,
        showPrevIcon,
        isLoading,
      ];
}
