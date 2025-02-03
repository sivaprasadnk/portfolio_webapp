import 'package:spnk/data/repository/repository_impl.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/utils/locator.dart';

class GetProjectDetails {
  GetProjectDetails();

  Future<List<ProjectDetails>> call() {
    return locator<RepositoryImpl>().getProjectDetails();
  }
}
