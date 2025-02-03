class ExperienceDetails {
  String title;
  String orgName;
  String startDate;
  String endDate;
  int order;
  List<String> detailsList;
  ExperienceDetails({
    required this.order,
    required this.title,
    required this.orgName,
    required this.startDate,
    required this.endDate,
    required this.detailsList,
  });
}
