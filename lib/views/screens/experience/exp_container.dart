import 'package:flutter/material.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class ExpContainer extends StatelessWidget {
  const ExpContainer({super.key, required this.experience});
  final ExperienceDetails experience;
  @override
  Widget build(BuildContext context) {
    final bulletPoint = CircleAvatar(
      radius: 5,
      backgroundColor: context.primaryColor,
    );
    return AnimatedContainer(
      margin: EdgeInsets.only(
        bottom: 20,
        right: context.isLargeDevice ? 20 : 0,
      ),
      duration: const Duration(milliseconds: 200),
      width: context.isLargeDevice ? 340 : double.infinity,
      height: 260,
      decoration: BoxDecoration(
        // color: context.scaffoldColor,
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
            child: Text(
              experience.title,
              style: context.displaySmall,
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
                // const SizedBox(width: 10),
                Text(
                  experience.orgName,
                  style: context.bodyMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "${experience.startDate} - ${experience.endDate}",
                  style: context.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
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
              children: experience.detailsList.map((desc) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bulletPoint,
                      const SizedBox(width: 10),
                      Text(
                        desc,
                        style: context.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // const Spacer(),
          // const SizedBox(height: 5),
        ],
      ),
    );
  }
}
