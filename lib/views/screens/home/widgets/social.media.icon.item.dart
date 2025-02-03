import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/utils/common_colors.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/widget_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaIconItem extends StatefulWidget {
  const SocialMediaIconItem({
    super.key,
    required this.icon,
    required this.url,
    required this.iconColor,
    required this.isMobile,
  });

  final IconData icon;
  final String url;
  final Color iconColor;
  final bool isMobile;

  @override
  State<SocialMediaIconItem> createState() => _SocialMediaIconItemState();
}

class _SocialMediaIconItemState extends State<SocialMediaIconItem> {
  ///
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    // final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      hoverColor: kTransparentColor,
      splashColor: kTransparentColor,
      highlightColor: kTransparentColor,
      onHover: (val) {
        setState(() {
          isHovering = val;
        });
      },
      child: AnimatedScale(
        scale: isHovering ? 1.5 : 1,
        duration: Duration(milliseconds: 300),
        
        child: FaIcon(
          widget.icon,
          // color: widget.isMobile
          //     ? kWhiteColor
          //     : isHovering
          //         ? Colors.cyan
          //         : isDarkTheme
          //             ? kWhiteColor
          //             : kPrimaryBlueColor,
          color: isHovering ? context.hoverColor : context.primaryColor,
          size: 20,
        ),
      ),
      onTap: () {
        launchUrl(Uri.parse(widget.url));
      },
    ).showCursorOnHover;
  }
}
