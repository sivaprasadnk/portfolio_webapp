class ProjectDetails {
  String projName;
  List<String> techStackList;
  List<String> descList;
  // String bgAssetPath;
  String webUrl;
  String playStoreUrl;
  bool isActive;
  ProjectDetails({
    required this.projName,
    required this.techStackList,
    required this.descList,
    // required this.bgAssetPath,
    required this.playStoreUrl,
    required this.webUrl,
    required this.isActive,
  });
}
