import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr/qr.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/qrcode/qr_web_helper.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  static const routeName = '/qrcode';

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

enum _QrTab { generate, scan }

class _QrCodeScreenState extends State<QrCodeScreen> {
  final TextEditingController _textController = TextEditingController();
  final QrPlatformHelper _platformHelper = createQrPlatformHelper();

  _QrTab _activeTab = _QrTab.generate;
  String _qrData = '';
  bool _isDownloading = false;

  // Scanner state
  late final String _cameraViewType;
  bool _isCameraRunning = false;
  bool _isStartingCamera = false;
  bool _useFrontCamera = false;
  String? _cameraError;
  String? _scannedResult;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _cameraViewType = _platformHelper.registerCameraView();
    final tabParam = Uri.base.queryParameters['tab']?.toLowerCase();
    if (tabParam == 'scan' || tabParam == 'scanner') {
      _activeTab = _QrTab.scan;
    }
    _textController.addListener(_onTextChanged);
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

  Future<void> _startCameraScanner() async {
    if (_isStartingCamera) return;
    setState(() {
      _isStartingCamera = true;
      _cameraError = null;
    });

    final error = await _platformHelper.startCamera(
      viewType: _cameraViewType,
      useFrontCamera: _useFrontCamera,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isStartingCamera = false;
        _isCameraRunning = false;
        _cameraError = error;
      });
      return;
    }

    setState(() {
      _isStartingCamera = false;
      _isCameraRunning = true;
      _cameraError = null;
    });

    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!_isCameraRunning || !mounted) return;
      final decoded = _platformHelper.decodeCurrentVideoFrame(_cameraViewType);
      if (decoded != null && decoded.isNotEmpty) {
        _onQrDetected(decoded);
      }
    });
  }

  void _stopCameraScanner() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _platformHelper.stopCamera(_cameraViewType);
    if (mounted && (_isCameraRunning || _isStartingCamera)) {
      setState(() {
        _isCameraRunning = false;
        _isStartingCamera = false;
      });
    }
  }

  Future<void> _toggleCameraFacing() async {
    setState(() {
      _useFrontCamera = !_useFrontCamera;
    });
    if (_isCameraRunning) {
      await _startCameraScanner();
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

  Future<void> _scanFromImageFile() async {
    final outcome = await _platformHelper.pickAndDecodeImage();
    if (!mounted) return;

    switch (outcome.status) {
      case QrImageScanStatus.found:
        if (outcome.data != null && outcome.data!.isNotEmpty) {
          _onQrDetected(outcome.data!);
        }
        break;
      case QrImageScanStatus.notFound:
        _showSnack('No QR code detected in the selected image.');
        break;
      case QrImageScanStatus.error:
        _showSnack(outcome.errorMessage ?? 'Could not scan image.');
        break;
      case QrImageScanStatus.cancelled:
        break;
    }
  }

  Future<Uint8List?> _renderQrPngBytes(String data, {int size = 1024}) async {
    if (data.isEmpty) return null;
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    final painter = _QrMatrixPainter(
      qrImage: qrImage,
      foregroundColor: const Color(0xFF000000),
      backgroundColor: const Color(0xFFFFFFFF),
      quietZoneModules: 4,
    );
    painter.paint(canvas, Size(size.toDouble(), size.toDouble()));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _downloadQrCode() async {
    if (_qrData.isEmpty || _isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      final pngBytes = await _renderQrPngBytes(_qrData);
      if (pngBytes == null) {
        _showSnack('Failed to render QR image.');
        return;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final success = await _platformHelper.downloadPngBytes(
        pngBytes,
        'qrcode_$timestamp.png',
      );
      if (!mounted) return;
      if (success) {
        _showSnack('QR code downloaded as PNG');
      } else {
        _showSnack('Download is supported in web browser.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Could not download QR code.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
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
    final isMobile = context.isMobileDevice;

    return PortfolioStyleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            tooltip: 'Home',
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.primaryColor,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 22,
                color: context.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'QR Code Studio',
                style: context.displaySmall.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final accent = themeState.accentColor;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 16 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    decoration: BoxDecoration(
                      color: themeState.cardSurfaceColor,
                      borderRadius:
                          BorderRadius.circular(themeState.cardRadius),
                      border: Border.all(
                        color: themeState.cardBorderColor,
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTabSelector(themeState, accent),
                        const SizedBox(height: 24),
                        if (_activeTab == _QrTab.generate)
                          _buildGeneratorSection(themeState, accent)
                        else
                          _buildScannerSection(themeState, accent),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabSelector(ThemeState themeState, Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.primaryColor
            .withValues(alpha: themeState.isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeState.cardBorderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPillButton(
              label: 'Generator',
              icon: Icons.qr_code_rounded,
              selected: _activeTab == _QrTab.generate,
              accent: accent,
              isDark: themeState.isDark,
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
              isDark: themeState.isDark,
              onTap: () => _switchTab(_QrTab.scan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorSection(ThemeState themeState, Color accent) {
    QrImage? qrImage;
    String? qrGenerationError;
    if (_qrData.isNotEmpty) {
      try {
        final code = QrCode.fromData(
          data: _qrData,
          errorCorrectLevel: QrErrorCorrectLevel.M,
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
          style: context.bodySmall.copyWith(
            fontSize: 14,
            color: context.primaryColor.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          minLines: 1,
          maxLines: 3,
          style: context.bodyMedium.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter text or paste a URL...',
            hintStyle: context.bodySmall.copyWith(
              fontSize: 15,
              color: context.primaryColor.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: context.primaryColor
                .withValues(alpha: themeState.isDark ? 0.05 : 0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeState.cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeState.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.4),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Paste',
                  icon: Icon(
                    Icons.content_paste_rounded,
                    size: 18,
                    color: context.primaryColor.withValues(alpha: 0.65),
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
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.primaryColor.withValues(alpha: 0.65),
                    ),
                    onPressed: () => _textController.clear(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeState.cardBorderColor,
              ),
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
                      foregroundColor: const Color(0xFF000000),
                      backgroundColor: const Color(0xFFFFFFFF),
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    (qrImage != null && !_isDownloading) ? _downloadQrCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor:
                      themeState.isDark ? const Color(0xFF090D16) : Colors.white,
                  disabledBackgroundColor: accent.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _isDownloading ? 'Downloading...' : 'Download QR (PNG)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                side: BorderSide(color: themeState.cardBorderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.copy_rounded,
                size: 19,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScannerSection(ThemeState themeState, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCameraRunning
                    ? accent.withValues(alpha: 0.8)
                    : themeState.cardBorderColor,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isCameraRunning)
                  _platformHelper.buildCameraPreview(_cameraViewType)
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
                if (_isCameraRunning)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      tooltip: 'Switch Camera',
                      onPressed: _toggleCameraFacing,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.cameraswitch_rounded, size: 18),
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
                onPressed: _isStartingCamera
                    ? null
                    : (_isCameraRunning
                        ? _stopCameraScanner
                        : _startCameraScanner),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCameraRunning
                      ? const Color(0xFFEF4444)
                      : accent,
                  foregroundColor: _isCameraRunning
                      ? Colors.white
                      : (themeState.isDark
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
                  _isStartingCamera
                      ? 'Starting...'
                      : (_isCameraRunning ? 'Stop Camera' : 'Start Camera'),
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
                onPressed: _scanFromImageFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: themeState.cardBorderColor),
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
              color: accent.withValues(alpha: themeState.isDark ? 0.08 : 0.06),
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
                      style: context.bodySmall.copyWith(
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
                        color: context.primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _scannedResult!,
                  style: context.bodyMedium.copyWith(
                    fontSize: 15,
                    height: 1.4,
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

class _TabPillButton extends StatelessWidget {
  const _TabPillButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
                color: selected
                    ? accent
                    : context.primaryColor.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected
                      ? (isDark ? Colors.white : accent)
                      : context.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
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
              style: context.bodySmall.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
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
    this.quietZoneModules = 2,
  });

  final QrImage qrImage;
  final Color foregroundColor;
  final Color backgroundColor;
  final int quietZoneModules;

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
      ..isAntiAlias = false;

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          final left = (col + quietZoneModules) * cellSize;
          final top = (row + quietZoneModules) * cellSize;
          canvas.drawRect(
            Rect.fromLTWH(left, top, cellSize + 0.35, cellSize + 0.35),
            fgPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor ||
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

    // Top-left
    canvas.drawLine(Offset(left, top + corner), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), paint);

    // Top-right
    canvas.drawLine(Offset(right - corner, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + corner), paint);

    // Bottom-left
    canvas.drawLine(Offset(left, bottom - corner), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + corner, bottom), paint);

    // Bottom-right
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
