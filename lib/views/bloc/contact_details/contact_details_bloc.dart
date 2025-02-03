import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/use_case/get_contact_details.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_event.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';

class ContactDetailsBloc
    extends Bloc<ContactDetailsEvent, ContactDetailsState> {

  ContactDetailsBloc()
      : super(const ContactDetailsState()) {
    on(_getContactDetails);
  }

  Future<void> _getContactDetails(
    FetchContactDetails event,
    Emitter<ContactDetailsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final list = await locator<GetContactDetails>().call();
    emit(state.copyWith(isLoading: false, details: list));
  }
}
