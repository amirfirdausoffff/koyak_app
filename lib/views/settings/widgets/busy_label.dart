import 'package:flutter/material.dart';

/// Button content that swaps its icon for a spinner while work runs.
class BusyLabel extends StatelessWidget {
  const BusyLabel({
    super.key,
    required this.busy,
    required this.icon,
    required this.label,
    required this.busyLabel,
  });

  final bool busy;
  final IconData icon;
  final String label;
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            busy ? busyLabel : label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
