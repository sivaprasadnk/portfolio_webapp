import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/string_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactContainer extends StatefulWidget {
  const ContactContainer({
    super.key,
    required this.contactDetails,
  });

  final ContactDetails contactDetails;

  @override
  State<ContactContainer> createState() => _ContactContainerState();
}

class _ContactContainerState extends State<ContactContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
          var link = "";
          if (widget.contactDetails.type == 'mobile') {
            final linkList = widget.contactDetails.link.split(',');
            if (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) {
              link = linkList.last.trim();
            } else {
              link = linkList.first.trim();
            }
          } else {
            link = widget.contactDetails.link;
          }
          await launchUrl(Uri.parse(link));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: context.isLargeDevice ? 340 : double.infinity,
          height: context.isLargeDevice ? 240 : 240,
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
              const SizedBox(height: 50),
              // Icon(
              //   widget.contactDetails.iconName.iconFromString,
              //   size: 60,
              //   color: context.primaryColor,
              // ),

              AnimateIcon(
                key: UniqueKey(),
                onTap: () {},
                iconType: context.isLargeDevice
                    ? IconType.animatedOnHover
                    : IconType.continueAnimation,
                height: 60,
                width: 60,
                color: context.primaryColor,
                animateIcon: widget.contactDetails.iconName.iconFromString,
              ),
              const SizedBox(height: 20),
              Text(
                widget.contactDetails.details,
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
