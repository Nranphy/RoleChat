import 'package:flutter/material.dart';
import '../../design/form_metrics.dart';

/// Shared chrome; callers own tabs, draft values and save behavior.
class ProfileDialogFrame extends StatelessWidget {
  const ProfileDialogFrame({
    super.key,
    required this.title,
    required this.tabs,
    required this.child,
    required this.onSave,
    required this.saving,
    this.saveLabel = '保存',
    this.maxWidth = 720,
    this.maxHeight = 780,
    this.tabGap = 6,
  });
  final String title, saveLabel;
  final Widget tabs, child;
  final VoidCallback onSave;
  final bool saving;
  final double maxWidth, maxHeight, tabGap;
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          tabs,
          SizedBox(height: tabGap),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: child,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: FormMetrics.dialogActionStyle,
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FormMetrics.dialogActionStyle,
                  onPressed: saving ? null : onSave,
                  child: Text(saving ? '保存中…' : saveLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
