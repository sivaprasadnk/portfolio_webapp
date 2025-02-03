import 'package:spnk/data/repository/repository_impl.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/locator.dart';

class GetSkillsDetails {
  GetSkillsDetails();

  Future<List<SkillDetails>> call() {
    return locator<RepositoryImpl>().getSkillsDetails();
  }
}
