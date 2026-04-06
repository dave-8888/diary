import 'dart:io';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/models/image_preview_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImagePreviewPage extends StatelessWidget {
  const ImagePreviewPage({
    super.key,
    this.preview,
  });

  final ImagePreviewData? preview;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final data = preview;
    final image = data?.media;
    final theme = Theme.of(context);
    final detailTimeValue = _metadataTimeValue(
      strings,
      image,
      fallbackTime: data?.entryCreatedAt,
    );
    final detailLocationValue = _metadataLocationValue(
      strings,
      image?.location ?? data?.location,
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(strings.imagePreviewPageTitle),
      ),
      child: SafeArea(
        top: false,
        child: image == null
            ? Center(child: Text(strings.noImageSelected))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final horizontalPadding = isWide ? 28.0 : 18.0;
                  final verticalPadding = isWide ? 24.0 : 16.0;
                  final detailContent = isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MetadataItem(
                                label: strings.photoUploadedAtLabel,
                                value: detailTimeValue,
                                labelStyle: theme.textTheme.labelLarge,
                                valueStyle: theme.textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Container(
                              width: 1,
                              height: 56,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _MetadataItem(
                                label: strings.photoUploadedLocationLabel,
                                value: detailLocationValue,
                                labelStyle: theme.textTheme.labelLarge,
                                valueStyle: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MetadataItem(
                              label: strings.photoUploadedAtLabel,
                              value: detailTimeValue,
                              labelStyle: theme.textTheme.labelLarge,
                              valueStyle: theme.textTheme.bodyLarge,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            _MetadataItem(
                              label: strings.photoUploadedLocationLabel,
                              value: detailLocationValue,
                              labelStyle: theme.textTheme.labelLarge,
                              valueStyle: theme.textTheme.bodyLarge,
                            ),
                          ],
                        );
                  final detailCard = Card(
                    elevation: 0,
                    color: theme.colorScheme.surface.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.88 : 0.96,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? 0.4 : 0.65,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: detailContent,
                    ),
                  );

                  final previewPanel = DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: theme.colorScheme.surface.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.86 : 0.94,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? 0.32 : 0.55,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.24
                                : 0.06,
                          ),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isWide ? 14 : 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: InteractiveViewer(
                            minScale: 0.9,
                            maxScale: 4,
                            child: Center(
                              child: Image.file(
                                File(image.path),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.broken_image_outlined,
                                    size: 56,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      14,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, 0.12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 1180 : 860,
                                maxHeight: constraints.maxHeight * 0.8,
                              ),
                              child: SizedBox.expand(
                                child: previewPanel,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 920),
                            child: detailCard,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _metadataTimeValue(
    AppStrings strings,
    DiaryMedia? media, {
    required DateTime? fallbackTime,
  }) {
    final value = media?.addedAt ?? fallbackTime;
    if (value == null) {
      return strings.notProvided;
    }
    return strings.formatDateTime(value);
  }

  String _metadataLocationValue(AppStrings strings, String? location) {
    final normalized = location?.trim();
    if (normalized == null || normalized.isEmpty) {
      return strings.notProvided;
    }
    return normalized;
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        Text(
          value,
          style: valueStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
