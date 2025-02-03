import 'package:spnk/domain/entity/experience_details.dart';

class ExperienceDetailsModel extends ExperienceDetails {
  ExperienceDetailsModel({
    required super.order,
    required super.title,
    required super.orgName,
    required super.startDate,
    required super.endDate,
    required super.detailsList,
  });

  factory ExperienceDetailsModel.fromJson(Map<String, dynamic> json) {
    return ExperienceDetailsModel(
      order: json['order'],
      title: json['title'],
      orgName: json['org'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      detailsList: (json['details'] as List).map((e) => e.toString()).toList(),
    );
  }
}
