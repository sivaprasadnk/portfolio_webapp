import 'package:get_it/get_it.dart';
import 'package:spnk/data/data_sources/local_data_source_impl.dart';
import 'package:spnk/data/data_sources/remote_data_source_impl.dart';
import 'package:spnk/data/repository/repository_impl.dart';
import 'package:spnk/domain/use_case/get_about_me.dart';
import 'package:spnk/domain/use_case/get_contact_details.dart';
import 'package:spnk/domain/use_case/get_exp_details.dart';
import 'package:spnk/domain/use_case/get_project_details.dart';
import 'package:spnk/domain/use_case/get_skills_details.dart';

GetIt locator = GetIt.instance;

void setup() {
  locator.registerSingleton<LocalDataSourceImpl>(LocalDataSourceImpl());
  locator.registerSingleton<RemoteDataSourceImpl>(RemoteDataSourceImpl());
  locator.registerSingleton<RepositoryImpl>(RepositoryImpl());
  locator.registerSingleton<GetContactDetails>(GetContactDetails());
  locator.registerSingleton<GetExpDetails>(GetExpDetails());
  locator.registerSingleton<GetAboutMe>(GetAboutMe());
  locator.registerSingleton<GetProjectDetails>(GetProjectDetails());
  locator.registerSingleton<GetSkillsDetails>(GetSkillsDetails());
}
