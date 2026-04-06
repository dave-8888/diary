import 'package:diary_mvp/features/diary/domain/diary_entry.dart';

class ImagePreviewData {
  const ImagePreviewData({
    required this.media,
    this.entryCreatedAt,
    this.location,
  });

  final DiaryMedia media;
  final DateTime? entryCreatedAt;
  final String? location;
}
