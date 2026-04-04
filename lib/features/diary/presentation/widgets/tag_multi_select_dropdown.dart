import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TagMultiSelectDropdown extends StatefulWidget {
  const TagMultiSelectDropdown({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.searchHintText,
    required this.clearSelectionText,
    required this.noResultsText,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.emptyOptionsText,
    this.deleteOptionTooltipText,
    this.onDeleteOption,
    this.enabled = true,
  });

  final String labelText;
  final String hintText;
  final String searchHintText;
  final String clearSelectionText;
  final String noResultsText;
  final String? emptyOptionsText;
  final String? deleteOptionTooltipText;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onSelectionChanged;
  final ValueChanged<String>? onDeleteOption;
  final bool enabled;

  @override
  State<TagMultiSelectDropdown> createState() => _TagMultiSelectDropdownState();
}

class _TagMultiSelectDropdownState extends State<TagMultiSelectDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant TagMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _expanded) {
      _collapse();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelection = widget.selectedValues.isNotEmpty;
    final query = _searchController.text.trim().toLowerCase();
    final selectedKeys =
        widget.selectedValues.map((tag) => tag.toLowerCase()).toSet();
    final filteredOptions = widget.options.where((tag) {
      if (query.isEmpty) {
        return true;
      }
      return tag.toLowerCase().contains(query);
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: widget.enabled ? _toggleExpanded : null,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _expanded
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hasSelection
                            ? theme.textTheme.bodyLarge
                            : theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.72),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      _expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: !_expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: CupertinoTextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            enabled: widget.enabled,
                            onChanged: (_) => setState(() {}),
                            placeholder: widget.searchHintText,
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Icon(CupertinoIcons.search, size: 18),
                            ),
                            suffix: _searchController.text.isEmpty
                                ? null
                                : CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      _requestSearchFocus();
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Icon(
                                        CupertinoIcons.clear_thick_circled,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (widget.selectedValues.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoActionButton(
                                onPressed:
                                    widget.enabled ? _clearSelection : null,
                                variant: CupertinoActionButtonVariant.plain,
                                label: widget.clearSelectionText,
                              ),
                            ),
                          ),
                        Container(
                          height: 1,
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                        Builder(
                          builder: (context) {
                            if (widget.options.isEmpty) {
                              return _buildMessage(
                                context,
                                widget.emptyOptionsText ?? widget.noResultsText,
                              );
                            }

                            if (filteredOptions.isEmpty) {
                              return _buildMessage(
                                context,
                                widget.noResultsText,
                              );
                            }

                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                itemCount: filteredOptions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 2),
                                itemBuilder: (context, index) {
                                  final tag = filteredOptions[index];
                                  final selected =
                                      selectedKeys.contains(tag.toLowerCase());
                                  return _buildOptionRow(
                                    context,
                                    tag: tag,
                                    selected: selected,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildOptionRow(
    BuildContext context, {
    required String tag,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: widget.enabled ? () => _toggleSelection(tag) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              size: 20,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.86),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (widget.onDeleteOption != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed:
                    widget.enabled ? () => widget.onDeleteOption!(tag) : null,
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 18,
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _displayText() {
    if (widget.selectedValues.isEmpty) {
      return widget.hintText;
    }
    if (widget.selectedValues.length <= 2) {
      return widget.selectedValues.join(', ');
    }
    final preview = widget.selectedValues.take(2).join(', ');
    return '$preview +${widget.selectedValues.length - 2}';
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _requestSearchFocus();
    } else {
      _collapse();
    }
  }

  void _clearSelection() {
    widget.onSelectionChanged(const <String>[]);
  }

  void _toggleSelection(String tag) {
    final next = List<String>.from(widget.selectedValues);
    final existingIndex = next.indexWhere(
      (item) => item.toLowerCase() == tag.toLowerCase(),
    );

    if (existingIndex >= 0) {
      next.removeAt(existingIndex);
    } else {
      next.add(tag);
    }

    widget.onSelectionChanged(List.unmodifiable(next));
  }

  void _collapse() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() => _expanded = false);
    }
  }

  void _requestSearchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _expanded && widget.enabled) {
        _searchFocusNode.requestFocus();
      }
    });
  }
}
