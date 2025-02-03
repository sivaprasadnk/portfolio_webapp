import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/loading_shimmer.dart';

class LoadingExpContainer extends StatelessWidget {
  const LoadingExpContainer({super.key});
  @override
  Widget build(BuildContext context) {
    final bulletPoint = LoadingShimmer.circle(
      size: 5,
      context: context,
    );
    const double height = 20;
    return Container(
      margin:
          EdgeInsets.only(right: context.isLargeDevice ? 20 : 0, bottom: 20),
      width: context.isLargeDevice ? 340 : double.infinity,
      height: 260,

      decoration: BoxDecoration(
        color: context.scaffoldColor,
        border: Border.all(
          color: context.primaryColor,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: LoadingShimmer.rectangle(
              height: height,
              width: 50,
              context: context,
            ),
          ),
          Divider(
            color: context.primaryColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
              horizontal: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingShimmer.rectangle(
                  height: height,
                  width: 250,
                  context: context,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                LoadingShimmer.rectangle(
                  height: height,
                  width: 50,
                  context: context,
                ),
                const SizedBox(width: 10),
                LoadingShimmer.rectangle(
                  height: height,
                  width: 50,
                  context: context,
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [1, 1, 1].map((desc) {
                return Padding(
                  padding: const EdgeInsets.only(top: height, left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bulletPoint,
                      const SizedBox(width: 10),
                      LoadingShimmer.rectangle(
                        height: height,
                        width: 120,
                        context: context,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
