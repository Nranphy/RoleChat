import 'package:flutter/material.dart';
import '../../design/app_theme.dart';

/// Shared shell for profile editors and ordinary application dialogs.
/// Flutter date/time pickers and the license viewer retain their native layouts.
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.child})
    : title = null,
      content = null,
      actions = null;
  const AppDialog.content({
    super.key,
    this.title,
    required this.content,
    this.actions,
  }) : child = null;

  static const profileWidth = 720.0;
  static const contentWidth = 568.0;
  static const maxHeight = 780.0;
  static const inset = EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  final Widget? child, title, content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
    );
    if (child != null) {
      return Dialog(
        insetPadding: inset,
        shape: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: profileWidth,
            maxHeight: maxHeight,
          ),
          child: child,
        ),
      );
    }
    return AlertDialog(
      insetPadding: inset,
      shape: shape,
      constraints: const BoxConstraints(
        maxWidth: contentWidth,
        maxHeight: maxHeight,
      ),
      title: title,
      content: SizedBox(width: contentWidth - 48, child: content),
      actions: actions,
    );
  }
}
