import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A form field wrapper that places a bold label ABOVE the input field,
/// matching the modern pattern: label on top, clean input box below.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final IconData? icon;
  final bool readOnly;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.icon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            if (readOnly)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppColors.textMuted),
              ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
