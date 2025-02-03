import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/loading_shimmer.dart';

class LoadingSkillsContainer extends StatelessWidget {
  const LoadingSkillsContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isLargeDevice ? 280 : double.infinity,
      height: 205,
      margin: EdgeInsets.only(
        bottom: 20,
        right: context.isLargeDevice ? 20 : 0,
      ),
      decoration: BoxDecoration(
        color: context.scaffoldColor,
        border: Border.all(
          color: context.scaffoldColor,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 75),
          LoadingShimmer.circle(size: 40, context: context),
          const SizedBox(height: 20),
          LoadingShimmer.rectangle(
            height: 20,
            width: 150,
            context: context,
          ),
        ],
      ),
    );
  }
}
