import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';

class SkillsContainer extends StatefulWidget {
  const SkillsContainer({
    super.key,
    required this.skillDetails,
  });

  final SkillDetails skillDetails;

  @override
  State<SkillsContainer> createState() => _SkillsContainerState();
}

class _SkillsContainerState extends State<SkillsContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final icon = 'assets/svg/${widget.skillDetails.iconName}.svg';
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: () async {
          // var link = "";
          // if (widget.skillDetails.type == 'mobile') {
          //   final linkList = widget.skillDetails.link.split(',');
          //   if (defaultTargetPlatform == TargetPlatform.android ||
          //       defaultTargetPlatform == TargetPlatform.iOS) {
          //     link = linkList.last.trim();
          //   } else {
          //     link = linkList.first.trim();
          //   }
          // } else {
          //   link = widget.skillDetails.link;
          // }
          // await launchUrl(Uri.parse(link));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: context.isLargeDevice ? 220 : double.infinity,
          height: 195,
          margin: EdgeInsets.only(
            bottom: 20,
            right: context.isLargeDevice ? 20 : 0,
          ),
          decoration: BoxDecoration(
            border: context.isLargeDevice
                ? _isHovered
                    ? Border.all(color: context.primaryColor)
                    : null
                : Border.all(color: context.primaryColor),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              // Icon(
              //   widget.contactDetails.iconName.iconFromString,
              //   size: 60,
              //   color: context.primaryColor,
              // ),

              SvgPicture.asset(
                icon,
                height: 50,
                width: 50,
                color: context.primaryColor,
                // key: UniqueKey(),
                // onTap: () {},
                // iconType: context.isLargeDevice
                //     ? IconType.animatedOnHover
                //     : IconType.continueAnimation,
                // height: 60,
                // width: 60,
                // color: context.primaryColor,
                // animateIcon: widget.skillDetails.iconName.iconFromString,
              ),
              const SizedBox(height: 20),
              Text(
                widget.skillDetails.title,
                style: context.bodySmall.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
