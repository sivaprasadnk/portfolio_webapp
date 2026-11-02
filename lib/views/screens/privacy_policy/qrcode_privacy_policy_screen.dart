import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class QrCodePrivacyPolicyScreen extends StatelessWidget {
  const QrCodePrivacyPolicyScreen({super.key});

  static const routeName = '/qrcode/privacy-policy';

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
            'QR Code Studio • Privacy Policy',
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
            cyberHeader: '~/qrcode/privacy_policy.md',
            padding: EdgeInsets.all(isMobile ? 20 : 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy for QR Code Studio',
                  style: context.displayMedium.copyWith(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: November 2, 2026',
                  style: context.bodySmall.copyWith(
                    fontSize: 14,
                    color: context.primaryColor.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 18),
                const _PolicyParagraph(
                  'This Privacy Policy describes Our policies and procedures on the collection, use, and disclosure of Your information when You use the QR Code Studio mobile and web application (the "Application" or "Service") and tells You about Your privacy rights and how the law protects You.\n\n'
                  'QR Code Studio is a QR code generator, customizer, and scanner utility application developed and published by Sivaprasad NK. By using the Application, You agree to the practices described in this Privacy Policy.',
                ),
                const _PolicyHeading('1. Interpretation and Definitions'),
                const _PolicyParagraph(
                  '• Application: Refers to QR Code Studio (dev.sivaprasadnk.qr_code_studio_mobile), the QR code generator and scanner software program provided by the Developer.\n'
                  '• Developer / We / Us / Our: Refers to Sivaprasad NK, Kerala, India.\n'
                  '• Device: Means any device that can access the Service such as a smartphone, tablet, or computer.\n'
                  '• Personal Data: Any information that relates to an identified or identifiable individual.',
                ),
                const _PolicyHeading('2. Collecting and Using Your Data'),
                const _PolicyParagraph(
                  '• No Personal Data Collected: QR Code Studio does not require You to create an account and does not collect, store, sell, or share any personally identifiable information (such as Your name, phone number, email address, contacts, or GPS location) on external servers.\n'
                  '• 100% On-Device QR Generation & Scanning: All QR codes You generate (including text, URLs, custom patterns, corner eye styles, and color palettes) and all QR codes You scan (via live camera or uploaded images) are processed 100% locally on Your Device. None of the text, links, or images You enter or scan are ever uploaded or transmitted to any external server.',
                ),
                const _PolicyHeading('3. Device Permissions Used'),
                const _PolicyParagraph(
                  'To function reliably as a QR code generator and scanner utility, QR Code Studio may request standard OS permissions:\n'
                  '• Camera (android.permission.CAMERA / NSCameraUsageDescription): Used strictly to scan QR codes in real time through the in-app camera viewfinder and to control the camera torch/flashlight during scanning. Camera frames are analyzed locally in memory and are never recorded, stored, or transmitted.\n'
                  '• Photo Library / Media Storage (WRITE_EXTERNAL_STORAGE on Android 9 and below, system photo picker / gallery access on Android 10+ and iOS): Used only when You explicitly tap Save to Gallery to save a generated 1024×1024 PNG QR image to Your Device, or when You tap Upload Image to decode a QR code from an image You select.',
                ),
                const _PolicyHeading('4. Diagnostic & Usage Data'),
                const _PolicyParagraph(
                  'When You access the Application installed via Google Play, standard platform services (such as Google Play Services) may automatically collect basic, anonymized diagnostic and crash logs (such as device model, OS version, and crash stack traces) solely to help Us fix bugs and improve app stability.',
                ),
                const _PolicyHeading('5. Data Sharing, Retention & Deletion'),
                const _PolicyParagraph(
                  'We do not sell, trade, rent, or share Your personal data with third parties or advertisers. The Application contains no third-party advertising SDKs and no user-tracking SDKs. Any QR images You explicitly save to Your Device gallery remain under Your full control and can be deleted at any time from Your gallery or by uninstalling QR Code Studio.',
                ),
                const _PolicyHeading("6. Children's Privacy"),
                const _PolicyParagraph(
                  'Our Service is a general-audience utility application and does not knowingly collect personally identifiable information from anyone, including children under the age of 13.',
                ),
                const _PolicyHeading('7. External Links in Scanned QR Codes'),
                const _PolicyParagraph(
                  'When You scan a QR code containing a web URL and tap Open URL, the link opens in Your Device\'s default browser at Your direction. We advise You to review the URL and Privacy Policy of any third-party website You visit.',
                ),
                const _PolicyHeading('8. Changes to this Privacy Policy'),
                const _PolicyParagraph(
                  'We may update Our Privacy Policy from time to time by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                ),
                const _PolicyHeading('9. Contact Us'),
                const _PolicyParagraph(
                  'If You have any questions about this Privacy Policy, You can contact Us:\n'
                  '• Email: sivaprasadnk123@gmail.com\n'
                  '• Website: https://sivaprasadnk.dev/qrcode\n'
                  '• Privacy Policy URL: https://sivaprasadnk.dev/qrcode/privacy-policy',
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

