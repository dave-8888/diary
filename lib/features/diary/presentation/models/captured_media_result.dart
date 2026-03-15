import 'package:diary_mvp/features/diary/domain/diary_entry.dart';

class CapturedMediaResult {
  const CapturedMediaResult({
    required this.type,
    required this.path,
    this.durationLabel,
  });

  final MediaType type;
  final String path;
  final String? durationLabel;
}
