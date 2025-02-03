import 'package:spnk/data/model/about_me_details_model.dart';
import 'package:spnk/data/model/contact_details_model.dart';
import 'package:spnk/data/model/experience_details_model.dart';
import 'package:spnk/data/model/project_details_model.dart';
import 'package:spnk/data/model/skill_details_model.dart';

abstract class LocalDataSource {
  Future<List<ExperienceDetailsModel>> getExperienceDetails();
  List<ProjectDetailsModel> getProjectDetails();
  List<ContactDetailsModel> getContactDetails();
  List<SkillDetailsModel> getSkillDetails();
  AboutMeDetailsModel getAboutMe();
}
