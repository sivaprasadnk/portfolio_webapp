// import 'package:dartz/dartz.dart';
import 'package:dartz/dartz.dart';
import 'package:spnk/data/model/about_me_details_model.dart';
import 'package:spnk/data/model/contact_details_model.dart';
import 'package:spnk/data/model/experience_details_model.dart';
import 'package:spnk/data/model/project_details_model.dart';
import 'package:spnk/data/model/skill_details_model.dart';

abstract class RemoteDataSource {
  Future<Either<List<ExperienceDetailsModel>, Error>> getExperienceDetails();
  Future<Either<List<ProjectDetailsModel>, Error>> getProjectDetails();
  Future<Either<List<ContactDetailsModel>, Error>> getContactDetails();
  Future<Either<List<SkillDetailsModel>, Error>> getSkillDetails();
  Future<Either<AboutMeDetailsModel, Error>> getAboutMe();
}
