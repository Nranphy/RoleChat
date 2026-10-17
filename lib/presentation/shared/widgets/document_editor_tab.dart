import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/editor_section.dart';

class DocumentEditorTab extends StatelessWidget {
  const DocumentEditorTab({
    super.key,
    required this.controller,
    required this.title,
    required this.explanation,
    this.autoUpdateEnabled,
    this.onAutoUpdateChanged,
  });
  final TextEditingController controller;
  final String title, explanation;
  final bool? autoUpdateEnabled;
  final ValueChanged<bool>? onAutoUpdateChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EditorSectionNote(explanation),
      TextField(
        controller: controller,
        minLines: 10,
        maxLines: 20,
        decoration: InputDecoration(labelText: title, alignLabelWithHint: true),
      ),
      if (autoUpdateEnabled != null) ...[
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('允许自主更新', style: TextStyle(fontSize: 14)),
          subtitle: const Text('关闭后仅允许手动编辑。', style: TextStyle(fontSize: 12)),
          value: autoUpdateEnabled!,
          onChanged: onAutoUpdateChanged,
        ),
      ],
    ],
  );
}
