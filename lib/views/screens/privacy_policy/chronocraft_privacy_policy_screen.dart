import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class ChronoCraftPrivacyPolicyScreen extends StatelessWidget {
  const ChronoCraftPrivacyPolicyScreen({super.key});

  static const routeName = '/chronocraft/privacy-policy';

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileDevice;

    return PortfolioStyleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'ChronoCraft • Privacy Policy',
            style: context.displaySmall.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : context.screenWidth * 0.14,
            vertical: 24,
          ),
          child: PortfolioStyledCard(
            width: double.infinity,
            cyberHeader: '~/chronocraft/privacy_policy.md',
            padding: EdgeInsets.all(isMobile ? 20 : 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy for ChronoCraft',
                  style: context.displayMedium.copyWith(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: October 29, 2026',
                  style: context.bodySmall.copyWith(
                    fontSize: 14,
                    color: context.primaryColor.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 18),
                const _PolicyParagraph(
                  'This Privacy Policy describes Our policies and procedures on the collection, use, and disclosure of Your information when You use the ChronoCraft mobile application (the "Application" or "Service") and tells You about Your privacy rights and how the law protects You.\n\n'
                  'ChronoCraft is a clock, alarm, world clock, timer, and stopwatch utility application developed and published by Sivaprasad NK. By using the Application, You agree to the practices described in this Privacy Policy.',
                ),
                const _PolicyHeading('1. Interpretation and Definitions'),
                const _PolicyParagraph(
                  '• Application: Refers to ChronoCraft, the clock, alarm, timer, and stopwatch software program provided by the Developer.\n'
                  '• Developer / We / Us / Our: Refers to Sivaprasad NK, Kerala, India.\n'
                  '• Device: Means any device that can access the Service such as a smartphone, tablet, or wearable device.\n'
                  '• Personal Data: Any information that relates to an identified or identifiable individual.',
                ),
                const _PolicyHeading('2. Collecting and Using Your Data'),
                const _PolicyParagraph(
                  '• No Personal Data Collected: ChronoCraft does not require You to create an account and does not collect, store, sell, or share any personally identifiable information (such as Your name, phone number, email address, contacts, or GPS location) on external servers.\n'
                  '• Locally Stored App Data: All clock configurations, alarms, alarm labels, timers, stopwatch laps, selected world clock time zones, and theme/display preferences are stored locally on Your Device. This data never leaves Your Device.',
                ),
                const _PolicyHeading('3. Device Permissions Used'),
                const _PolicyParagraph(
                  'To function reliably as a clock, alarm, and timer utility, ChronoCraft may request standard OS permissions:\n'
                  '• Exact Alarms (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM): Used strictly to trigger Your scheduled alarms and countdown timers at the exact time You specify.\n'
                  '• Notifications & Full-Screen Intent (POST_NOTIFICATIONS / USE_FULL_SCREEN_INTENT): Used to display active timer progress and alarm alerts when the screen is locked.\n'
                  '• Foreground Service & Wake Lock (FOREGROUND_SERVICE / WAKE_LOCK): Used to keep active timers, stopwatches, and ringing alarms running reliably.\n'
                  '• Receive Boot Completed (RECEIVE_BOOT_COMPLETED): Used to automatically reschedule enabled alarms after Your Device restarts.\n'
                  '• Vibration & Audio Settings (VIBRATE): Used to play alarm tones and vibration patterns.',
                ),
                const _PolicyHeading('4. Diagnostic & Usage Data'),
                const _PolicyParagraph(
                  'When You access the Application installed via Google Play, standard platform services (such as Google Play Services) may automatically collect basic, anonymized diagnostic and crash logs (such as device model, OS version, and crash stack traces) solely to help Us fix bugs and improve app stability.',
                ),
                const _PolicyHeading('5. Data Sharing, Retention & Deletion'),
                const _PolicyParagraph(
                  'We do not sell, trade, rent, or share Your personal data with third parties or advertisers. Because Your alarms, timers, and preferences are stored locally on Your Device, You can delete all data at any time by deleting items inside the ChronoCraft app or clearing the app storage / uninstalling ChronoCraft from Your Device.',
                ),
                const _PolicyHeading("6. Children's Privacy"),
                const _PolicyParagraph(
                  'Our Service is a general-audience timekeeping utility and does not knowingly collect personally identifiable information from anyone, including children under the age of 13.',
                ),
                const _PolicyHeading('7. Changes to this Privacy Policy'),
                const _PolicyParagraph(
                  'We may update Our Privacy Policy from time to time by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                ),
                const _PolicyHeading('8. Contact Us'),
                const _PolicyParagraph(
                  'If You have any questions about this Privacy Policy, You can contact Us:\n'
                  '• Email: sivaprasadnk123@gmail.com\n'
                  '• Website: https://sivaprasadnk.dev/\n'
                  '• Privacy Policy URL: https://sivaprasadnk.dev/chronocraft/privacy-policy',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyHeading extends StatelessWidget {
  const _PolicyHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        text,
        style: context.displaySmall.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.bodyMedium.copyWith(
        fontSize: 16,
        height: 1.55,
        color: context.primaryColor.withOpacity(0.88),
      ),
    );
  }
}

