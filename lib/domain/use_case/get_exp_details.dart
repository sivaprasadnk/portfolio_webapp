import 'package:spnk/data/repository/repository_impl.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/utils/locator.dart';

class GetExpDetails {
  GetExpDetails();

  Future<List<ExperienceDetails>> call() {
    return locator<RepositoryImpl>().getExperienceDetails();
  }
}
