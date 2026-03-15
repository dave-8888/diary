import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DiaryMood value;
  final ValueChanged<DiaryMood> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: DiaryMood.values.map((mood) {
        final selected = mood == value;
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => onChanged(mood),
          label: Text('${mood.emoji} ${mood.label}'),
        );
      }).toList(),
    );
  }
}
