import 'package:equatable/equatable.dart';
import 'package:spnk/domain/entity/contact_details.dart';

class ContactDetailsState extends Equatable {
  final List<ContactDetails> contactDetailList;
  final bool isLoading;

  const ContactDetailsState({
    this.contactDetailList = const [],
    this.isLoading = true,
  });

  ContactDetailsState copyWith({
    List<ContactDetails>? details,
    bool? isLoading,
  }) {
    return ContactDetailsState(
      contactDetailList: details ?? contactDetailList,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [contactDetailList, isLoading];
}
