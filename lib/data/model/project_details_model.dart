import 'package:spnk/domain/entity/project_details.dart';

class ProjectDetailsModel extends ProjectDetails {
  ProjectDetailsModel({
    required super.projName,
    required super.techStackList,
    required super.descList,
    // required super.bgAssetPath,
    required super.playStoreUrl,
    required super.webUrl,
    required super.isActive,
  });

  factory ProjectDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProjectDetailsModel(
      projName: json['name'],
      techStackList:
          (json['tech_stack'] as List).map((e) => e.toString()).toList(),
      descList: (json['desc'] as List).map((e) => e.toString()).toList(),
      playStoreUrl: json['playstore_url'],
      webUrl: json['web_url'],
      isActive: json['is_active'] == "Y",
    );
  }
}
