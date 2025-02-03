abstract class ProjectEvent {
  const ProjectEvent();
}

class FetchProjects extends ProjectEvent {}

class ShowPrevIcon extends ProjectEvent {
  final bool showPrev;
  ShowPrevIcon({this.showPrev = false});
}

class ShowNextIcon extends ProjectEvent {
  final bool showNext;
  ShowNextIcon({this.showNext = true});
}
