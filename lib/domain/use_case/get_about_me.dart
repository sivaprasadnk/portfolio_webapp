import 'package:spnk/data/repository/repository_impl.dart';
import 'package:spnk/domain/entity/about_me_details.dart';
import 'package:spnk/utils/locator.dart';

class GetAboutMe {
  GetAboutMe();

  Future<AboutMeDetails> call() async {
    return locator<RepositoryImpl>().getAboutMe();
  }
}
