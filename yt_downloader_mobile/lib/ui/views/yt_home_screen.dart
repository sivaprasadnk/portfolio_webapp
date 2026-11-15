import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/yt_models.dart';
import '../core/app_theme.dart';
import '../view_models/yt_downloader_view_model.dart';

class YtHomeScreen extends StatefulWidget {
  const YtHomeScreen({
    super.key,
    required this.viewModel,
  });

  final YtDownloaderViewModel viewModel;

  @override
  State<YtHomeScreen> createState() => _YtHomeScreenState();
}

class _YtHomeScreenState extends State<YtHomeScreen> {
  late final TextEditingController _urlController;
  bool _descriptionExpanded = false;

  YtDownloaderViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _vm.rawUrlInput);
    _vm.addListener(_syncControllerFromVm);
  }

  void _syncControllerFromVm() {
    if (_urlController.text != _vm.rawUrlInput) {
      _urlController.value = TextEditingValue(
        text: _vm.rawUrlInput,
        selection: TextSelection.collapsed(offset: _vm.rawUrlInput.length),
      );
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_syncControllerFromVm);
    _urlController.dispose();
    super.dispose();
  }

  void _showFeedbackSnackBar(YtActionFeedback feedback) {
    if (!mounted || feedback.wasCancelled) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final saved = feedback.savedItem;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: feedback.isError
            ? const Color(0xFFB91C1C)
            : const Color(0xFF0F172A),
        content: Text(
          feedback.message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        action: saved != null
            ? SnackBarAction(
                label: 'SHARE',
                textColor: _vm.themeConfig.accent,
                onPressed: () {
                  _vm.shareSavedItem(saved);
                },
              )
            : null,
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    _vm.updateUrlInput(text);
    if (ParsedYoutubeTarget.tryParse(text) != null) {
      await _vm.fetchMedia(text);
    }
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text('Copied $label to clipboard'),
        ),
      );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openSettingsSheet() {
    final endpointController = TextEditingController(text: _vm.customEndpoint);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            final cfg = _vm.themeConfig;
            return DraggableScrollableSheet(
              initialChildSize: 0.74,
              minChildSize: 0.5,
              maxChildSize: 0.94,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cfg.isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(color: cfg.cardBorder),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cfg.primaryText.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, color: cfg.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Studio Appearance & Engine',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: cfg.primaryText,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _vm.autoSaveToGallery,
                        activeTrackColor: cfg.accent,
                        title: const Text(
                          'Auto-Save MP4 & Covers to Gallery',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Exports MP4 videos & JPEG thumbnails directly to your phone Photos/Gallery album in addition to the app Library.',
                        ),
                        onChanged: _vm.setAutoSaveToGallery,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: cfg.isDark,
                        activeTrackColor: cfg.accent,
                        title: const Text(
                          'Dark Studio Theme',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onChanged: (v) =>
                            _vm.updateTheme(cfg.copyWith(isDark: v)),
                      ),
                      const Divider(height: 24),
                      Text(
                        'VISUAL STYLE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: cfg.primaryText.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppVisualStyle.values.map((style) {
                          final selected = cfg.visualStyle == style;
                          return ChoiceChip(
                            avatar: Icon(style.icon, size: 16),
                            label: Text(style.label),
                            selected: selected,
                            onSelected: (_) => _vm.updateTheme(
                              cfg.copyWith(visualStyle: style),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'DYNAMIC BACKGROUND',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: cfg.primaryText.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DynamicBackgroundStyle.values.map((bg) {
                          final selected = cfg.bgStyle == bg;
                          return ChoiceChip(
                            avatar: Icon(bg.icon, size: 16),
                            label: Text(bg.label),
                            selected: selected,
                            onSelected: (_) =>
                                _vm.updateTheme(cfg.copyWith(bgStyle: bg)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'COLOR PALETTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: cfg.primaryText.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BackgroundPalette.values.map((pal) {
                          final selected = cfg.palette == pal;
                          return ChoiceChip(
                            avatar: CircleAvatar(
                              radius: 7,
                              backgroundColor: pal.primaryGlow,
                            ),
                            label: Text(pal.label),
                            selected: selected,
                            onSelected: (_) =>
                                _vm.updateTheme(cfg.copyWith(palette: pal)),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 28),
                      Text(
                        'CUSTOM STREAM NODE (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: cfg.primaryText.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Leave blank to use the built-in On-Device YouTube Engine + automatic companion fallback, or enter a custom Invidious/Cobalt instance URL.',
                        style: TextStyle(
                          fontSize: 13,
                          color: cfg.primaryText.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: endpointController,
                        decoration: InputDecoration(
                          hintText: 'https://your-instance.example.com',
                          filled: true,
                          fillColor: cfg.cardSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Reset to default engine',
                            icon: const Icon(Icons.restart_alt_rounded),
                            onPressed: () {
                              endpointController.clear();
                              _vm.setCustomEndpoint('');
                            },
                          ),
                        ),
                        onSubmitted: _vm.setCustomEndpoint,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          _vm.setCustomEndpoint(endpointController.text);
                          Navigator.of(sheetCtx).pop();
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Apply Settings'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final cfg = _vm.themeConfig;
        final savedCount = _vm.savedItems.length;

        return DynamicStudioBackground(
          config: cfg,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useRail = constraints.maxWidth >= 640;

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  titleSpacing: 16,
                  title: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cfg.accent, cfg.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'YT Downloader',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: cfg.primaryText,
                              ),
                            ),
                            Text(
                              _vm.videoInfo?.activeProviderNode.isNotEmpty ==
                                      true
                                  ? _vm.videoInfo!.activeProviderNode
                                  : 'On-Device Mobile Media Studio',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cfg.primaryText.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: cfg.isDark
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      onPressed: () =>
                          _vm.updateTheme(cfg.copyWith(isDark: !cfg.isDark)),
                      icon: Icon(
                        cfg.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Appearance & Stream Engine',
                      onPressed: _openSettingsSheet,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                body: SafeArea(
                  top: false,
                  child: useRail
                      ? Row(
                          children: [
                            NavigationRail(
                              backgroundColor: Colors.transparent,
                              selectedIndex: _vm.selectedNavIndex,
                              onDestinationSelected: _vm.setSelectedNavIndex,
                              labelType: NavigationRailLabelType.all,
                              destinations: [
                                const NavigationRailDestination(
                                  icon: Icon(
                                    Icons.download_for_offline_outlined,
                                  ),
                                  selectedIcon: Icon(
                                    Icons.download_for_offline_rounded,
                                  ),
                                  label: Text('Downloader'),
                                ),
                                NavigationRailDestination(
                                  icon: _buildLibraryBadge(
                                    savedCount,
                                    const Icon(Icons.video_library_outlined),
                                  ),
                                  selectedIcon: _buildLibraryBadge(
                                    savedCount,
                                    const Icon(Icons.video_library_rounded),
                                  ),
                                  label: const Text('Library'),
                                ),
                              ],
                            ),
                            VerticalDivider(width: 1, color: cfg.cardBorder),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 860,
                                  ),
                                  child: _buildActivePage(cfg),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildActivePage(cfg),
                ),
                bottomNavigationBar: useRail
                    ? null
                    : NavigationBar(
                        backgroundColor: cfg.cardSurface,
                        selectedIndex: _vm.selectedNavIndex,
                        onDestinationSelected: _vm.setSelectedNavIndex,
                        destinations: [
                          const NavigationDestination(
                            icon: Icon(Icons.download_for_offline_outlined),
                            selectedIcon: Icon(
                              Icons.download_for_offline_rounded,
                            ),
                            label: 'Downloader',
                          ),
                          NavigationDestination(
                            icon: _buildLibraryBadge(
                              savedCount,
                              const Icon(Icons.video_library_outlined),
                            ),
                            selectedIcon: _buildLibraryBadge(
                              savedCount,
                              const Icon(Icons.video_library_rounded),
                            ),
                            label: 'Library',
                          ),
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLibraryBadge(int count, Widget icon) {
    if (count <= 0) return icon;
    return Badge(
      label: Text('$count'),
      child: icon,
    );
  }

  Widget _buildActivePage(YtThemeConfig cfg) {
    if (_vm.selectedNavIndex == 1) {
      return _buildLibraryView(cfg);
    }
    return _buildDownloaderView(cfg);
  }

  Widget _buildDownloaderView(YtThemeConfig cfg) {
    final info = _vm.videoInfo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _buildUrlInputCard(cfg),
        if (_vm.errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorCard(cfg, _vm.errorMessage!),
        ],
        if (info == null && !_vm.isLoading) ...[
          const SizedBox(height: 16),
          _buildQuickGuideCard(cfg),
        ],
        if (info != null) ...[
          const SizedBox(height: 16),
          _buildVideoHeroCard(cfg, info),
          const SizedBox(height: 14),
          _buildMediaTabsHeader(cfg, info),
          const SizedBox(height: 12),
          _buildActiveMediaTabBody(cfg, info),
        ],
      ],
    );
  }

  Widget _buildUrlInputCard(YtThemeConfig cfg) {
    final parsed = _vm.parsedTarget;

    return _StudioCard(
      config: cfg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: cfg.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'YouTube Link or Video ID',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cfg.primaryText,
                  ),
                ),
              ),
              if (parsed != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cfg.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cfg.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '${parsed.kind.badge} • ${parsed.videoId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cfg.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('yt_url_input'),
            controller: _urlController,
            onChanged: _vm.updateUrlInput,
            onSubmitted: (_) => _vm.fetchMedia(),
            textInputAction: TextInputAction.search,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cfg.primaryText,
            ),
            decoration: InputDecoration(
              hintText: 'Paste YouTube, Shorts, Music, or youtu.be URL...',
              isDense: true,
              filled: true,
              fillColor: cfg.scaffoldBg.withValues(alpha: 0.55),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cfg.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cfg.cardBorder),
              ),
              suffixIcon: _vm.rawUrlInput.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear link',
                      onPressed: () {
                        _urlController.clear();
                        _vm.clearInput();
                      },
                      icon: const Icon(Icons.close_rounded, size: 19),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _vm.isLoading ? null : _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_rounded, size: 17),
                label: const Text('Paste'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('yt_extract_button'),
                  onPressed: _vm.isLoading ? null : () => _vm.fetchMedia(),
                  style: FilledButton.styleFrom(
                    backgroundColor: cfg.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _vm.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 19),
                  label: Text(
                    _vm.isLoading ? 'Extracting Streams...' : 'Extract Media',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Try sample:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cfg.primaryText.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(width: 8),
                ...YtSamplePreset.presets.map(
                  (preset) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        Icons.play_circle_outline_rounded,
                        size: 15,
                        color: cfg.accent,
                      ),
                      label: Text(
                        '${preset.label} (${preset.tag})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _vm.isLoading
                          ? null
                          : () {
                              _vm.updateUrlInput(preset.url);
                              _vm.fetchMedia(preset.url);
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(YtThemeConfig cfg, String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(cfg.cardRadius),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: cfg.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _vm.isLoading ? null : () => _vm.fetchMedia(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGuideCard(YtThemeConfig cfg) {
    return _StudioCard(
      config: cfg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_iphone_rounded, color: cfg.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Built for Native Mobile Downloads',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cfg.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GuideBullet(
            icon: Icons.share_rounded,
            accent: cfg.accent,
            title: 'Share Directly from YouTube App',
            subtitle:
                'Tap Share on any YouTube video or Short and choose YT Downloader to auto-extract.',
          ),
          const SizedBox(height: 8),
          _GuideBullet(
            icon: Icons.high_quality_rounded,
            accent: cfg.secondary,
            title: 'Inline 1-Tap Progress & Cancel',
            subtitle:
                'Every video, audio, cover, and subtitle tile shows real-time MB/% progress and Cancel right inside the tile.',
          ),
          const SizedBox(height: 8),
          _GuideBullet(
            icon: Icons.photo_library_rounded,
            accent: const Color(0xFF10B981),
            title: 'Phone Gallery + Offline Library',
            subtitle:
                'MP4 videos and HD covers save straight to your Photos/Gallery album and offline Library.',
          ),
        ],
      ),
    );
  }

  Widget _buildVideoHeroCard(YtThemeConfig cfg, YtVideoInfo info) {
    return _StudioCard(
      config: cfg,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(cfg.cardRadius),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    info.primaryThumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: cfg.scaffoldBg,
                      child: Center(
                        child: Icon(
                          Icons.ondemand_video_rounded,
                          size: 48,
                          color: cfg.accent,
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _OverlayPill(
                      text: info.urlKind.badge,
                      background: cfg.accent,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _OverlayPill(
                      text: info.formattedDuration,
                      background: Colors.black.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: cfg.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    info.author,
                    if (info.publishedText.isNotEmpty) info.publishedText,
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cfg.primaryText.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatBadge(
                      icon: Icons.visibility_outlined,
                      label:
                          '${YtVideoInfo.formatCompactCount(info.viewCount)} views',
                      config: cfg,
                    ),
                    if (info.likeCount != null)
                      _StatBadge(
                        icon: Icons.thumb_up_alt_outlined,
                        label: YtVideoInfo.formatCompactCount(info.likeCount),
                        config: cfg,
                      ),
                    if (info.rating != null)
                      _StatBadge(
                        icon: Icons.star_rounded,
                        label: '${info.rating!.toStringAsFixed(1)} / 5.0',
                        config: cfg,
                      ),
                    _StatBadge(
                      icon: Icons.layers_outlined,
                      label:
                          '${info.videoStreams.length}V • ${info.audioStreams.length}A',
                      config: cfg,
                    ),
                  ],
                ),
                if (info.streamWarning != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      info.streamWarning!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cfg.primaryText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _openExternalUrl(info.watchUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('YouTube'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _vm.shareCurrentVideoLink,
                      icon: const Icon(Icons.share_outlined, size: 15),
                      label: const Text('Share Link'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _copyText(info.watchUrl, 'video URL'),
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Copy URL'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTabsHeader(YtThemeConfig cfg, YtVideoInfo info) {
    final counts = <YtMediaTab, int>{
      YtMediaTab.video: info.videoStreams.length,
      YtMediaTab.audio: info.audioStreams.length,
      YtMediaTab.thumbnails: info.thumbnails.length,
      YtMediaTab.tools: info.captions.length + 1,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: YtMediaTab.values.map((tab) {
          final selected = _vm.activeTab == tab;
          final count = counts[tab] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              selectedColor: cfg.accent.withValues(alpha: 0.22),
              label: Text(
                '${tab.label} ($count)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? cfg.accent : cfg.primaryText,
                ),
              ),
              onSelected: (_) => _vm.setActiveTab(tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveMediaTabBody(YtThemeConfig cfg, YtVideoInfo info) {
    switch (_vm.activeTab) {
      case YtMediaTab.video:
        return _buildVideoStreamsSection(cfg);
      case YtMediaTab.audio:
        return _buildAudioStreamsSection(cfg, info.audioStreams);
      case YtMediaTab.thumbnails:
        return _buildThumbnailsSection(cfg, info.thumbnails);
      case YtMediaTab.tools:
        return _buildToolsSection(cfg, info);
    }
  }

  Widget _buildVideoStreamsSection(YtThemeConfig cfg) {
    final streams = _vm.filteredVideoStreams;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...YtContainerFilter.values.map((filter) {
              final selected = _vm.containerFilter == filter;
              return FilterChip(
                visualDensity: VisualDensity.compact,
                selected: selected,
                label: Text(filter.label),
                onSelected: (_) => _vm.setContainerFilter(filter),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        if (streams.isEmpty)
          _StudioCard(
            config: cfg,
            child: Text(
              'No video streams matched the selected container filter.',
              style: TextStyle(color: cfg.primaryText.withValues(alpha: 0.75)),
            ),
          )
        else
          ...streams.map(
            (stream) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildStreamOptionTile(cfg, stream),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioStreamsSection(
    YtThemeConfig cfg,
    List<YtStreamOption> audioStreams,
  ) {
    if (audioStreams.isEmpty) {
      return _StudioCard(
        config: cfg,
        child: Text(
          'No standalone audio tracks were exposed for this video.',
          style: TextStyle(color: cfg.primaryText.withValues(alpha: 0.75)),
        ),
      );
    }
    return Column(
      children: audioStreams
          .map(
            (stream) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildStreamOptionTile(cfg, stream),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStreamOptionTile(YtThemeConfig cfg, YtStreamOption stream) {
    final tileId = YtDownloaderViewModel.streamTileId(stream);
    final isThisDownloading = _vm.activeDownloadId == tileId;
    final isAnotherDownloading =
        _vm.activeDownloadId != null && !isThisDownloading;

    final modeColor = stream.isAudioOnly
        ? cfg.secondary
        : (stream.isCombined
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B));
    final modeText = stream.isAudioOnly
        ? 'Audio Track'
        : (stream.isCombined ? 'Video + Audio' : 'Video-Only HD');

    return _StudioCard(
      key: ValueKey('tile_$tileId'),
      config: cfg,
      borderOverride: isThisDownloading ? cfg.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cfg.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  stream.isAudioOnly
                      ? Icons.headphones_rounded
                      : Icons.movie_creation_outlined,
                  color: cfg.accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          stream.qualityLabel,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: cfg.primaryText,
                          ),
                        ),
                        _MiniBadge(
                          label: stream.tierBadge,
                          color: cfg.accent,
                        ),
                        _MiniBadge(
                          label: modeText,
                          color: modeColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${stream.fileExtension.toUpperCase()} • '
                      '${stream.codecShortLabel} • '
                      '${stream.formattedSize}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cfg.primaryText.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isThisDownloading) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: ValueKey('download_btn_$tileId'),
                  onPressed: isAnotherDownloading
                      ? null
                      : () async {
                          final res = await _vm.downloadStream(stream);
                          _showFeedbackSnackBar(res);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: cfg.accent,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          if (isThisDownloading) ...[
            const SizedBox(height: 12),
            _InlineTileProgressBar(
              tileId: tileId,
              progress: _vm.downloadProgress,
              stageLabel: _vm.downloadStageLabel,
              accent: cfg.accent,
              textColor: cfg.primaryText,
              onCancel: _vm.cancelActiveDownload,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnailsSection(
    YtThemeConfig cfg,
    List<YtThumbnailOption> thumbnails,
  ) {
    return Column(
      children: thumbnails.map((thumb) {
        final tileId = YtDownloaderViewModel.thumbnailTileId(thumb);
        final isThisDownloading = _vm.activeDownloadId == tileId;
        final isAnotherDownloading =
            _vm.activeDownloadId != null && !isThisDownloading;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StudioCard(
            key: ValueKey('tile_$tileId'),
            config: cfg,
            borderOverride: isThisDownloading ? cfg.accent : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 96,
                        height: 54,
                        child: Image.network(
                          thumb.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: cfg.scaffoldBg,
                            child: Icon(
                              Icons.image_outlined,
                              color: cfg.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thumb.label,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: cfg.primaryText,
                            ),
                          ),
                          Text(
                            '${thumb.resolution} • JPEG Cover',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cfg.primaryText.withValues(alpha: 0.66),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isThisDownloading)
                      FilledButton.tonalIcon(
                        key: ValueKey('download_btn_$tileId'),
                        onPressed: isAnotherDownloading
                            ? null
                            : () async {
                                final res = await _vm.downloadThumbnail(thumb);
                                _showFeedbackSnackBar(res);
                              },
                        icon: const Icon(Icons.download_rounded, size: 17),
                        label: const Text('Save'),
                      ),
                  ],
                ),
                if (isThisDownloading) ...[
                  const SizedBox(height: 12),
                  _InlineTileProgressBar(
                    tileId: tileId,
                    progress: _vm.downloadProgress,
                    stageLabel: _vm.downloadStageLabel,
                    accent: cfg.accent,
                    textColor: cfg.primaryText,
                    onCancel: _vm.cancelActiveDownload,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolsSection(YtThemeConfig cfg, YtVideoInfo info) {
    final isMetaDownloading =
        _vm.activeDownloadId == YtDownloaderViewModel.metadataTileId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StudioCard(
          config: cfg,
          borderOverride: isMetaDownloading ? cfg.accent : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.data_object_rounded, color: cfg.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metadata JSON Snapshot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cfg.primaryText,
                          ),
                        ),
                        Text(
                          'Save full title, stats, stream counts, and description to JSON.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cfg.primaryText.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMetaDownloading)
                    FilledButton.tonalIcon(
                      onPressed: _vm.activeDownloadId != null
                          ? null
                          : () async {
                              final res = await _vm.exportMetadataJson();
                              _showFeedbackSnackBar(res);
                            },
                      icon: const Icon(Icons.save_alt_rounded, size: 17),
                      label: const Text('Export'),
                    ),
                ],
              ),
              if (isMetaDownloading) ...[
                const SizedBox(height: 10),
                _InlineTileProgressBar(
                  tileId: YtDownloaderViewModel.metadataTileId,
                  progress: null,
                  stageLabel: _vm.downloadStageLabel,
                  accent: cfg.accent,
                  textColor: cfg.primaryText,
                  onCancel: _vm.cancelActiveDownload,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StudioCard(
          config: cfg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.subtitles_outlined, color: cfg.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Closed Captions / Subtitles (.VTT)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cfg.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (info.captions.isEmpty)
                Text(
                  'No closed caption tracks were listed for this video.',
                  style: TextStyle(
                    color: cfg.primaryText.withValues(alpha: 0.68),
                  ),
                )
              else
                ...info.captions.map((cap) {
                  final tileId = YtDownloaderViewModel.captionTileId(cap);
                  final isThisActive = _vm.activeDownloadId == tileId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${cap.label} (${cap.languageCode})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cfg.primaryText,
                                ),
                              ),
                            ),
                            if (!isThisActive)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _vm.activeDownloadId != null
                                    ? null
                                    : () async {
                                        final res =
                                            await _vm.downloadCaption(cap);
                                        _showFeedbackSnackBar(res);
                                      },
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 15,
                                ),
                                label: const Text('.VTT'),
                              ),
                          ],
                        ),
                        if (isThisActive) ...[
                          const SizedBox(height: 6),
                          _InlineTileProgressBar(
                            tileId: tileId,
                            progress: null,
                            stageLabel: _vm.downloadStageLabel,
                            accent: cfg.accent,
                            textColor: cfg.primaryText,
                            onCancel: _vm.cancelActiveDownload,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        if (info.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _StudioCard(
            config: cfg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Video Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cfg.primaryText,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _copyText(info.description, 'description'),
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
                Text(
                  info.description,
                  maxLines: _descriptionExpanded ? null : 5,
                  overflow: _descriptionExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: cfg.primaryText.withValues(alpha: 0.8),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                    child: Text(
                      _descriptionExpanded ? 'Show less' : 'Read full description',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLibraryView(YtThemeConfig cfg) {
    final allItems = _vm.savedItems;
    final items = _vm.filteredSavedItems;
    final totalBytes =
        allItems.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _StudioCard(
          config: cfg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_special_rounded, color: cfg.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Downloads Library',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: cfg.primaryText,
                          ),
                        ),
                        Text(
                          '${allItems.length} saved files • $totalMb MB stored on device',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cfg.primaryText.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _vm.openDeviceGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Open Phone Gallery'),
                  ),
                  if (allItems.isNotEmpty)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear Offline Library?'),
                            content: const Text(
                              'This removes saved copies inside the app Library. Items already exported to your phone Gallery remain in Photos.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _vm.clearLibrary();
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                      label: const Text('Clear All'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _vm.libraryFilterKind == null,
                  label: const Text('All'),
                  onSelected: (_) => _vm.setLibraryFilterKind(null),
                ),
              ),
              ...SavedMediaKind.values.map(
                (kind) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _vm.libraryFilterKind == kind,
                    label: Text(kind.badge),
                    onSelected: (_) => _vm.setLibraryFilterKind(kind),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _StudioCard(
            config: cfg,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_download_outlined,
                    size: 44,
                    color: cfg.accent.withValues(alpha: 0.75),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No saved media yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cfg.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloaded videos, audio tracks, HD covers, and subtitles appear here for offline sharing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cfg.primaryText.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: () => _vm.setSelectedNavIndex(0),
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Go to Downloader'),
                  ),
                ],
              ),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSavedLibraryTile(cfg, item),
            ),
          ),
      ],
    );
  }

  Widget _buildSavedLibraryTile(YtThemeConfig cfg, SavedMediaItem item) {
    final canSaveGallery = item.kind == SavedMediaKind.video ||
        item.kind == SavedMediaKind.thumbnail;

    return _StudioCard(
      key: ValueKey('saved_item_${item.id}'),
      config: cfg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 84,
                  height: 52,
                  child: Image.network(
                    item.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: cfg.scaffoldBg,
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        color: cfg.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cfg.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MiniBadge(label: item.formatBadge, color: cfg.accent),
                        Text(
                          item.formattedSize,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cfg.primaryText.withValues(alpha: 0.66),
                          ),
                        ),
                        if (item.savedToGallery)
                          const _MiniBadge(
                            label: 'IN GALLERY',
                            color: Color(0xFF10B981),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final res = await _vm.shareSavedItem(item);
                  if (res.isError) _showFeedbackSnackBar(res);
                },
                icon: const Icon(Icons.ios_share_rounded, size: 16),
                label: const Text('Share / Open'),
              ),
              if (canSaveGallery)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    final res = await _vm.saveItemToGallery(item);
                    _showFeedbackSnackBar(res);
                  },
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: Text(
                    item.savedToGallery ? 'Re-save Gallery' : 'Save to Gallery',
                  ),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _vm.reloadVideoFromLibrary(item),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reload'),
              ),
              IconButton(
                tooltip: 'Delete file',
                visualDensity: VisualDensity.compact,
                onPressed: () => _vm.deleteSavedItem(item),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineTileProgressBar extends StatelessWidget {
  const _InlineTileProgressBar({
    required this.tileId,
    required this.progress,
    required this.stageLabel,
    required this.accent,
    required this.textColor,
    required this.onCancel,
  });

  final String tileId;
  final double? progress;
  final String stageLabel;
  final Color accent;
  final Color textColor;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('inline_progress_$tileId'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stageLabel.isNotEmpty ? stageLabel : 'Downloading...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              TextButton.icon(
                key: ValueKey('cancel_download_$tileId'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.config,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderOverride,
  });

  final YtThemeConfig config;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderOverride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.cardSurface,
        borderRadius: BorderRadius.circular(config.cardRadius),
        border: Border.all(
          color: borderOverride ?? config.cardBorder,
          width: borderOverride != null ? 1.5 : 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({
    required this.text,
    required this.background,
  });

  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.config,
  });

  final IconData icon;
  final String label;
  final YtThemeConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: config.scaffoldBg.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: config.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
