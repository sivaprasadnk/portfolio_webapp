import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class YtDownloaderPrivacyPolicyScreen extends StatelessWidget {
  const YtDownloaderPrivacyPolicyScreen({super.key});

  static const routeName = '/yt-downloader/privacy-policy';

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileDevice;

    return PortfolioStyleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'YT Downloader • Privacy Policy',
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
            cyberHeader: '~/yt-downloader/privacy_policy.md',
            padding: EdgeInsets.all(isMobile ? 20 : 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy for YT Downloader',
                  style: context.displayMedium.copyWith(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: November 15, 2026',
                  style: context.bodySmall.copyWith(
                    fontSize: 14,
                    color: context.primaryColor.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 18),
                const _PolicyParagraph(
                  'This Privacy Policy describes Our policies and procedures on the collection, use, and disclosure of Your information when You use the YT Downloader mobile and web application (the "Application" or "Service") and tells You about Your privacy rights and how the law protects You.\n\n'
                  'YT Downloader is an on-device media utility application developed and published by Sivaprasad NK. By using the Application, You agree to the practices described in this Privacy Policy.',
                ),
                const _PolicyHeading('1. Interpretation and Definitions'),
                const _PolicyParagraph(
                  '• Application: Refers to YT Downloader (dev.sivaprasadnk.yt_downloader_mobile), the video, audio, thumbnail, and subtitle extractor software program provided by the Developer.\n'
                  '• Developer / We / Us / Our: Refers to Sivaprasad NK, Kerala, India.\n'
                  '• Device: Means any device that can access the Service such as a smartphone, tablet, or computer.\n'
                  '• Personal Data: Any information that relates to an identified or identifiable individual.',
                ),
                const _PolicyHeading('2. Overview & 100% On-Device Processing'),
                const _PolicyParagraph(
                  '• No Personal Data Collected: YT Downloader does not require You to create an account and does not collect, store, sell, or share any personally identifiable information (such as Your name, phone number, email address, contacts, browsing history, or GPS location) on developer-operated servers.\n'
                  '• 100% Local Processing: All URL parsing, stream extraction, audio/video muxing, thumbnail export, closed-caption (.vtt) generation, and file management occur 100% locally on Your Device.',
                ),
                const _PolicyHeading('3. Device Permissions Used'),
                const _PolicyParagraph(
                  'To function reliably as a media utility, YT Downloader requests only essential permissions:\n'
                  '• Internet (android.permission.INTERNET): Used directly by Your Device to fetch public media metadata, download user-requested streams, and check for application updates via Google Play In-App Updates or GitHub Releases.\n'
                  '• Photos / Media / Storage (WRITE_EXTERNAL_STORAGE on Android 9 and below, MediaStore on Android 10+): Used solely when You explicitly save downloaded MP4 videos, JPEG cover art, audio tracks, or subtitles to Your Device\'s Photos/Gallery album (YT Downloader) and Download/YT Downloader directory.',
                ),
                const _PolicyHeading('4. Third-Party Services, Updates & Diagnostics'),
                const _PolicyParagraph(
                  '• No Ads or Tracking SDKs: The Application contains no third-party advertising SDKs and no behavioral analytics or user-tracking SDKs.\n'
                  '• Application Updates: On Android, the Application uses Google Play In-App Updates and queries public GitHub Releases to check for newer versions on launch or when requested in Settings.\n'
                  '• Platform Diagnostics: When installed via Google Play, standard platform services (such as Google Play Services) may automatically collect basic, anonymized diagnostic and crash logs solely to help Us fix bugs and improve app stability.',
                ),
                const _PolicyHeading('5. Data Sharing, Retention & Deletion'),
                const _PolicyParagraph(
                  'We do not sell, trade, rent, or share Your personal data with third parties or advertisers. All downloaded files and local download history are stored strictly on Your Device and can be deleted at any time from the in-app Library tab, Your Device gallery/file manager, or by uninstalling YT Downloader.',
                ),
                const _PolicyHeading("6. Children's Privacy"),
                const _PolicyParagraph(
                  'Our Service is a general-audience utility application and does not knowingly collect personally identifiable information from anyone, including children under the age of 13.',
                ),
                const _PolicyHeading('7. Changes to this Privacy Policy'),
                const _PolicyParagraph(
                  'We may update Our Privacy Policy from time to time by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                ),
                const _PolicyHeading('8. Contact Us'),
                const _PolicyParagraph(
                  'If You have any questions about this Privacy Policy, You can contact Us:\n'
                  '• Developer: Sivaprasad NK\n'
                  '• Email: sivaprasadnk123@gmail.com\n'
                  '• Website: https://sivaprasadnk.dev/yt-downloader\n'
                  '• Privacy Policy URL: https://sivaprasadnk.dev/yt-downloader/privacy-policy',
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
        color: context.primaryColor.withValues(alpha: 0.88),
      ),
    );
  }
}

