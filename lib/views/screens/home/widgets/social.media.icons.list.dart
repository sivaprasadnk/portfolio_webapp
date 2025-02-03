import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/screens/home/widgets/social.media.icon.item.dart';

class SocialMediaIconsList extends StatelessWidget {
  const SocialMediaIconsList({
    super.key,
    this.isMobile = false,
  });
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    const double spacing = 15;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    var normalColor = isMobile
        ? kWhiteColor
        : isDarkTheme
            ? kWhiteColor
            : kPrimaryBlueColor;
    normalColor = context.primaryColor;
    return FadeInRight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Container(
          //   height: 3,
          //   width: 50,
          //   decoration: BoxDecoration(
          //     color: context.primaryColor,
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          // ),
          // SocialMediaIconItem(
          //   icon: FontAwesomeIcons.facebook,
          //   url: fbLink,
          //   iconColor: normalColor,
          //   isMobile: isMobile,
          // ),
          // const SizedBox(width: spacing),
          SocialMediaIconItem(
            icon: FontAwesomeIcons.instagram,
            url: instaLink,
            iconColor: normalColor,
            isMobile: isMobile,
          ),
          const SizedBox(width: spacing),
          SocialMediaIconItem(
            icon: FontAwesomeIcons.whatsapp,
            url: whatsappWebLink,
            iconColor: normalColor,
            isMobile: isMobile,
          ),
          const SizedBox(width: spacing),
          SocialMediaIconItem(
            icon: FontAwesomeIcons.linkedin,
            url: linkedInLink,
            iconColor: normalColor,
            isMobile: isMobile,
          ),
          const SizedBox(width: spacing),
          SocialMediaIconItem(
            icon: FontAwesomeIcons.github,
            url: githubLink,
            iconColor: normalColor,
            isMobile: isMobile,
          ),
          const SizedBox(width: spacing),
          SocialMediaIconItem(
            icon: FontAwesomeIcons.dartLang,
            url: pubDevLink,
            iconColor: normalColor,
            isMobile: isMobile,
          ),
          const SizedBox(width: spacing),
          SocialMediaIconItem(
            icon: FontAwesomeIcons.store,
            url: vsCodeThemesLink,
            iconColor: normalColor,
            isMobile: isMobile,
          ),


          // const SizedBox(height: spacing),
          // Container(
          //   width: 3,
          //   height: 200,
          //   decoration: BoxDecoration(
          //     color: context.primaryColor,
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          // ),
        ],
      ),
    );
  }
}
