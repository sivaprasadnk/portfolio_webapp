import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';
import 'package:spnk/views/screens/about_me/loading_abt_me_container.dart';
import 'package:spnk/views/screens/screen_section.dart';
import 'package:spnk/views/widgets/sample_common_widget.dart';
import 'package:typewritertext/typewritertext.dart';

class AboutMeScreen extends StatelessWidget {
  const AboutMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SampleCommonWidget(
      data: '',
      child: ScreenSection(
        title: Screen.aboutMe.screenTitle,
        details: BlocBuilder<AboutMeBloc, AboutMeState>(
          builder: (context, state) {
            final data = SampleCommonWidget.of(context).data;
            return SingleChildScrollView(
              child: SizedBox(
                // width: context.isMobileDevice ? context.screenWidth - 20 : 600,
                width: isMobilePlatform ? double.infinity : double.infinity,
                child: state.isLoading
                    ? const LoadingAbtMeContainer()
                    : TypeWriter.text(
                        state.content,
                        textAlign: TextAlign.justify,
                        duration: const Duration(milliseconds: 22),
                        style: context.displaySmall,
                      ),
                // : Text(
                //   state.content,
                //   textAlign: TextAlign.justify,
                //   style: context.displaySmall,
                // ),
              )
                  .addRightPadding(
                    isMobilePlatform ? 20 : 50,
                  )
                  .addLeftPadding(
                    isMobilePlatform ? 20 : context.screenWidth * 0.09,
                  ),
            );
          },
        ),
        imageName: '',
      ),
    );
  }
}
