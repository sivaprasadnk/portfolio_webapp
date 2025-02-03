import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/is_mobile_platform.dart';
import 'package:spnk/views/widgets/loading_shimmer.dart';

class LoadingAbtMeContainer extends StatelessWidget {
  const LoadingAbtMeContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.8,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 15,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LoadingShimmer.rectangle(
              height: 10,
              width: isMobilePlatform ? context.screenWidth - 20 : 600,
              context: context,
            ),
          );
        },
      ),
    );
  }
}
