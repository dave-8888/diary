import 'package:flutter/material.dart';

class ContextTooltip extends StatelessWidget {
  const ContextTooltip({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.iconSize = 18,
    this.padding = const EdgeInsets.all(4),
    this.color,
  });

  final String message;
  final IconData icon;
  final double iconSize;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    final iconColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Tooltip(
      message: normalized,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 4),
      child: IconButton(
        onPressed: () {},
        visualDensity: VisualDensity.compact,
        splashRadius: 16,
        padding: padding,
        iconSize: iconSize,
        color: iconColor,
        icon: Icon(icon),
      ),
    );
  }
}
