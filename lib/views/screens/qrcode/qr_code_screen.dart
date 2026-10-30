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

class _QrCodeScreenState extends State<QrCodeScreen> {
  static const List<Color> _fgColorOptions = [
    Color(0xFF000000), // Classic Black
    Color(0xFF0F172A), // Deep Slate
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF059669), // Emerald
    Color(0xFFE11D48), // Rose
    Color(0xFF7C3AED), // Violet
    Color(0xFFD97706), // Amber
  ];

  static const List<Color> _bgColorOptions = [
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFF8FAFC), // Cool Alabaster
    Color(0xFFFEFCE8), // Warm Cream
    Color(0xFFECFDF5), // Mint Tint
    Color(0xFFF0F9FF), // Sky Tint
    Color(0xFFFDF2F8), // Rose Tint
  ];

  final TextEditingController _textController = TextEditingController();
  final QrPlatformHelper _platformHelper = createQrPlatformHelper();

  _QrTab _activeTab = _QrTab.generate;
  String _qrData = '';
  bool _isDownloading = false;
  bool _showCustomize = false;

  // QR Customization state
  QrModuleStyle _moduleStyle = QrModuleStyle.square;
  QrEyeStyle _eyeStyle = QrEyeStyle.square;
  Color _fgColor = _fgColorOptions.first;
  Color _bgColor = _bgColorOptions.first;
  int _errorCorrectLevel = QrErrorCorrectLevel.M;

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
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
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
            hoverColor: Colors.transparent,
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
        const SizedBox(height: 22),
        Center(
          child: Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: qrImage != null ? _bgColor : Colors.white,
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
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _showCustomize = !_showCustomize),
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
                  style: context.bodySmall.copyWith(
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
          _buildCustomizationPanel(themeState, accent),
        ],
        const SizedBox(height: 16),
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

  Widget _buildCustomizationPanel(ThemeState themeState, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.primaryColor
            .withValues(alpha: themeState.isDark ? 0.04 : 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeState.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pattern Style',
                style: context.bodySmall.copyWith(
                  fontSize: 13,
                  color: context.primaryColor.withValues(alpha: 0.75),
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
                    style: context.bodySmall.copyWith(
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
                    borderColor: themeState.cardBorderColor,
                    onTap: () => setState(() => _moduleStyle = style),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Corner Eye Shape',
            style: context.bodySmall.copyWith(
              fontSize: 13,
              color: context.primaryColor.withValues(alpha: 0.75),
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
                    borderColor: themeState.cardBorderColor,
                    onTap: () => setState(() => _eyeStyle = style),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'QR Color',
            style: context.bodySmall.copyWith(
              fontSize: 13,
              color: context.primaryColor.withValues(alpha: 0.75),
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
            style: context.bodySmall.copyWith(
              fontSize: 13,
              color: context.primaryColor.withValues(alpha: 0.75),
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
            style: context.bodySmall.copyWith(
              fontSize: 13,
              color: context.primaryColor.withValues(alpha: 0.75),
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
                      borderColor: themeState.cardBorderColor,
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

class _MiniOptionButton extends StatelessWidget {
  const _MiniOptionButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
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
          style: context.bodySmall.copyWith(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? accent
                : context.primaryColor.withValues(alpha: 0.75),
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

    // Draw the 3 corner finder patterns
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

    // Draw remaining modules
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
