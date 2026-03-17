import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DiaryEntryAiAnalysis serializes analyzedAt', () {
    final analyzedAt = DateTime(2026, 3, 18, 9, 45);
    final analysis = DiaryEntryAiAnalysis(
      overviewText: 'A calm evening',
      suggestedTags: const ['#calm', '#evening'],
      emotionalSupportText: 'You slowed down and recovered.',
      questionSuggestionText: 'Keep one quiet hour for yourself.',
      analyzedAt: analyzedAt,
    );

    final decoded = DiaryEntryAiAnalysis.fromJson(
        Map<String, dynamic>.from(analysis.toJson()));

    expect(decoded.overviewText, analysis.overviewText);
    expect(decoded.suggestedTags, analysis.suggestedTags);
    expect(decoded.emotionalSupportText, analysis.emotionalSupportText);
    expect(decoded.questionSuggestionText, analysis.questionSuggestionText);
    expect(decoded.analyzedAt, analyzedAt);
  });

  test('DiaryEntryAiAnalysis stays compatible with legacy JSON', () {
    final decoded = DiaryEntryAiAnalysis.fromJson({
      'overview_text': 'Legacy overview',
      'suggested_tags': ['#legacy'],
      'emotional_support_text': 'Be gentle with yourself.',
      'question_suggestion_text': 'Rest first.',
    });

    expect(decoded.overviewText, 'Legacy overview');
    expect(decoded.suggestedTags, ['#legacy']);
    expect(decoded.emotionalSupportText, 'Be gentle with yourself.');
    expect(decoded.questionSuggestionText, 'Rest first.');
    expect(decoded.analyzedAt, isNull);
  });
}
