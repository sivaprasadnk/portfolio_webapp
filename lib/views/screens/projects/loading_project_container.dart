import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/loading_shimmer.dart';

class LoadingProjectContainer extends StatefulWidget {
  const LoadingProjectContainer({
    super.key,
  });

  @override
  State<LoadingProjectContainer> createState() =>
      _LoadingProjectContainerState();
}

class _LoadingProjectContainerState extends State<LoadingProjectContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 340,
      width: context.isLargeDevice ? 340 : double.infinity,
      margin:
          EdgeInsets.only(bottom: 20, right: context.isLargeDevice ? 20 : 0),
      height: 265,
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
              height: 15,
              width: 75,
              context: context,
            ),
          ),
          Divider(
            color: context.primaryColor,
          ),
          Wrap(
            children: [1, 1, 1, 1].map((tool) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: LoadingShimmer.rectangle(
                  height: 15,
                  width: 50,
                  context: context,
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [1, 1, 1, 1].map((desc) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: LoadingShimmer.rectangle(
                    height: 15,
                    width: 100,
                    context: context,
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
