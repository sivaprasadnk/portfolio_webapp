import 'package:spnk/domain/entity/contact_details.dart';

class ContactDetailsModel extends ContactDetails {
  ContactDetailsModel({
    required super.title,
    required super.details,
    required super.iconName,
    required super.index,
    required super.type,
    required super.link,
  });

  factory ContactDetailsModel.fromJson(Map<String, dynamic> json) {
    return ContactDetailsModel(
      title: json['title'],
      details: json['details'].toString().trim(),
      iconName: json['icon_name'],
      index: json['index'],
      type: json['type'],
      link: json['link'],
    );
  }
}
