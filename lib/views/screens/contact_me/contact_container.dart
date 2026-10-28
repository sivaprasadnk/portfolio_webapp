import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/string_extensions.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactContainer extends StatelessWidget {
  const ContactContainer({
    super.key,
    required this.contactDetails,
  });

  final ContactDetails contactDetails;

  Future<void> _handleTap() async {
    GamificationController.instance.addXp(
      25,
      reason: 'Opened Guild Comms: ${contactDetails.title.trim()}!',
      uniqueKey: 'contact_${contactDetails.type}',
    );
    var link = "";
    if (contactDetails.type == 'mobile') {
      final linkList = contactDetails.link.split(',');
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        link = linkList.last.trim();
      } else {
        link = linkList.first.trim();
      }
    } else {
      link = contactDetails.link;
    }
    await launchUrl(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;

        return PortfolioStyledCard(
          width: context.isLargeDevice ? 370 : double.infinity,
          cyberHeader: '~/comms/${contactDetails.type.toLowerCase()}.channel',
          onTap: _handleTap,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          accent.withOpacity(themeState.isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.35)),
                    ),
                    child: AnimateIcon(
                      key: ValueKey(
                          '${contactDetails.iconName}_${accent.value}'),
                      onTap: _handleTap,
                      iconType: context.isLargeDevice
                          ? IconType.animatedOnHover
                          : IconType.continueAnimation,
                      height: 32,
                      width: 32,
                      color: accent,
                      animateIcon: contactDetails.iconName.iconFromString,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+25 XP',
                          style: context.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: accent,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                contactDetails.title.trim(),
                style: context.displaySmall.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contactDetails.details.trim(),
                style: context.bodyMedium.copyWith(
                  fontSize: 17,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
