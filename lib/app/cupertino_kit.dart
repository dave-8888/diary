import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum CupertinoActionButtonVariant { filled, tinted, outline, plain }

class CupertinoActionButton extends StatelessWidget {
  const CupertinoActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isBusy = false,
    this.variant = CupertinoActionButtonVariant.filled,
    this.destructive = false,
    this.expand = false,
    this.minHeight = 46,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;
  final CupertinoActionButtonVariant variant;
  final bool destructive;
  final bool expand;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = destructive ? colorScheme.error : colorScheme.primary;
    final isDark = colorScheme.brightness == Brightness.dark;
    final enabled = onPressed != null && !isBusy;

    final (backgroundColor, foregroundColor, borderColor) = switch (variant) {
      CupertinoActionButtonVariant.filled => (
          destructive ? colorScheme.error : accent,
          destructive ? colorScheme.onError : colorScheme.onPrimary,
          Colors.transparent,
        ),
      CupertinoActionButtonVariant.tinted => (
          accent.withValues(alpha: isDark ? 0.18 : 0.08),
          accent,
          accent.withValues(alpha: isDark ? 0.24 : 0.14),
        ),
      CupertinoActionButtonVariant.outline => (
          theme.cardTheme.color?.withValues(alpha: isDark ? 0.6 : 0.52) ??
              colorScheme.surface.withValues(alpha: isDark ? 0.6 : 0.52),
          destructive ? colorScheme.error : colorScheme.onSurface,
          destructive
              ? colorScheme.error.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      CupertinoActionButtonVariant.plain => (
          Colors.transparent,
          accent,
          Colors.transparent,
        ),
    };

    final content = DefaultTextStyle.merge(
      style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ) ??
          TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
      child: IconTheme(
        data: IconThemeData(
          color: foregroundColor,
          size: 18,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy)
              CupertinoActivityIndicator(color: foregroundColor)
            else if (icon != null)
              Icon(icon),
            if (isBusy || icon != null) const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled || isBusy ? 1 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight,
              minWidth: expand ? double.infinity : 0,
            ),
            child: Padding(
              padding: padding,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class CupertinoPill extends StatelessWidget {
  const CupertinoPill({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onPressed,
    this.selected = false,
    this.destructive = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final Widget label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool selected;
  final bool destructive;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = destructive ? colorScheme.error : colorScheme.primary;
    final isDark = colorScheme.brightness == Brightness.dark;
    final backgroundColor = selected
        ? accent.withValues(alpha: isDark ? 0.2 : 0.08)
        : (theme.cardTheme.color?.withValues(alpha: isDark ? 0.58 : 0.48) ??
            colorScheme.surface.withValues(alpha: isDark ? 0.58 : 0.48));
    final foregroundColor = selected
        ? accent
        : (destructive ? colorScheme.error : colorScheme.onSurfaceVariant);
    final borderColor = selected
        ? accent.withValues(alpha: isDark ? 0.28 : 0.16)
        : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.42 : 0.28);

    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ) ??
              TextStyle(
                color: foregroundColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
          child: IconTheme(
            data: IconThemeData(
              color: foregroundColor,
              size: 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ] else if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 8),
                ],
                label,
              ],
            ),
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return body;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: body,
    );
  }
}

Future<bool> showCupertinoConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool isDestructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        CupertinoDialogAction(
          isDefaultAction: !isDestructive,
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return result ?? false;
}
