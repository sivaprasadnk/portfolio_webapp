import 'package:spnk/domain/entity/skill_details.dart';

class SkillDetailsModel extends SkillDetails {
  SkillDetailsModel({
    required super.title,
    required super.details,
    required super.iconName,
    required super.index,
    required super.type,
    required super.link,
  });

  factory SkillDetailsModel.fromJson(Map<String, dynamic> json) {
    return SkillDetailsModel(
      title: json['title'],
      details: json['details'].toString().trim(),
      iconName: json['icon_name'],
      index: json['index'],
      type: json['type'],
      link: json['link'],
    );
  }
}
