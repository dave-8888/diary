import 'dart:convert';
import 'dart:io';

import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/data/local/diary_database.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final diaryMigrationServiceProvider = Provider<DiaryMigrationService>((ref) {
  return DiaryMigrationService();
});

class MigrationExportResult {
  const MigrationExportResult({
    required this.directoryPath,
    required this.entryCount,
    required this.mediaCount,
  });

  final String directoryPath;
  final int entryCount;
  final int mediaCount;
}

class MigrationImportResult {
  const MigrationImportResult({
    required this.entryCount,
    required this.mediaCount,
  });

  final int entryCount;
  final int mediaCount;
}

class DiaryMigrationService {
  static const int _formatVersion = 1;

  Future<String> appDataRootPath() async {
    final documents = await getApplicationDocumentsDirectory();
    return p.join(documents.path, 'diary_mvp');
  }

  Future<MigrationExportResult> exportPackage({
    required String destinationRootPath,
    required List<DiaryEntry> activeEntries,
    required List<DiaryEntry> trashedEntries,
    required List<String> tagLibrary,
    required List<DiaryMood> moodLibrary,
  }) async {
    final rootDirectory = Directory(destinationRootPath);
    await rootDirectory.create(recursive: true);

    final packageDirectory = await _createUniqueDirectory(
      rootDirectory.path,
      'diary_migration_${_timestampForFileName(DateTime.now())}',
    );
    final usedRelativePaths = <String>{};
    final manifestEntries = <Map<String, Object?>>[];
    var mediaCount = 0;

    for (final entry in [...activeEntries, ...trashedEntries]) {
      final mediaRecords = <Map<String, Object?>>[];
      final mediaFolder = entry.trashedAt == null ? 'active' : 'trash';

      for (final media in entry.media) {
        final source = File(media.path);
        if (!await source.exists()) {
          continue;
        }

        final category = switch (media.type) {
          MediaType.image => 'images',
          MediaType.audio => 'audio',
          MediaType.video => 'video',
        };
        final fileName = _uniqueFileName(
          p.basename(media.path),
          usedRelativePaths,
          directorySegments: [mediaFolder, category],
        );
        final relativePath = p.posix.joinAll([
          'media',
          mediaFolder,
          category,
          fileName,
        ]);
        final targetPath = p.joinAll([
          packageDirectory.path,
          ...p.posix.split(relativePath),
        ]);
        await Directory(p.dirname(targetPath)).create(recursive: true);
        await source.copy(targetPath);
        usedRelativePaths.add(relativePath);
        mediaCount += 1;

        mediaRecords.add({
          'id': media.id,
          'type': media.type.name,
          'relative_path': relativePath,
          'duration_label': media.durationLabel,
        });
      }

      manifestEntries.add({
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'mood': entry.mood.id,
        'created_at': entry.createdAt.millisecondsSinceEpoch,
        'location': entry.location,
        'trashed_at': entry.trashedAt?.millisecondsSinceEpoch,
        'tags': entry.tags,
        'media': mediaRecords,
      });
    }

    final manifest = <String, Object?>{
      'app': 'diary_mvp',
      'format_version': _formatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'entry_count': manifestEntries.length,
      'media_count': mediaCount,
      'tag_library': tagLibrary,
      'mood_library': moodLibrary
          .map(
            (mood) => {
              'id': mood.id,
              'label': mood.label,
              'emoji': mood.emoji,
              'sort_order': mood.sortOrder,
              'is_default': mood.isDefault,
            },
          )
          .toList(growable: false),
      'entries': manifestEntries,
    };

    await File(p.join(packageDirectory.path, 'manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );

    return MigrationExportResult(
      directoryPath: packageDirectory.path,
      entryCount: manifestEntries.length,
      mediaCount: mediaCount,
    );
  }

  Future<MigrationImportResult> importPackage({
    required String sourceDirectoryPath,
    required DiaryDatabase currentDatabase,
    required LocalStorageService storage,
  }) async {
    final sourceDirectory = Directory(sourceDirectoryPath);
    if (!await sourceDirectory.exists()) {
      throw StateError(
          'Migration package does not exist: $sourceDirectoryPath');
    }

    final manifest = await _readManifest(sourceDirectory.path);
    final appRoot = await storage.appRootDirectory();
    final temporaryDirectory = await getTemporaryDirectory();
    final backupDirectory = Directory(
      p.join(
        temporaryDirectory.path,
        'diary_mvp_backup_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    if (await appRoot.exists()) {
      await _copyDirectory(appRoot, backupDirectory);
    }

    DiaryDatabase? importedDatabase;
    try {
      await currentDatabase.close();
      await _replaceCurrentAppData(
        appRoot: appRoot,
        sourceDirectory: sourceDirectory,
        manifest: manifest,
        storage: storage,
      );

      importedDatabase = DiaryDatabase();
      await importedDatabase.replaceMoodLibrary(manifest.moodLibrary);
      var mediaCount = 0;
      for (final entry in manifest.entries) {
        mediaCount += entry.media.length;
        await importedDatabase
            .insertEntry(entry.toDiaryEntry(manifest.moodMap));
      }
      await importedDatabase.upsertTagLibrary(manifest.tagLibrary);
      await importedDatabase.close();

      if (await backupDirectory.exists()) {
        await backupDirectory.delete(recursive: true);
      }

      return MigrationImportResult(
        entryCount: manifest.entries.length,
        mediaCount: mediaCount,
      );
    } catch (error) {
      if (importedDatabase != null) {
        await importedDatabase.close();
      }
      await _deleteDirectoryIfExists(appRoot);
      if (await backupDirectory.exists()) {
        await _copyDirectory(backupDirectory, appRoot);
        await backupDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _replaceCurrentAppData({
    required Directory appRoot,
    required Directory sourceDirectory,
    required _MigrationManifest manifest,
    required LocalStorageService storage,
  }) async {
    await _deleteDirectoryIfExists(appRoot);
    await appRoot.create(recursive: true);

    for (final entry in manifest.entries) {
      final isTrashed = entry.trashedAt != null;
      for (final media in entry.media) {
        final sourcePath = p.joinAll([
          sourceDirectory.path,
          ...p.posix.split(media.relativePath),
        ]);
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          throw StateError(
              'Missing media file in migration package: $sourcePath');
        }

        final targetDirectory = await storage.mediaDirectoryForType(
          media.type,
          useTrash: isTrashed,
        );
        await targetDirectory.create(recursive: true);
        final targetPath =
            p.join(targetDirectory.path, p.basename(media.relativePath));
        await sourceFile.copy(targetPath);
        media.absolutePath = targetPath;
      }
    }
  }

  Future<_MigrationManifest> _readManifest(String packageDirectoryPath) async {
    final manifestFile = File(p.join(packageDirectoryPath, 'manifest.json'));
    if (!await manifestFile.exists()) {
      throw const FormatException(
          'manifest.json was not found in the migration package.');
    }

    final raw = jsonDecode(await manifestFile.readAsString());
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('manifest.json is invalid.');
    }

    final formatVersion = raw['format_version'];
    if (formatVersion is! int || formatVersion != _formatVersion) {
      throw FormatException(
          'Unsupported migration format version: $formatVersion');
    }

    final entriesRaw = raw['entries'];
    if (entriesRaw is! List) {
      throw const FormatException('entries field is missing or invalid.');
    }

    final tagsRaw = raw['tag_library'];
    final tagLibrary = tagsRaw is List
        ? tagsRaw.whereType<String>().toList(growable: false)
        : const <String>[];
    final moodLibraryRaw = raw['mood_library'];
    final moodLibrary = moodLibraryRaw is List
        ? moodLibraryRaw
            .map(
                (item) => _MigrationMood.fromJson(item as Map<String, dynamic>))
            .map((item) => item.toDiaryMood())
            .toList(growable: false)
        : DiaryMood.values;

    return _MigrationManifest(
      tagLibrary: tagLibrary,
      moodLibrary: moodLibrary,
      entries: entriesRaw
          .map((entry) =>
              _MigrationEntry.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Future<Directory> _createUniqueDirectory(
    String rootPath,
    String baseName,
  ) async {
    var candidateName = baseName;
    var index = 2;

    while (true) {
      final candidate = Directory(p.join(rootPath, candidateName));
      if (!await candidate.exists()) {
        await candidate.create(recursive: true);
        return candidate;
      }
      candidateName = '$baseName ($index)';
      index += 1;
    }
  }

  String _uniqueFileName(
    String originalName,
    Set<String> usedRelativePaths, {
    required List<String> directorySegments,
  }) {
    final extension = p.extension(originalName);
    final baseName =
        _sanitizeFileName(p.basenameWithoutExtension(originalName));
    var candidateBaseName = baseName.isEmpty ? 'file' : baseName;
    var index = 2;

    while (true) {
      final candidateName = '$candidateBaseName$extension';
      final relativePath = p.posix.joinAll([
        'media',
        ...directorySegments,
        candidateName,
      ]);
      if (!usedRelativePaths.contains(relativePath)) {
        return candidateName;
      }
      candidateBaseName = '${baseName.isEmpty ? 'file' : baseName}_$index';
      index += 1;
    }
  }

  String _sanitizeFileName(String input) {
    return input
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _timestampForFileName(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute$second';
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final target =
            Directory(p.join(destination.path, p.basename(entity.path)));
        await _copyDirectory(entity, target);
      } else if (entity is File) {
        final target = File(p.join(destination.path, p.basename(entity.path)));
        await target.parent.create(recursive: true);
        await entity.copy(target.path);
      }
    }
  }

  Future<void> _deleteDirectoryIfExists(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

class _MigrationManifest {
  const _MigrationManifest({
    required this.tagLibrary,
    required this.moodLibrary,
    required this.entries,
  });

  final List<String> tagLibrary;
  final List<DiaryMood> moodLibrary;
  final List<_MigrationEntry> entries;

  Map<String, DiaryMood> get moodMap => {
        for (final mood in moodLibrary) mood.id: mood,
      };
}

class _MigrationEntry {
  const _MigrationEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.moodId,
    required this.createdAt,
    required this.location,
    required this.trashedAt,
    required this.tags,
    required this.media,
  });

  factory _MigrationEntry.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'];
    return _MigrationEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      moodId: json['mood'] as String? ?? DiaryMood.neutralId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      location: json['location'] as String?,
      trashedAt: json['trashed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['trashed_at'] as int),
      tags: (json['tags'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      media: (mediaRaw as List? ?? const [])
          .map((item) => _MigrationMedia.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String id;
  final String title;
  final String content;
  final String moodId;
  final DateTime createdAt;
  final String? location;
  final DateTime? trashedAt;
  final List<String> tags;
  final List<_MigrationMedia> media;

  DiaryEntry toDiaryEntry(Map<String, DiaryMood> moodLibrary) {
    return DiaryEntry(
      id: id,
      title: title,
      content: content,
      mood: moodLibrary[moodId] ?? DiaryMood.byId(moodId) ?? DiaryMood.neutral,
      createdAt: createdAt,
      location: location,
      trashedAt: trashedAt,
      tags: tags,
      media: media
          .map(
            (item) => DiaryMedia(
              id: item.id,
              type: item.type,
              path: item.absolutePath ?? '',
              durationLabel: item.durationLabel,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MigrationMood {
  const _MigrationMood({
    required this.id,
    required this.label,
    required this.emoji,
    required this.sortOrder,
    required this.isDefault,
  });

  factory _MigrationMood.fromJson(Map<String, dynamic> json) {
    return _MigrationMood(
      id: json['id'] as String? ?? DiaryMood.neutralId,
      label: json['label'] as String? ?? '',
      emoji: json['emoji'] as String? ?? DiaryMood.neutral.emoji,
      sortOrder: json['sort_order'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  final String id;
  final String label;
  final String emoji;
  final int sortOrder;
  final bool isDefault;

  DiaryMood toDiaryMood() {
    return DiaryMood(
      id: id,
      label: label,
      emoji: emoji,
      sortOrder: sortOrder,
      isDefault: isDefault,
    );
  }
}

class _MigrationMedia {
  _MigrationMedia({
    required this.id,
    required this.type,
    required this.relativePath,
    required this.durationLabel,
  });

  factory _MigrationMedia.fromJson(Map<String, dynamic> json) {
    return _MigrationMedia(
      id: json['id'] as String,
      type: _parseMediaType(json['type'] as String?),
      relativePath: json['relative_path'] as String,
      durationLabel: json['duration_label'] as String?,
    );
  }

  final String id;
  final MediaType type;
  final String relativePath;
  final String? durationLabel;
  String? absolutePath;

  static MediaType _parseMediaType(String? raw) {
    return MediaType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => MediaType.image,
    );
  }
}
