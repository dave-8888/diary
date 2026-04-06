import 'package:diary_mvp/features/diary/domain/diary_entry.dart';

class CapturedMediaResult {
  const CapturedMediaResult({
    required this.type,
    required this.path,
    this.durationLabel,
    this.capturedAt,
    this.location,
  });

  final MediaType type;
  final String path;
  final String? durationLabel;
  final DateTime? capturedAt;
  final String? location;
}
