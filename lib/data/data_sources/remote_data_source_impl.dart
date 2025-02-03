import 'dart:convert';

// import 'package:dartz/dartz.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spnk/data/data_sources/remote_data_source.dart';
import 'package:spnk/data/model/about_me_details_model.dart';
import 'package:spnk/data/model/contact_details_model.dart';
import 'package:spnk/data/model/experience_details_model.dart';
import 'package:spnk/data/model/project_details_model.dart';
import 'package:spnk/data/model/skill_details_model.dart';
import 'package:spnk/utils/string_constants.dart';

class RemoteDataSourceImpl extends RemoteDataSource {
  RemoteDataSourceImpl();

  @override
  Future<Either<AboutMeDetailsModel, Error>> getAboutMe() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse('${baseUrl}about-me'));
      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        debugPrint('response :$resp');
        return Left(AboutMeDetailsModel.fromJson(resp));
      } else {
        return Right(Error());
      }
    } catch (err) {
      throw Exception('Failed to load About Me details');
    }
    // return aboutMeDetailsContent;
  }

  @override
  Future<Either<List<ContactDetailsModel>, Error>> getContactDetails() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse('${baseUrl}contact-me'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(response.body);
        debugPrint('response :$resp');
        return Left(
          (resp['data'] as List)
              .map((e) => ContactDetailsModel.fromJson(e))
              .toList(),
        );
      } else {
        return Right(Error());
      }
    } catch (err) {
      throw Exception('Failed to load contact details');
    }
  }

  @override
  Future<Either<List<ExperienceDetailsModel>, Error>>
      getExperienceDetails() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse('${baseUrl}experience'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(response.body);
        debugPrint('response :$resp');
        return Left(
          (resp['data'] as List)
              .map((e) => ExperienceDetailsModel.fromJson(e))
              .toList(),
        );
      } else {
        return Right(Error());
      }
    } catch (err) {
      throw Exception('Failed to load exp details');
    }
  }

  @override
  Future<Either<List<ProjectDetailsModel>, Error>> getProjectDetails() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse('${baseUrl}projects'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(response.body);
        debugPrint('response :$resp');
        return Left(
          (resp['data'] as List)
              .map((e) => ProjectDetailsModel.fromJson(e))
              .toList()
              .where((project) => project.isActive)
              .toList(),
        );
      } else {
        return Right(Error());
      }
    } catch (err) {
      throw Exception('Failed to load project details');
    }
  }
  
  @override
  Future<Either<List<SkillDetailsModel>, Error>> getSkillDetails() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri.parse('${baseUrl}my-skills'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(response.body);
        debugPrint('response :$resp');
        return Left(
          (resp['data'] as List)
              .map((e) => SkillDetailsModel.fromJson(e))
              .toList(),
        );
      } else {
        return Right(Error());
      }
    } catch (err) {
      throw Exception('Failed to load skill details');
    }
  }
}
