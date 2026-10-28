import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/screens/contact_me/contact_container.dart';
import 'package:spnk/views/screens/contact_me/loading_contact_container.dart';

class ContactDetailsListView extends StatelessWidget {
  const ContactDetailsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
        builder: (_, state) {
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: state.isLoading
                ? List.generate(3, (index) {
                    return const LoadingContactContainer();
                  })
                : List.generate(state.contactDetailList.length, (index) {
                    final item = state.contactDetailList[index];
                    return ContactContainer(contactDetails: item);
                  }),
          );
        },
      ),
    );
  }
}
