import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/screens/contact_me/contact_container.dart';
import 'package:spnk/views/screens/contact_me/loading_contact_container.dart';

class ContactDetailsListView extends StatelessWidget {
  const ContactDetailsListView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
      builder: (_, state) {
        return SizedBox(
          height: context.isLargeDevice ? 570 : context.screenHeight - 200,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Wrap(
              children: state.isLoading
                  ? [1, 1, 1].map((item) {
                      return const LoadingContactContainer();
                    }).toList()
                  : state.contactDetailList.map((item) {
                      return ContactContainer(contactDetails: item);
                    }).toList(),
            ),
          ),
        );
      },
    )
        .addLeftPadding(
          isMobilePlatform ? 20 : context.screenWidth * 0.09,
        )
        .addRightPadding(
          isMobilePlatform ? 20 : 50,
        );
  }
}
