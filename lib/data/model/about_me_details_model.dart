import 'package:spnk/domain/entity/about_me_details.dart';

class AboutMeDetailsModel extends AboutMeDetails {
  AboutMeDetailsModel({
    required super.content,
  });

  factory AboutMeDetailsModel.fromJson(Map<String, dynamic> json) {
    return AboutMeDetailsModel(
      content: json['data'],
    );
  }
}
