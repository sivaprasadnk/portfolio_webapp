import 'package:spnk/data/constants.dart';
import 'package:spnk/data/data_sources/local_data_source.dart';
import 'package:spnk/data/model/about_me_details_model.dart';
import 'package:spnk/data/model/contact_details_model.dart';
import 'package:spnk/data/model/experience_details_model.dart';
import 'package:spnk/data/model/project_details_model.dart';
import 'package:spnk/data/model/skill_details_model.dart';

class LocalDataSourceImpl implements LocalDataSource {
  LocalDataSourceImpl();

  @override
  Future<List<ExperienceDetailsModel>> getExperienceDetails() async {
    return expDetailsList;
  }

  @override
  List<ContactDetailsModel> getContactDetails() {
    return contactDetailsList;
  }

  @override
  List<ProjectDetailsModel> getProjectDetails() {
    return projectList;
  }

  @override
  AboutMeDetailsModel getAboutMe() {
    return aboutMeDetailsContent;
  }

  @override
  List<SkillDetailsModel> getSkillDetails() {
    return skillsList;
  }
}
