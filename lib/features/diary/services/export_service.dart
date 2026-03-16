import 'dart:io';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final diaryExportServiceProvider = Provider<DiaryExportService>((ref) {
  return DiaryExportService();
});

class DiaryExportResult {
  const DiaryExportResult({
    required this.directoryPath,
    required this.markdownPath,
    required this.textPath,
    required this.exportedMediaCount,
  });

  final String directoryPath;
  final String markdownPath;
  final String textPath;
  final int exportedMediaCount;
}

class DiaryExportService {
  Future<DiaryExportResult> exportEntry({
    required DiaryEntry entry,
    required String destinationRootPath,
    required AppStrings strings,
  }) async {
    final root = Directory(destinationRootPath);
    await root.create(recursive: true);

    final exportDirectory = await _createUniqueDirectory(
      root.path,
      _buildDirectoryName(entry, strings),
    );

    final exportedMedia = await _copyMediaFiles(
      media: entry.media,
      exportDirectoryPath: exportDirectory.path,
    );
    final markdownPath = p.join(exportDirectory.path, 'entry.md');
    final textPath = p.join(exportDirectory.path, 'entry.txt');

    await File(markdownPath).writeAsString(
      _buildMarkdown(
        entry: entry,
        strings: strings,
        exportedMedia: exportedMedia,
      ),
      flush: true,
    );
    await File(textPath).writeAsString(
      _buildPlainText(
        entry: entry,
        strings: strings,
        exportedMedia: exportedMedia,
      ),
      flush: true,
    );

    return DiaryExportResult(
      directoryPath: exportDirectory.path,
      markdownPath: markdownPath,
      textPath: textPath,
      exportedMediaCount: exportedMedia.length,
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

  Future<List<_ExportedMediaFile>> _copyMediaFiles({
    required List<DiaryMedia> media,
    required String exportDirectoryPath,
  }) async {
    final exported = <_ExportedMediaFile>[];
    final usedRelativePaths = <String>{};

    for (final item in media) {
      final source = File(item.path);
      if (!await source.exists()) {
        continue;
      }

      final directoryName = switch (item.type) {
        MediaType.image => 'images',
        MediaType.audio => 'audio',
        MediaType.video => 'video',
      };
      final targetDirectory = Directory(
        p.join(exportDirectoryPath, 'media', directoryName),
      );
      await targetDirectory.create(recursive: true);

      final fileName = _uniqueFileName(
        p.basename(item.path),
        usedRelativePaths,
        directoryName: directoryName,
      );
      final targetPath = p.join(targetDirectory.path, fileName);
      await source.copy(targetPath);

      final relativePath = p.posix.join('media', directoryName, fileName);
      usedRelativePaths.add(relativePath);
      exported.add(
        _ExportedMediaFile(
          media: item,
          fileName: fileName,
          relativePath: relativePath,
        ),
      );
    }

    return exported;
  }

  String _uniqueFileName(
    String originalName,
    Set<String> usedRelativePaths, {
    required String directoryName,
  }) {
    final extension = p.extension(originalName);
    final baseName =
        _sanitizeFileName(p.basenameWithoutExtension(originalName));
    var candidateBaseName = baseName.isEmpty ? 'file' : baseName;
    var index = 2;

    while (true) {
      final candidateName = '$candidateBaseName$extension';
      final relativePath = p.posix.join('media', directoryName, candidateName);
      if (!usedRelativePaths.contains(relativePath)) {
        return candidateName;
      }
      candidateBaseName = '${baseName.isEmpty ? 'file' : baseName}_$index';
      index += 1;
    }
  }

  String _buildDirectoryName(DiaryEntry entry, AppStrings strings) {
    final datePart = strings.formatDay(entry.createdAt);
    final rawTitle =
        entry.title.trim().isEmpty ? strings.untitledEntry : entry.title;
    final normalizedTitle = _sanitizeFileName(rawTitle).replaceAll(' ', '_');
    final titlePart = normalizedTitle.isEmpty ? 'entry' : normalizedTitle;
    final truncatedTitle =
        titlePart.length > 48 ? titlePart.substring(0, 48) : titlePart;
    return '${datePart}_$truncatedTitle';
  }

  String _sanitizeFileName(String input) {
    return input
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildMarkdown({
    required DiaryEntry entry,
    required AppStrings strings,
    required List<_ExportedMediaFile> exportedMedia,
  }) {
    final buffer = StringBuffer()
      ..writeln(
          '# ${entry.title.trim().isEmpty ? strings.untitledEntry : entry.title.trim()}')
      ..writeln()
      ..writeln(
          '- ${strings.createdAtLabel}: ${strings.formatDateTime(entry.createdAt)}')
      ..writeln(
          '- ${strings.mood}: ${entry.mood.emoji} ${strings.moodLabel(entry.mood)}')
      ..writeln(
        '- ${strings.locationLabel}: ${entry.location?.trim().isNotEmpty == true ? entry.location!.trim() : strings.notProvided}',
      )
      ..writeln(
        '- ${strings.tagsLabel}: ${entry.tags.isEmpty ? strings.noTagsValue : entry.tags.join(', ')}',
      )
      ..writeln()
      ..writeln('## ${strings.contentSectionTitle}')
      ..writeln()
      ..writeln(entry.content.trim().isEmpty
          ? strings.emptyContentValue
          : entry.content.trim());

    _appendMarkdownMediaSection(
      buffer: buffer,
      title: strings.imagesSectionTitle,
      media: exportedMedia
          .where((item) => item.media.type == MediaType.image)
          .toList(),
      itemBuilder: (item) => '![${item.fileName}](${item.relativePath})',
    );
    _appendMarkdownMediaSection(
      buffer: buffer,
      title: strings.audioSectionTitle,
      media: exportedMedia
          .where((item) => item.media.type == MediaType.audio)
          .toList(),
      itemBuilder: (item) =>
          '- [${strings.mediaLabel(item.media, baseName: item.fileName)}](${item.relativePath})',
    );
    _appendMarkdownMediaSection(
      buffer: buffer,
      title: strings.videoSectionTitle,
      media: exportedMedia
          .where((item) => item.media.type == MediaType.video)
          .toList(),
      itemBuilder: (item) =>
          '- [${strings.mediaLabel(item.media, baseName: item.fileName)}](${item.relativePath})',
    );

    return buffer.toString().trimRight();
  }

  String _buildPlainText({
    required DiaryEntry entry,
    required AppStrings strings,
    required List<_ExportedMediaFile> exportedMedia,
  }) {
    final buffer = StringBuffer()
      ..writeln(entry.title.trim().isEmpty
          ? strings.untitledEntry
          : entry.title.trim())
      ..writeln()
      ..writeln(
          '${strings.createdAtLabel}: ${strings.formatDateTime(entry.createdAt)}')
      ..writeln(
          '${strings.mood}: ${entry.mood.emoji} ${strings.moodLabel(entry.mood)}')
      ..writeln(
        '${strings.locationLabel}: ${entry.location?.trim().isNotEmpty == true ? entry.location!.trim() : strings.notProvided}',
      )
      ..writeln(
        '${strings.tagsLabel}: ${entry.tags.isEmpty ? strings.noTagsValue : entry.tags.join(', ')}',
      )
      ..writeln()
      ..writeln('${strings.contentSectionTitle}:')
      ..writeln(entry.content.trim().isEmpty
          ? strings.emptyContentValue
          : entry.content.trim());

    _appendPlainTextMediaSection(
      buffer: buffer,
      title: strings.imagesSectionTitle,
      media: exportedMedia
          .where((item) => item.media.type == MediaType.image)
          .toList(),
    );
    _appendPlainTextMediaSection(
      buffer: buffer,
      title: strings.audioSectionTitle,
      media: exportedMedia
          .where((item) => item.media.type == MediaType.audio)
          .toList(),
    );
    _appendPlainTextMediaSection(
      buffer: buffer,
      title: strings.videoSectionTitle,
      media: exportedMedia
          .where((item) => item.media.type == MediaType.video)
          .toList(),
    );

    return buffer.toString().trimRight();
  }

  void _appendMarkdownMediaSection({
    required StringBuffer buffer,
    required String title,
    required List<_ExportedMediaFile> media,
    required String Function(_ExportedMediaFile item) itemBuilder,
  }) {
    if (media.isEmpty) return;

    buffer
      ..writeln()
      ..writeln()
      ..writeln('## $title')
      ..writeln();

    for (final item in media) {
      buffer.writeln(itemBuilder(item));
    }
  }

  void _appendPlainTextMediaSection({
    required StringBuffer buffer,
    required String title,
    required List<_ExportedMediaFile> media,
  }) {
    if (media.isEmpty) return;

    buffer
      ..writeln()
      ..writeln()
      ..writeln('$title:');

    for (final item in media) {
      buffer.writeln('- ${item.relativePath}');
    }
  }
}

class _ExportedMediaFile {
  const _ExportedMediaFile({
    required this.media,
    required this.fileName,
    required this.relativePath,
  });

  final DiaryMedia media;
  final String fileName;
  final String relativePath;
}
