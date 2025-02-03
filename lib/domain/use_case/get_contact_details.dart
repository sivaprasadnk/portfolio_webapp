import 'package:spnk/data/repository/repository_impl.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/utils/locator.dart';

class GetContactDetails {
  GetContactDetails();

  Future<List<ContactDetails>> call() {
    return locator<RepositoryImpl>().getContactDetails();
  }
}
