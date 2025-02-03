import 'package:spnk/data/data_sources/local_data_source_impl.dart';
import 'package:spnk/data/data_sources/remote_data_source_impl.dart';
import 'package:spnk/domain/entity/about_me_details.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/domain/repository/repository.dart';
import 'package:spnk/utils/locator.dart';

class RepositoryImpl implements Repository {
  RepositoryImpl();

  @override
  Future<List<ContactDetails>> getContactDetails() async {
    final result = await locator<RemoteDataSourceImpl>().getContactDetails();
    return result.fold(
      (data) => data,
      (_) => locator<LocalDataSourceImpl>().getContactDetails(),
    );
  }

  @override
  Future<List<ExperienceDetails>> getExperienceDetails() async {
    final result = await locator<RemoteDataSourceImpl>().getExperienceDetails();
    return result.fold(
      (data) => data,
      (_) => locator<LocalDataSourceImpl>().getExperienceDetails(),
    );
  }

  @override
  Future<List<ProjectDetails>> getProjectDetails() async {
    final result = await locator<RemoteDataSourceImpl>().getProjectDetails();
    return result.fold(
      (data) => data,
      (_) => locator<LocalDataSourceImpl>().getProjectDetails(),
    );
  }

  @override
  Future<AboutMeDetails> getAboutMe() async {
    final result = await locator<RemoteDataSourceImpl>().getAboutMe();
    return result.fold(
      (data) => data,
      (_) => locator<LocalDataSourceImpl>().getAboutMe(),
    );
  }

  @override
  Future<List<SkillDetails>> getSkillsDetails() async {
    final result = await locator<RemoteDataSourceImpl>().getSkillDetails();
    return result.fold(
      (data) => data,
      (_) => locator<LocalDataSourceImpl>().getSkillDetails(),
    );
  }
}
