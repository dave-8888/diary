import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.moods,
    required this.valueId,
    required this.onChanged,
  });

  final List<DiaryMood> moods;
  final String valueId;
  final ValueChanged<DiaryMood> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: moods.map((mood) {
        final selected = mood.id == valueId;
        return CupertinoPill(
          selected: selected,
          onPressed: () => onChanged(mood),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                mood.emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(strings.moodLabel(mood)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );
      }).toList(growable: false),
    );
  }
}
