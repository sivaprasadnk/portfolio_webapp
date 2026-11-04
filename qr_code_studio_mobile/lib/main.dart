import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QrCodeStudioApp());
}

enum AppVisualStyle {
  glass('Glass', Icons.auto_awesome_rounded),
  bento('Bento', Icons.grid_view_rounded),
  cyber('Cyber', Icons.terminal_rounded);

  const AppVisualStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum DynamicBackgroundStyle {
  aurora('Aurora Orbs', Icons.blur_on_rounded),
  cyberGrid('Cyber Grid', Icons.grid_4x4_rounded),
  starfield('Cosmic Stars', Icons.auto_awesome_mosaic_rounded),
  neonWaves('Neon Waves', Icons.waves_rounded),
  particles('Constellation', Icons.hub_rounded),
  minimal('Minimal Solid', Icons.check_box_outline_blank_rounded);

  const DynamicBackgroundStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum BackgroundPalette {
  themeDefault(
    'Theme Auto',
    Color(0xFF0B0F19),
    Color(0xFFF3F6FC),
    Color(0xFF38BDF8),
    Color(0xFFA855F7),
  ),
  midnightCyan(
    'Midnight Cyan',
    Color(0xFF050B16),
    Color(0xFFEFF6FF),
    Color(0xFF00F0FF),
    Color(0xFF3B82F6),
  ),
  emeraldMatrix(
    'Emerald Matrix',
    Color(0xFF04120D),
    Color(0xFFECFDF5),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
  ),
  royalAmethyst(
    'Royal Amethyst',
    Color(0xFF11071F),
    Color(0xFFF5F3FF),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ),
  sunsetEmber(
    'Sunset Ember',
    Color(0xFF18080C),
    Color(0xFFFFF7ED),
    Color(0xFFF97316),
    Color(0xFFF43F5E),
  ),
  deepOcean(
    'Deep Ocean',
    Color(0xFF04101E),
    Color(0xFFF0F9FF),
    Color(0xFF0EA5E9),
    Color(0xFF2DD4BF),
  );

  const BackgroundPalette(
    this.label,
    this.darkBg,
    this.lightBg,
    this.primaryGlow,
    this.secondaryGlow,
  );

  final String label;
  final Color darkBg;
  final Color lightBg;
  final Color primaryGlow;
  final Color secondaryGlow;
}

class QrCodeStudioApp extends StatefulWidget {
  const QrCodeStudioApp({super.key});

  @override
  State<QrCodeStudioApp> createState() => _QrCodeStudioAppState();
}

class _QrCodeStudioAppState extends State<QrCodeStudioApp> {
  bool _isDark = true;
  AppVisualStyle _visualStyle = AppVisualStyle.glass;
  DynamicBackgroundStyle _bgStyle = DynamicBackgroundStyle.aurora;
  BackgroundPalette _bgPalette = BackgroundPalette.themeDefault;

  Color get _scaffoldBg {
    if (_bgPalette != BackgroundPalette.themeDefault) {
      return _isDark ? _bgPalette.darkBg : _bgPalette.lightBg;
    }
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return _isDark ? const Color(0xFF0B0F19) : const Color(0xFFF3F6FC);
      case AppVisualStyle.bento:
        return _isDark ? const Color(0xFF09090B) : const Color(0xFFF7F7F5);
      case AppVisualStyle.cyber:
        return _isDark ? const Color(0xFF050811) : const Color(0xFFEEF2F6);
    }
  }

  Color get _primaryText {
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
      case AppVisualStyle.bento:
        return _isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
      case AppVisualStyle.cyber:
        return _isDark ? const Color(0xFFE2F1FF) : const Color(0xFF0B1324);
    }
  }

  Color get _accent {
    if (_bgPalette != BackgroundPalette.themeDefault) {
      return _bgPalette.primaryGlow;
    }
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return _isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5);
      case AppVisualStyle.bento:
        return _isDark ? const Color(0xFF10B981) : const Color(0xFF18181B);
      case AppVisualStyle.cyber:
        return _isDark ? const Color(0xFF00F0FF) : const Color(0xFF0077B6);
    }
  }

  Color get _secondaryAccent {
    if (_bgPalette != BackgroundPalette.themeDefault) {
      return _bgPalette.secondaryGlow;
    }
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return _isDark ? const Color(0xFFA855F7) : const Color(0xFF06B6D4);
      case AppVisualStyle.bento:
        return _isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
      case AppVisualStyle.cyber:
        return _isDark ? const Color(0xFFFF2A85) : const Color(0xFFD90429);
    }
  }

  Color get _cardSurface {
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return _isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.78);
      case AppVisualStyle.bento:
        return _isDark
            ? const Color(0xFF141418).withValues(alpha: 0.88)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.90);
      case AppVisualStyle.cyber:
        return _isDark
            ? const Color(0xFF0B1324).withValues(alpha: 0.88)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.92);
    }
  }

  Color get _cardBorder {
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return _isDark
            ? Colors.white.withValues(alpha: 0.14)
            : _accent.withValues(alpha: 0.22);
      case AppVisualStyle.bento:
        return _isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
      case AppVisualStyle.cyber:
        return _accent.withValues(alpha: 0.45);
    }
  }

  double get _cardRadius {
    switch (_visualStyle) {
      case AppVisualStyle.glass:
        return 20;
      case AppVisualStyle.bento:
        return 24;
      case AppVisualStyle.cyber:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _scaffoldBg,
        primaryColor: _primaryText,
        fontFamily: 'Rajdhani',
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: QrCodeMobileScreen(
        isDark: _isDark,
        visualStyle: _visualStyle,
        bgStyle: _bgStyle,
        bgPalette: _bgPalette,
        scaffoldBg: _scaffoldBg,
        primaryText: _primaryText,
        accent: _accent,
        secondaryAccent: _secondaryAccent,
        cardSurface: _cardSurface,
        cardBorder: _cardBorder,
        cardRadius: _cardRadius,
        onToggleBrightness: () => setState(() => _isDark = !_isDark),
        onChangeStyle: (style) => setState(() => _visualStyle = style),
        onChangeBgStyle: (bg) => setState(() => _bgStyle = bg),
        onChangeBgPalette: (palette) => setState(() => _bgPalette = palette),
      ),
    );
  }
}

enum _QrTab { generate, scan }

enum QrModuleStyle {
  square('Square'),
  rounded('Rounded'),
  dots('Dots');

  const QrModuleStyle(this.label);
  final String label;
}

enum QrEyeStyle {
  square('Square'),
  rounded('Rounded'),
  circle('Circle');

  const QrEyeStyle(this.label);
  final String label;
}

class QrCodeMobileScreen extends StatefulWidget {
  const QrCodeMobileScreen({
    super.key,
    required this.isDark,
    required this.visualStyle,
    required this.bgStyle,
    required this.bgPalette,
    required this.scaffoldBg,
    required this.primaryText,
    required this.accent,
    required this.secondaryAccent,
    required this.cardSurface,
    required this.cardBorder,
    required this.cardRadius,
    required this.onToggleBrightness,
    required this.onChangeStyle,
    required this.onChangeBgStyle,
    required this.onChangeBgPalette,
  });

  final bool isDark;
  final AppVisualStyle visualStyle;
  final DynamicBackgroundStyle bgStyle;
  final BackgroundPalette bgPalette;
  final Color scaffoldBg;
  final Color primaryText;
  final Color accent;
  final Color secondaryAccent;
  final Color cardSurface;
  final Color cardBorder;
  final double cardRadius;
  final VoidCallback onToggleBrightness;
  final ValueChanged<AppVisualStyle> onChangeStyle;
  final ValueChanged<DynamicBackgroundStyle> onChangeBgStyle;
  final ValueChanged<BackgroundPalette> onChangeBgPalette;

  @override
  State<QrCodeMobileScreen> createState() => _QrCodeMobileScreenState();
}

class _QrCodeMobileScreenState extends State<QrCodeMobileScreen> {
  static const String _packageId = 'dev.sivaprasadnk.qr_code_studio_mobile';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_packageId';
  static const List<Color> _fgColorOptions = [
    Color(0xFF000000),
    Color(0xFF0F172A),
    Color(0xFF4F46E5),
    Color(0xFF0284C7),
    Color(0xFF059669),
    Color(0xFFE11D48),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
  ];

  static const List<Color> _bgColorOptions = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
    Color(0xFFFEFCE8),
    Color(0xFFECFDF5),
    Color(0xFFF0F9FF),
    Color(0xFFFDF2F8),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  _QrTab _activeTab = _QrTab.generate;
  String _qrData = '';
  bool _isInputFocused = false;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _showCustomize = false;

  // Version & In-App Update state
  String _appVersion = '1.0.0+2';
  bool _isCheckingUpdate = false;
  String _updateStatusText = 'Check Google Play for latest version';

  // Customization state
  QrModuleStyle _moduleStyle = QrModuleStyle.square;
  QrEyeStyle _eyeStyle = QrEyeStyle.square;
  Color _fgColor = _fgColorOptions.first;
  Color _bgColor = _bgColorOptions.first;
  int _errorCorrectLevel = QrErrorCorrectLevel.M;

  // Scanner state
  MobileScannerController? _scannerController;
  bool _isCameraRunning = false;
  bool _torchEnabled = false;
  String? _cameraError;
  String? _scannedResult;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _inputFocusNode.addListener(_onFocusChanged);
    _loadPackageVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPlayStoreUpdate(silentOnUpToDate: true);
    });
  }

  void _onFocusChanged() {
    if (mounted && _isInputFocused != _inputFocusNode.hasFocus) {
      setState(() {
        _isInputFocused = _inputFocusNode.hasFocus;
      });
    }
  }

  Future<void> _loadPackageVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = info.buildNumber.isNotEmpty
            ? '${info.version}+${info.buildNumber}'
            : info.version;
      });
    } catch (_) {}
  }

  Future<void> _checkForPlayStoreUpdate({bool silentOnUpToDate = false}) async {
    if (_isCheckingUpdate) return;
    if (kIsWeb || !Platform.isAndroid) {
      if (!silentOnUpToDate) {
        _showSnack('In-app updates are supported on Android via Google Play.');
      }
      return;
    }

    setState(() {
      _isCheckingUpdate = true;
      _updateStatusText = 'Checking Google Play for updates...';
    });

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (!mounted) return;

      if (updateInfo.installStatus == InstallStatus.downloaded) {
        setState(() {
          _updateStatusText = 'Update downloaded! Installing...';
        });
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable ||
          updateInfo.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress) {
        setState(() {
          _updateStatusText =
              'Update available (v${updateInfo.availableVersionCode ?? 'new'})! Downloading...';
        });
        if (!silentOnUpToDate) {
          _showSnack('Update found! Starting download from Google Play...');
        }

        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success && mounted) {
            await InAppUpdate.completeFlexibleUpdate();
          }
        } else {
          await _openPlayStoreListing();
        }
      } else {
        setState(() {
          _updateStatusText = 'Up to date (v$_appVersion)';
        });
        if (!silentOnUpToDate) {
          _showSnack('You are on the latest version (v$_appVersion)');
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _updateStatusText = 'Up to date (v$_appVersion)';
      });
      if (!silentOnUpToDate) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Current version: v$_appVersion'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Open Play Store',
                onPressed: _openPlayStoreListing,
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _openPlayStoreListing() async {
    final marketUri = Uri.parse('market://details?id=$_packageId');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_packageId',
    );
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not open Google Play Store.');
      }
    }
  }

  void _onTextChanged() {
    final trimmed = _textController.text.trim();
    if (trimmed != _qrData) {
      setState(() {
        _qrData = trimmed;
      });
    }
  }

  @override
  void dispose() {
    _stopCameraScanner();
    _scannerController?.dispose();
    _inputFocusNode.removeListener(_onFocusChanged);
    _inputFocusNode.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _switchTab(_QrTab tab) {
    if (_activeTab == tab) return;
    if (tab == _QrTab.generate) {
      _stopCameraScanner();
    }
    setState(() {
      _activeTab = tab;
    });
  }

  void _resetCustomization() {
    setState(() {
      _moduleStyle = QrModuleStyle.square;
      _eyeStyle = QrEyeStyle.square;
      _fgColor = _fgColorOptions.first;
      _bgColor = _bgColorOptions.first;
      _errorCorrectLevel = QrErrorCorrectLevel.M;
    });
  }

  Future<void> _startCameraScanner() async {
    _scannerController ??= MobileScannerController(
      autoStart: true,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
    if (!mounted) return;
    setState(() {
      _cameraError = null;
      _isCameraRunning = true;
      _torchEnabled = false;
    });
  }

  Future<void> _stopCameraScanner() async {
    if (mounted && _isCameraRunning) {
      setState(() {
        _isCameraRunning = false;
        _torchEnabled = false;
      });
    }
    try {
      await _scannerController?.stop();
    } catch (_) {}
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _onQrDetected(raw);
        break;
      }
    }
  }

  void _onQrDetected(String value) {
    _stopCameraScanner();
    setState(() {
      _scannedResult = value;
      _cameraError = null;
    });
    _showSnack('QR code scanned successfully');
  }

  Future<void> _scanFromGalleryImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (file == null) return;

      _scannerController ??= MobileScannerController(
        autoStart: true,
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.normal,
      );
      final BarcodeCapture? capture = await _scannerController!.analyzeImage(
        file.path,
        formats: const [BarcodeFormat.qrCode],
      );
      if (!mounted) return;

      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          _onQrDetected(code);
          return;
        }
      }
      _showSnack('No QR code detected in the selected image.');
    } catch (e) {
      if (mounted) {
        _showSnack('Could not scan image: $e');
      }
    }
  }

  Future<Uint8List?> _renderQrPngBytes(String data, {int size = 1024}) async {
    if (data.isEmpty) return null;
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: _errorCorrectLevel,
    );
    final qrImage = QrImage(qrCode);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    final painter = _QrMatrixPainter(
      qrImage: qrImage,
      foregroundColor: _fgColor,
      backgroundColor: _bgColor,
      moduleStyle: _moduleStyle,
      eyeStyle: _eyeStyle,
      quietZoneModules: 4,
    );
    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveQrToGallery() async {
    if (_qrData.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final pngBytes = await _renderQrPngBytes(_qrData);
      if (pngBytes == null) {
        _showSnack('Failed to render QR image.');
        return;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await Gal.putImageBytes(pngBytes, name: 'qrcode_$timestamp');
      if (!mounted) return;
      _showSnack('QR code saved to Gallery');
    } catch (e) {
      if (mounted) {
        _showSnack('Could not save QR code to Gallery.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareQrImage([BuildContext? buttonContext]) async {
    if (_qrData.isEmpty || _isSharing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSharing = true);

    try {
      final pngBytes = await _renderQrPngBytes(_qrData);
      if (pngBytes == null) {
        if (mounted) {
          setState(() => _isSharing = false);
          _showSnack('Failed to render QR image.');
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/qrcode_$timestamp.png');
      await file.writeAsBytes(pngBytes, flush: true);

      Rect? shareOrigin;
      if (buttonContext != null && buttonContext.mounted) {
        final box = buttonContext.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          shareOrigin = box.localToGlobal(Offset.zero) & box.size;
        }
      }

      if (mounted) {
        setState(() => _isSharing = false);
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/png',
              name: 'qrcode_$timestamp.png',
            ),
          ],
          text: 'Shared via QR Code Studio - $_playStoreUrl',
          title: 'QR Code Studio',
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSharing = false);
        _showSnack('Could not share QR code.');
      }
    }
  }

  Future<void> _openPortfolioWebsite() async {
    await _launchExternalUrl('https://sivaprasadnk.dev');
  }

  Future<void> _openPrivacyPolicy() async {
    await _launchExternalUrl('https://sivaprasadnk.dev/qrcode/privacy-policy');
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not open link');
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  bool _isValidHttpUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final primaryText = widget.primaryText;

    return _DynamicAppBackground(
      bgStyle: widget.bgStyle,
      isDark: widget.isDark,
      scaffoldBg: widget.scaffoldBg,
      accent: accent,
      secondaryAccent: widget.secondaryAccent,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: _buildAppDrawer(accent, primaryText),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryText),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 22,
                color: primaryText,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code Studio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Dynamic Backgrounds',
              onPressed: () {
                final values = DynamicBackgroundStyle.values;
                final nextIndex =
                    (values.indexOf(widget.bgStyle) + 1) % values.length;
                widget.onChangeBgStyle(values[nextIndex]);
                _showSnack('Background: ${values[nextIndex].label}');
              },
              icon: Icon(
                widget.bgStyle.icon,
                size: 20,
                color: accent,
              ),
            ),
            IconButton(
              tooltip: 'Toggle Theme Mode',
              onPressed: widget.onToggleBrightness,
              icon: Icon(
                widget.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 20,
                color: primaryText,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _buildStyleBar(accent, primaryText),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.cardSurface,
                        borderRadius: BorderRadius.circular(widget.cardRadius),
                        border: Border.all(
                          color: widget.cardBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTabSelector(accent, primaryText),
                          const SizedBox(height: 22),
                          if (_activeTab == _QrTab.generate)
                            _buildGeneratorSection(accent, primaryText)
                          else
                            _buildScannerSection(accent, primaryText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFooter(accent, primaryText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer(Color accent, Color primaryText) {
    final drawerSurface = widget.isDark
        ? Color.alphaBlend(
            Colors.black.withValues(alpha: 0.35),
            widget.scaffoldBg,
          )
        : Colors.white;

    return Drawer(
      backgroundColor: drawerSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
        side: BorderSide(color: widget.cardBorder),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: widget.isDark ? 0.10 : 0.08),
                border: Border(
                  bottom: BorderSide(color: widget.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.55)),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 26,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code Studio',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                'v$_appVersion',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '• SPNK Studio',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryText.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close Drawer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: primaryText.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Drawer Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Play Store Update Check & Download
                  _DrawerSectionHeader(
                    title: 'PLAY STORE UPDATES',
                    icon: Icons.system_update_rounded,
                    accent: accent,
                    primaryText: primaryText,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: widget.isDark ? 0.10 : 0.07,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: _isCheckingUpdate
                          ? null
                          : () =>
                              _checkForPlayStoreUpdate(silentOnUpToDate: false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: _isCheckingUpdate
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: accent,
                              ),
                            )
                          : Icon(
                              Icons.system_update_alt_rounded,
                              color: accent,
                            ),
                      title: Text(
                        _isCheckingUpdate
                            ? 'Checking for Updates...'
                            : 'Check for Updates',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      subtitle: Text(
                        _updateStatusText,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: primaryText.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Open Google Play Store',
                        onPressed: _openPlayStoreListing,
                        icon: Icon(
                          Icons.shop_two_rounded,
                          size: 19,
                          color: accent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Dynamic Backgrounds Section
                  _DrawerSectionHeader(
                    title: 'DYNAMIC BACKGROUND',
                    icon: Icons.wallpaper_rounded,
                    accent: accent,
                    primaryText: primaryText,
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: DynamicBackgroundStyle.values.map((bg) {
                      final selected = widget.bgStyle == bg;
                      return InkWell(
                        onTap: () => widget.onChangeBgStyle(bg),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? accent.withValues(
                                    alpha: widget.isDark ? 0.20 : 0.14,
                                  )
                                : primaryText.withValues(
                                    alpha: widget.isDark ? 0.04 : 0.03,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? accent : widget.cardBorder,
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                bg.icon,
                                size: 17,
                                color: selected
                                    ? accent
                                    : primaryText.withValues(alpha: 0.65),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  bg.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: selected
                                        ? (widget.isDark
                                            ? Colors.white
                                            : accent)
                                        : primaryText.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // 3. Background Color Palette / Mood
                  _DrawerSectionHeader(
                    title: 'BACKGROUND COLOR MOOD',
                    icon: Icons.color_lens_outlined,
                    accent: accent,
                    primaryText: primaryText,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: BackgroundPalette.values.map((palette) {
                      final selected = widget.bgPalette == palette;
                      return InkWell(
                        onTap: () => widget.onChangeBgPalette(palette),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.primaryGlow.withValues(alpha: 0.18)
                                : primaryText.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? palette.primaryGlow
                                  : widget.cardBorder,
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      palette.primaryGlow,
                                      palette.secondaryGlow,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                palette.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // 4. Appearance & Theme Mode
                  _DrawerSectionHeader(
                    title: 'APPEARANCE & CARD STYLE',
                    icon: Icons.tune_rounded,
                    accent: accent,
                    primaryText: primaryText,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryText.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isDark ? 'Dark Mode' : 'Light Mode',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: primaryText,
                            ),
                          ),
                        ),
                        Switch(
                          value: widget.isDark,
                          activeThumbColor: accent,
                          onChanged: (_) => widget.onToggleBrightness(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    onTap: _openPrivacyPolicy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      size: 19,
                      color: primaryText.withValues(alpha: 0.75),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: primaryText.withValues(alpha: 0.5),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    onTap: _openPortfolioWebsite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      Icons.language_rounded,
                      size: 19,
                      color: primaryText.withValues(alpha: 0.75),
                    ),
                    title: Text(
                      'Developer Portfolio (sivaprasadnk.dev)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: primaryText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Footer with Version & Portfolio Link
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: widget.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Version $_appVersion',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: primaryText.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openPortfolioWebsite,
                    child: Text(
                      'sivaprasadnk.dev ↗',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(Color accent, Color primaryText) {
    return InkWell(
      onTap: _openPortfolioWebsite,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Crafted by ',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: primaryText.withValues(alpha: 0.65),
              ),
            ),
            Text(
              'sivaprasadnk.dev',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new_rounded,
              size: 13.5,
              color: accent.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleBar(Color accent, Color primaryText) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.cardSurface,
        borderRadius: BorderRadius.circular(
          widget.visualStyle == AppVisualStyle.cyber ? 6 : 999,
        ),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppVisualStyle.values.map((style) {
          final isSelected = style == widget.visualStyle;
          return GestureDetector(
            onTap: () => widget.onChangeStyle(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: widget.isDark ? 0.22 : 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  widget.visualStyle == AppVisualStyle.cyber ? 4 : 999,
                ),
                border: Border.all(
                  color: isSelected
                      ? accent.withValues(alpha: 0.75)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    style.icon,
                    size: 14,
                    color: isSelected
                        ? accent
                        : primaryText.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? (widget.isDark ? Colors.white : accent)
                          : primaryText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabSelector(Color accent, Color primaryText) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primaryText.withValues(alpha: widget.isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPillButton(
              label: 'Generator',
              icon: Icons.qr_code_rounded,
              selected: _activeTab == _QrTab.generate,
              accent: accent,
              primaryText: primaryText,
              isDark: widget.isDark,
              onTap: () => _switchTab(_QrTab.generate),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabPillButton(
              label: 'Scanner',
              icon: Icons.qr_code_scanner_rounded,
              selected: _activeTab == _QrTab.scan,
              accent: accent,
              primaryText: primaryText,
              isDark: widget.isDark,
              onTap: () => _switchTab(_QrTab.scan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorSection(Color accent, Color primaryText) {
    QrImage? qrImage;
    String? qrGenerationError;
    if (_qrData.isNotEmpty) {
      try {
        final code = QrCode.fromData(
          data: _qrData,
          errorCorrectLevel: _errorCorrectLevel,
        );
        qrImage = QrImage(code);
      } catch (_) {
        qrGenerationError = 'Text is too long to encode into a QR code.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Text or URL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryText.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _inputFocusNode.requestFocus(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: 14, right: 6, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color:
                  primaryText.withValues(alpha: widget.isDark ? 0.05 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInputFocused ? accent : widget.cardBorder,
                width: _isInputFocused ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _inputFocusNode,
                    minLines: 1,
                    maxLines: 3,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: 'Enter text or paste a URL...',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: primaryText.withValues(alpha: 0.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Paste',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.content_paste_rounded,
                    size: 18,
                    color: primaryText.withValues(alpha: 0.65),
                  ),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _textController.text = data.text!;
                    }
                  },
                ),
                if (_qrData.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: primaryText.withValues(alpha: 0.65),
                    ),
                    onPressed: () => _textController.clear(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: qrImage != null ? _bgColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: qrImage != null
                ? CustomPaint(
                    size: const Size(212, 212),
                    painter: _QrMatrixPainter(
                      qrImage: qrImage,
                      foregroundColor: _fgColor,
                      backgroundColor: _bgColor,
                      moduleStyle: _moduleStyle,
                      eyeStyle: _eyeStyle,
                      quietZoneModules: 2,
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        qrGenerationError ??
                            'Type any text above to generate QR',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _showCustomize = !_showCustomize);
            },
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: Icon(
              _showCustomize ? Icons.tune_rounded : Icons.palette_outlined,
              size: 17,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showCustomize ? 'Hide Customization' : 'Customize QR',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCustomize
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
        if (_showCustomize) ...[
          const SizedBox(height: 8),
          _buildCustomizationPanel(accent, primaryText),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    (qrImage != null && !_isSaving) ? _saveQrToGallery : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor:
                      widget.isDark ? const Color(0xFF090D16) : Colors.white,
                  disabledBackgroundColor: accent.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving...' : 'Download QR (PNG)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (buttonContext) => IconButton.outlined(
                tooltip: 'Share QR Image',
                onPressed: qrImage != null
                    ? () => _shareQrImage(buttonContext)
                    : null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  side: BorderSide(color: widget.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSharing
                    ? SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : Icon(
                        Icons.share_rounded,
                        size: 19,
                        color: qrImage != null
                            ? primaryText
                            : primaryText.withValues(alpha: 0.35),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Copy text',
              onPressed: _qrData.isNotEmpty
                  ? () {
                      Clipboard.setData(ClipboardData(text: _qrData));
                      _showSnack('Text copied to clipboard');
                    }
                  : null,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(12),
                side: BorderSide(color: widget.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.copy_rounded,
                size: 19,
                color: _qrData.isNotEmpty
                    ? primaryText
                    : primaryText.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationPanel(Color accent, Color primaryText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryText.withValues(alpha: widget.isDark ? 0.04 : 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pattern Style',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryText.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _resetCustomization,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: QrModuleStyle.values.map((style) {
              final selected = _moduleStyle == style;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: style != QrModuleStyle.values.last ? 6 : 0,
                  ),
                  child: _MiniOptionButton(
                    label: style.label,
                    selected: selected,
                    accent: accent,
                    primaryText: primaryText,
                    borderColor: widget.cardBorder,
                    onTap: () => setState(() => _moduleStyle = style),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Corner Eye Shape',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryText.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: QrEyeStyle.values.map((style) {
              final selected = _eyeStyle == style;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: style != QrEyeStyle.values.last ? 6 : 0,
                  ),
                  child: _MiniOptionButton(
                    label: style.label,
                    selected: selected,
                    accent: accent,
                    primaryText: primaryText,
                    borderColor: widget.cardBorder,
                    onTap: () => setState(() => _eyeStyle = style),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'QR Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryText.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _fgColorOptions.map((color) {
              final selected = _fgColor.toARGB32() == color.toARGB32();
              return _ColorSwatchDot(
                color: color,
                selected: selected,
                accent: accent,
                onTap: () => setState(() => _fgColor = color),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Background',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryText.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _bgColorOptions.map((color) {
              final selected = _bgColor.toARGB32() == color.toARGB32();
              return _ColorSwatchDot(
                color: color,
                selected: selected,
                accent: accent,
                showLightBorder: true,
                onTap: () => setState(() => _bgColor = color),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Error Correction',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryText.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final entry in const [
                ('L (7%)', QrErrorCorrectLevel.L),
                ('M (15%)', QrErrorCorrectLevel.M),
                ('Q (25%)', QrErrorCorrectLevel.Q),
                ('H (30%)', QrErrorCorrectLevel.H),
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.$2 != QrErrorCorrectLevel.H ? 6 : 0,
                    ),
                    child: _MiniOptionButton(
                      label: entry.$1,
                      selected: _errorCorrectLevel == entry.$2,
                      accent: accent,
                      primaryText: primaryText,
                      borderColor: widget.cardBorder,
                      onTap: () =>
                          setState(() => _errorCorrectLevel = entry.$2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection(Color accent, Color primaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCameraRunning
                    ? accent.withValues(alpha: 0.8)
                    : widget.cardBorder,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isCameraRunning && _scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onBarcodeDetect,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam_off_rounded,
                                size: 44,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                error.errorDetails?.message ??
                                    error.errorCode.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFFF87171),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _cameraError ??
                                'Start camera or upload a QR image to scan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _cameraError != null
                                  ? const Color(0xFFF87171)
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ScannerOverlayPainter(
                      color: _isCameraRunning
                          ? accent
                          : Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                if (_isCameraRunning && _scannerController != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Toggle Flash',
                          onPressed: () async {
                            await _scannerController?.toggleTorch();
                            setState(() => _torchEnabled = !_torchEnabled);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor:
                                _torchEnabled ? accent : Colors.white,
                          ),
                          icon: Icon(
                            _torchEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Switch Camera',
                          onPressed: () => _scannerController?.switchCamera(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.cameraswitch_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isCameraRunning ? _stopCameraScanner : _startCameraScanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCameraRunning ? const Color(0xFFEF4444) : accent,
                  foregroundColor: _isCameraRunning
                      ? Colors.white
                      : (widget.isDark
                          ? const Color(0xFF090D16)
                          : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  _isCameraRunning
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  size: 19,
                ),
                label: Text(
                  _isCameraRunning ? 'Stop Camera' : 'Start Camera',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanFromGalleryImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryText,
                  side: BorderSide(color: widget.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.image_outlined,
                  size: 19,
                  color: accent,
                ),
                label: const Text(
                  'Upload Image',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_scannedResult != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: widget.isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scanned Result',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _scannedResult = null),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: primaryText.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _scannedResult!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResultActionChip(
                      icon: Icons.copy_rounded,
                      label: 'Copy',
                      accent: accent,
                      primaryText: primaryText,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: _scannedResult!),
                        );
                        _showSnack('Copied to clipboard');
                      },
                    ),
                    if (_isValidHttpUrl(_scannedResult!))
                      _ResultActionChip(
                        icon: Icons.open_in_new_rounded,
                        label: 'Open URL',
                        accent: accent,
                        primaryText: primaryText,
                        onTap: () async {
                          final uri = Uri.parse(_scannedResult!.trim());
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    _ResultActionChip(
                      icon: Icons.qr_code_rounded,
                      label: 'Edit in Generator',
                      accent: accent,
                      primaryText: primaryText,
                      onTap: () {
                        _textController.text = _scannedResult!;
                        _switchTab(_QrTab.generate);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
    required this.primaryText,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color primaryText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: primaryText.withValues(alpha: 0.65),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicAppBackground extends StatefulWidget {
  const _DynamicAppBackground({
    required this.bgStyle,
    required this.isDark,
    required this.scaffoldBg,
    required this.accent,
    required this.secondaryAccent,
    required this.child,
  });

  final DynamicBackgroundStyle bgStyle;
  final bool isDark;
  final Color scaffoldBg;
  final Color accent;
  final Color secondaryAccent;
  final Widget child;

  @override
  State<_DynamicAppBackground> createState() => _DynamicAppBackgroundState();
}

class _DynamicAppBackgroundState extends State<_DynamicAppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: widget.scaffoldBg),
        ),
        if (widget.bgStyle != DynamicBackgroundStyle.minimal)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DynamicBackgroundPainter(
                      style: widget.bgStyle,
                      progress: _controller.value,
                      isDark: widget.isDark,
                      accent: widget.accent,
                      secondaryAccent: widget.secondaryAccent,
                    ),
                  );
                },
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _DynamicBackgroundPainter extends CustomPainter {
  _DynamicBackgroundPainter({
    required this.style,
    required this.progress,
    required this.isDark,
    required this.accent,
    required this.secondaryAccent,
  });

  final DynamicBackgroundStyle style;
  final double progress;
  final bool isDark;
  final Color accent;
  final Color secondaryAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    switch (style) {
      case DynamicBackgroundStyle.aurora:
        _paintAurora(canvas, size, t);
        break;
      case DynamicBackgroundStyle.cyberGrid:
        _paintCyberGrid(canvas, size, t);
        break;
      case DynamicBackgroundStyle.starfield:
        _paintStarfield(canvas, size, t);
        break;
      case DynamicBackgroundStyle.neonWaves:
        _paintNeonWaves(canvas, size, t);
        break;
      case DynamicBackgroundStyle.particles:
        _paintConstellation(canvas, size, t);
        break;
      case DynamicBackgroundStyle.minimal:
        break;
    }
  }

  void _paintAurora(Canvas canvas, Size size, double t) {
    final alpha1 = isDark ? 0.25 : 0.16;
    final alpha2 = isDark ? 0.20 : 0.14;

    final c1 = Offset(
      size.width * (0.22 + 0.18 * math.sin(t)),
      size.height * (0.18 + 0.12 * math.cos(t)),
    );
    final c2 = Offset(
      size.width * (0.78 + 0.16 * math.cos(t * 0.8)),
      size.height * (0.75 + 0.14 * math.sin(t * 1.1)),
    );
    final c3 = Offset(
      size.width * (0.50 + 0.22 * math.sin(t * 1.3 + 1.2)),
      size.height * (0.48 + 0.16 * math.cos(t * 0.9)),
    );

    _drawRadialOrb(canvas, c1, size.shortestSide * 0.58, accent, alpha1);
    _drawRadialOrb(
      canvas,
      c2,
      size.shortestSide * 0.64,
      secondaryAccent,
      alpha2,
    );
    _drawRadialOrb(
      canvas,
      c3,
      size.shortestSide * 0.45,
      Color.lerp(accent, secondaryAccent, 0.5) ?? accent,
      alpha2 * 0.75,
    );
  }

  void _drawRadialOrb(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double maxAlpha,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: maxAlpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintCyberGrid(Canvas canvas, Size size, double t) {
    const step = 42.0;
    final shift = (progress * step);
    final linePaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.11 : 0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = (shift % step) - step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Scanning neon laser bar
    final scanY = (progress * size.height);
    final scanRect = Rect.fromLTWH(0, scanY - 50, size.width, 100);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0),
          accent.withValues(alpha: isDark ? 0.16 : 0.10),
          accent.withValues(alpha: 0),
        ],
      ).createShader(scanRect);
    canvas.drawRect(scanRect, scanPaint);
  }

  void _paintStarfield(Canvas canvas, Size size, double t) {
    _paintAurora(canvas, size, t * 0.5);
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final seed = i * 73.19;
      final baseX = ((math.sin(seed) * 0.5 + 0.5) * size.width);
      final baseY =
          (((math.cos(seed * 1.3) * 0.5 + 0.5) + progress * (0.2 + (i % 3) * 0.1)) %
                  1.0) *
              size.height;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 + i));
      final r = 1.2 + (i % 3) * 0.9;
      starPaint.color = (i.isEven ? accent : secondaryAccent)
          .withValues(alpha: (isDark ? 0.65 : 0.45) * twinkle);
      canvas.drawCircle(Offset(baseX, baseY), r, starPaint);
    }
  }

  void _paintNeonWaves(Canvas canvas, Size size, double t) {
    for (var w = 0; w < 3; w++) {
      final path = Path();
      final baseY = size.height * (0.28 + w * 0.24);
      final amp = 26.0 + w * 10.0;
      final phase = t + w * 1.4;
      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 16) {
        final y = baseY +
            math.sin((x / size.width) * 2 * math.pi + phase) * amp +
            math.cos((x / size.width) * 4 * math.pi - phase) * (amp * 0.4);
        path.lineTo(x, y);
      }
      final color = w.isEven ? accent : secondaryAccent;
      final strokePaint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.28 : 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawPath(path, strokePaint);
    }
  }

  void _paintConstellation(Canvas canvas, Size size, double t) {
    final points = <Offset>[];
    for (var i = 0; i < 20; i++) {
      final angle = (i * 1.7) + t * (i.isEven ? 1 : -1) * 0.5;
      final px = size.width * (0.1 + 0.8 * ((i * 37 % 100) / 100.0)) +
          math.cos(angle) * 24;
      final py = size.height * (0.1 + 0.8 * ((i * 61 % 100) / 100.0)) +
          math.sin(angle) * 24;
      points.add(Offset(px, py));
    }

    final linePaint = Paint()..strokeWidth = 1.0;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final maxDist = size.shortestSide * 0.34;

    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d < maxDist) {
          final alpha = (1.0 - (d / maxDist)) * (isDark ? 0.22 : 0.15);
          linePaint.color = accent.withValues(alpha: alpha);
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
      dotPaint.color = (i.isEven ? accent : secondaryAccent)
          .withValues(alpha: isDark ? 0.55 : 0.40);
      canvas.drawCircle(points[i], 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.style != style ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accent != accent ||
        oldDelegate.secondaryAccent != secondaryAccent;
  }
}

class _MiniOptionButton extends StatelessWidget {
  const _MiniOptionButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.primaryText,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color primaryText;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : borderColor,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? accent : primaryText.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  const _ColorSwatchDot({
    required this.color,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.showLightBorder = false,
  });

  final Color color;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool showLightBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? accent
                : (showLightBorder
                    ? const Color(0xFFCBD5E1)
                    : Colors.white.withValues(alpha: 0.25)),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 15,
                color: showLightBorder ? const Color(0xFF0F172A) : Colors.white,
              )
            : null,
      ),
    );
  }
}

class _TabPillButton extends StatelessWidget {
  const _TabPillButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.primaryText,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final Color primaryText;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: selected
              ? Border.all(color: accent.withValues(alpha: 0.65))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? accent : primaryText.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? (isDark ? Colors.white : accent)
                    : primaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultActionChip extends StatelessWidget {
  const _ResultActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.primaryText,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color primaryText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  _QrMatrixPainter({
    required this.qrImage,
    required this.foregroundColor,
    required this.backgroundColor,
    this.moduleStyle = QrModuleStyle.square,
    this.eyeStyle = QrEyeStyle.square,
    this.quietZoneModules = 2,
  });

  final QrImage qrImage;
  final Color foregroundColor;
  final Color backgroundColor;
  final QrModuleStyle moduleStyle;
  final QrEyeStyle eyeStyle;
  final int quietZoneModules;

  bool _isInFinderPattern(int row, int col, int moduleCount) {
    final inTopLeft = row < 7 && col < 7;
    final inTopRight = row < 7 && col >= moduleCount - 7;
    final inBottomLeft = row >= moduleCount - 7 && col < 7;
    return inTopLeft || inTopRight || inBottomLeft;
  }

  void _drawFinderPattern(
    Canvas canvas,
    int startRow,
    int startCol,
    double cellSize,
    Paint fgPaint,
    Paint bgPaint,
  ) {
    final left = (startCol + quietZoneModules) * cellSize;
    final top = (startRow + quietZoneModules) * cellSize;

    final outerRect = Rect.fromLTWH(left, top, 7 * cellSize, 7 * cellSize);
    final middleRect = Rect.fromLTWH(
      left + cellSize,
      top + cellSize,
      5 * cellSize,
      5 * cellSize,
    );
    final innerRect = Rect.fromLTWH(
      left + 2 * cellSize,
      top + 2 * cellSize,
      3 * cellSize,
      3 * cellSize,
    );

    switch (eyeStyle) {
      case QrEyeStyle.square:
        canvas.drawRect(outerRect, fgPaint);
        canvas.drawRect(middleRect, bgPaint);
        canvas.drawRect(innerRect, fgPaint);
        break;
      case QrEyeStyle.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(outerRect, Radius.circular(cellSize * 1.8)),
          fgPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(middleRect, Radius.circular(cellSize * 1.2)),
          bgPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(innerRect, Radius.circular(cellSize * 0.7)),
          fgPaint,
        );
        break;
      case QrEyeStyle.circle:
        canvas.drawOval(outerRect, fgPaint);
        canvas.drawOval(middleRect, bgPaint);
        canvas.drawOval(innerRect, fgPaint);
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final moduleCount = qrImage.moduleCount;
    final totalModules = moduleCount + (quietZoneModules * 2);
    final cellSize = size.width / totalModules;

    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = moduleStyle != QrModuleStyle.square ||
          eyeStyle != QrEyeStyle.square;

    _drawFinderPattern(canvas, 0, 0, cellSize, fgPaint, bgPaint);
    _drawFinderPattern(
      canvas,
      0,
      moduleCount - 7,
      cellSize,
      fgPaint,
      bgPaint,
    );
    _drawFinderPattern(
      canvas,
      moduleCount - 7,
      0,
      cellSize,
      fgPaint,
      bgPaint,
    );

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (_isInFinderPattern(row, col, moduleCount)) continue;
        if (qrImage.isDark(row, col)) {
          final left = (col + quietZoneModules) * cellSize;
          final top = (row + quietZoneModules) * cellSize;
          switch (moduleStyle) {
            case QrModuleStyle.square:
              canvas.drawRect(
                Rect.fromLTWH(left, top, cellSize + 0.35, cellSize + 0.35),
                fgPaint,
              );
              break;
            case QrModuleStyle.rounded:
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(
                    left + cellSize * 0.06,
                    top + cellSize * 0.06,
                    cellSize * 0.88,
                    cellSize * 0.88,
                  ),
                  Radius.circular(cellSize * 0.32),
                ),
                fgPaint,
              );
              break;
            case QrModuleStyle.dots:
              canvas.drawCircle(
                Offset(left + cellSize / 2, top + cellSize / 2),
                cellSize * 0.44,
                fgPaint,
              );
              break;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.moduleStyle != moduleStyle ||
        oldDelegate.eyeStyle != eyeStyle ||
        oldDelegate.quietZoneModules != quietZoneModules;
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double margin = 28;
    const double corner = 24;
    final left = margin;
    final top = margin;
    final right = size.width - margin;
    final bottom = size.height - margin;

    canvas.drawLine(Offset(left, top + corner), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), paint);

    canvas.drawLine(Offset(right - corner, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + corner), paint);

    canvas.drawLine(Offset(left, bottom - corner), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + corner, bottom), paint);

    canvas.drawLine(
      Offset(right - corner, bottom),
      Offset(right, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right, bottom - corner),
      Offset(right, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.color != color;
}
