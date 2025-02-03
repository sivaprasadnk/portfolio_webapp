import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';
import 'package:spnk/views/screens/skills/loading_skills_container.dart';
import 'package:spnk/views/screens/skills/skills_container.dart';

class SkillDetailsListView extends StatelessWidget {
  const SkillDetailsListView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkillDetailsBloc, SkillsState>(
      builder: (_, state) {
        return SizedBox(
          height: context.isLargeDevice ? 570 : context.screenHeight - 200,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Wrap(
              children: state.isLoading
                  ? [1, 1, 1].map((item) {
                      return const LoadingSkillsContainer();
                    }).toList()
                  : state.skillDetails.map((item) {
                      return SkillsContainer(skillDetails: item);
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
