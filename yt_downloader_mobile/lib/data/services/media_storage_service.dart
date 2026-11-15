import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/yt_models.dart';

class MediaStorageService {
  MediaStorageService({
    Future<Directory> Function()? baseDirectoryResolver,
  }) : _baseDirectoryResolver =
            baseDirectoryResolver ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDirectoryResolver;

  static const String galleryAlbumName = 'YT Downloader';
  static const String _libraryFolderName = 'yt_downloader_library';
  static const String _indexFileName = 'library_index.json';

  static const MethodChannel _shareIntentChannel = MethodChannel(
    'dev.sivaprasadnk.yt_downloader_mobile/share_intent',
  );

  Future<Directory> getLibraryDirectory() async {
    final base = await _baseDirectoryResolver();
    final dir = Directory(
      '${base.path}${Platform.pathSeparator}$_libraryFolderName',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _getIndexFile() async {
    final dir = await getLibraryDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_indexFileName');
  }

  Future<String> allocateDestinationPath(String rawFileName) async {
    final dir = await getLibraryDirectory();
    final sanitized = rawFileName
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim();
    final safeName = sanitized.isEmpty ? 'youtube_media.mp4' : sanitized;

    final dotIndex = safeName.lastIndexOf('.');
    final stem = dotIndex > 0 ? safeName.substring(0, dotIndex) : safeName;
    final ext = dotIndex > 0 ? safeName.substring(dotIndex) : '';

    var candidate = File('${dir.path}${Platform.pathSeparator}$safeName');
    var counter = 2;
    while (await candidate.exists()) {
      candidate = File(
        '${dir.path}${Platform.pathSeparator}${stem}_($counter)$ext',
      );
      counter++;
    }
    return candidate.path;
  }

  Future<List<SavedMediaItem>> loadSavedItems() async {
    try {
      final indexFile = await _getIndexFile();
      if (!await indexFile.exists()) return const [];
      final raw = await indexFile.readAsString();
      if (raw.trim().isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final validItems = <SavedMediaItem>[];
      var pruned = false;

      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        final item = SavedMediaItem.fromJson(entry);
        if (item.filePath.isNotEmpty && await File(item.filePath).exists()) {
          validItems.add(item);
        } else {
          pruned = true;
        }
      }

      validItems.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      if (pruned) {
        await _persistItems(validItems);
      }
      return validItems;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persistItems(List<SavedMediaItem> items) async {
    final indexFile = await _getIndexFile();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await indexFile.writeAsString(encoded, flush: true);
  }

  Future<SavedMediaItem> registerSavedFile({
    required String videoId,
    required String title,
    required String filePath,
    required String formatBadge,
    required SavedMediaKind kind,
    bool savedToGallery = false,
  }) async {
    final file = File(filePath);
    final sizeBytes = await file.exists() ? await file.length() : 0;
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : filePath.split(Platform.pathSeparator).last;

    final newItem = SavedMediaItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_$videoId',
      videoId: videoId,
      title: title,
      fileName: fileName,
      filePath: filePath,
      formatBadge: formatBadge,
      sizeBytes: sizeBytes,
      kind: kind,
      savedAt: DateTime.now(),
      savedToGallery: savedToGallery,
    );

    final current = await loadSavedItems();
    final updated = <SavedMediaItem>[newItem, ...current];
    await _persistItems(updated);
    return newItem;
  }

  Future<SavedMediaItem> markSavedToGallery(SavedMediaItem target) async {
    final current = await loadSavedItems();
    final updatedItem = target.copyWith(savedToGallery: true);
    final updatedList = current
        .map((item) => item.id == target.id ? updatedItem : item)
        .toList();
    await _persistItems(updatedList);
    return updatedItem;
  }

  Future<void> deleteSavedItem(SavedMediaItem target) async {
    try {
      final f = File(target.filePath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}

    final current = await loadSavedItems();
    final remaining = current.where((item) => item.id != target.id).toList();
    await _persistItems(remaining);
  }

  Future<void> clearLibrary() async {
    final dir = await getLibraryDirectory();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }
    await _persistItems(const []);
  }

  Future<void> saveVideoToGallery(String filePath) async {
    await Gal.putVideo(filePath, album: galleryAlbumName);
  }

  Future<void> saveImageToGallery(String filePath) async {
    await Gal.putImage(filePath, album: galleryAlbumName);
  }

  Future<void> openGallery() async {
    await Gal.open();
  }

  Future<void> shareFile(String filePath, {String? title}) async {
    final cleanTitle = title?.trim();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: (cleanTitle != null && cleanTitle.isNotEmpty) ? cleanTitle : null,
      ),
    );
  }

  Future<void> shareText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: clean));
  }

  Future<String?> consumeInitialSharedText() async {
    try {
      final shared = await _shareIntentChannel.invokeMethod<String>(
        'getInitialSharedText',
      );
      final trimmed = shared?.trim();
      return (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  void listenForSharedText(void Function(String sharedText) onShared) {
    _shareIntentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final raw = call.arguments as String?;
        final trimmed = raw?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          onShared(trimmed);
        }
      }
    });
  }
}

