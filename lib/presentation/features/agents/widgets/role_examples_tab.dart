import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/editor_section.dart';
import 'package:rolechat/presentation/theme/form_metrics.dart';

class RoleExamplesTab extends StatelessWidget {
  const RoleExamplesTab({
    super.key,
    required this.examples,
    required this.onAdd,
    required this.onDelete,
  });
  final List<(TextEditingController, TextEditingController)> examples;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      EditorSectionNote('供 Agent 参考对话风格。', onAdd: onAdd),
      if (examples.isEmpty) EditorEmptyState('暂无样例'),
      ...examples.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EditableEntryCard(
            title: '示例 ${e.key + 1}',
            deleteTooltip: '移除示例',
            onDelete: () => onDelete(e.key),
            children: [
              TextField(
                controller: e.value.$1,
                style: FormMetrics.textStyle,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                decoration: FormMetrics.decoration('user'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: e.value.$2,
                style: FormMetrics.textStyle,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                decoration: FormMetrics.decoration('assistant'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
