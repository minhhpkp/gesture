import 'package:flutter/material.dart';

class OutlinedIconButton extends StatelessWidget {
  const OutlinedIconButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon
  });

  final void Function() onPressed;
  final Widget label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      iconAlignment: IconAlignment.end, // places the icon after the label
      label: label,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }
}
