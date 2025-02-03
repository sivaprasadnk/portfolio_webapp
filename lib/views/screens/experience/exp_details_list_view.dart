import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';
import 'package:spnk/views/screens/experience/exp_container.dart';
import 'package:spnk/views/screens/experience/loading_exp_container.dart';

class ExpDetailsListView extends StatelessWidget {
  const ExpDetailsListView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: context.isLargeDevice ? 570 : context.screenHeight - 200,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Scrollbar(
                child: context.isLargeDevice
                    ? Wrap(
                        children: state.isLoading
                            ? [1, 1, 1]
                                .map(
                                  (_) => const LoadingExpContainer(),
                                )
                                .toList()
                            : state.expList.map((exp) {
                                return ExpContainer(
                                  experience: exp,
                                );
                              }).toList(),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: state.isLoading
                            ? [1, 1, 1]
                                .map(
                                  (_) => const LoadingExpContainer(),
                                )
                                .toList()
                            : state.expList.map((exp) {
                                return ExpContainer(
                                  experience: exp,
                                );
                              }).toList(),
                      ),
              ),
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
