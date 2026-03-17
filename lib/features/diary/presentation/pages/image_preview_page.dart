import 'dart:io';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ImagePreviewPage extends StatelessWidget {
  const ImagePreviewPage({
    super.key,
    this.media,
  });

  final DiaryMedia? media;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final image = media;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.imagePreviewPageTitle),
      ),
      body: SafeArea(
        child: image == null
            ? Center(child: Text(strings.noImageSelected))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final theme = Theme.of(context);
                  final detailCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings.previewPhoto,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.mediaLabel(
                              image,
                              baseName: p.basename(image.path),
                            ),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  );

                  final previewHeight = constraints.maxWidth >= 1024
                      ? (constraints.maxHeight - 24)
                          .clamp(420.0, 760.0)
                          .toDouble()
                      : (constraints.maxHeight * 0.56)
                          .clamp(280.0, 520.0)
                          .toDouble();

                  final previewPanel = ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: SizedBox(
                        height: previewHeight,
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
                  );

                  if (constraints.maxWidth >= 1024) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: previewPanel),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 280,
                            child: detailCard,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      previewPanel,
                      const SizedBox(height: 20),
                      detailCard,
                    ],
                  );
                },
              ),
      ),
    );
  }
}
