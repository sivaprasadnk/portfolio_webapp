import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class SpVideoSaverPrivacyPolicyScreen extends StatelessWidget {
  const SpVideoSaverPrivacyPolicyScreen({super.key});

  static const routeName = '/sp-video-saver/privacy-policy';

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
            'SP Video Saver • Privacy Policy',
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
            cyberHeader: '~/sp-video-saver/privacy_policy.md',
            padding: EdgeInsets.all(isMobile ? 20 : 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy for SP Video Saver / Downloader',
                  style: context.displayMedium.copyWith(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Effective Date: November 23, 2026',
                  style: context.bodySmall.copyWith(
                    fontSize: 14,
                    color: context.primaryColor.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 18),
                const _PolicyHeading('1. Overview'),
                const _PolicyParagraph(
                  'SP Video Saver / Downloader (dev.sivaprasadnk.universal_video_downloader_mobile) is an on-device mobile media utility for inspecting and saving open, Creative Commons, user-owned, and direct video and audio files. We respect your privacy and designed the application so that all link detection, stream downloading, Gallery export, and offline library management happen locally on your device.',
                ),
                const _PolicyHeading('2. Information Collection and Use'),
                const _PolicyParagraph(
                  'We do not collect, store, log, transmit, or share any personal information, usage analytics, or download history on any developer-operated servers. No account registration or sign-in is required.',
                ),
                const _PolicyHeading('3. Device Permissions'),
                const _PolicyParagraph(
                  'SP Video Saver / Downloader requests only the permissions strictly necessary for core app functionality:\n'
                  '• Internet (android.permission.INTERNET): Used directly on your device to inspect user-submitted or shared media URLs and download requested video or audio files.\n'
                  '• Storage / Media Access (WRITE_EXTERNAL_STORAGE on Android 9 / API 29 and below, and scoped MediaStore write access on Android 10+): Used solely when exporting saved videos and media files to your device\'s Photos/Gallery album (SP Video Saver) and public Downloads folder (Download/SP Video Saver).',
                ),
                const _PolicyHeading(
                  '4. External Link Sharing, Deep Links & Clipboard Detection',
                ),
                const _PolicyParagraph(
                  '• Share Sheet & Deep Links: When you share a link from another app via the Android Share Sheet or open a spvideosaver:// link, the URL is processed locally on your device to detect downloadable streams.\n'
                  '• Clipboard Detection (Optional): When enabled in Settings, the app checks the clipboard locally upon returning to the foreground only to detect valid media URLs for your convenience. Clipboard contents are never uploaded or stored externally.',
                ),
                const _PolicyHeading('5. Third-Party Services & Advertisements'),
                const _PolicyParagraph(
                  '• The app contains no third-party advertising SDKs.\n'
                  '• The app contains no behavioral analytics, telemetry, or tracking SDKs.\n'
                  '• Network requests are made directly from your device only to the media URLs you choose to inspect or download.',
                ),
                const _PolicyHeading("6. Children's Privacy"),
                const _PolicyParagraph(
                  'SP Video Saver / Downloader does not knowingly collect any personal information from anyone, including children under the age of 13.',
                ),
                const _PolicyHeading('7. Changes to This Privacy Policy'),
                const _PolicyParagraph(
                  'We may update this Privacy Policy from time to time. Any updates will be posted on this page with an updated effective date.',
                ),
                const _PolicyHeading('8. Contact Us'),
                const _PolicyParagraph(
                  'If you have any questions about this Privacy Policy, please contact:\n'
                  '• Developer: Sivaprasad NK\n'
                  '• Email: sivaprasadnk123@gmail.com\n'
                  '• Website: https://sivaprasadnk.dev\n'
                  '• Privacy Policy URL: https://sivaprasadnk.dev/sp-video-saver/privacy-policy',
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
