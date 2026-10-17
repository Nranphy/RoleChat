import 'package:flutter/material.dart';
import '../../design/form_metrics.dart';
import 'section_card.dart';

class EditorSectionNote extends StatelessWidget {
  const EditorSectionNote(this.explanation, {super.key, this.onAdd});
  final String explanation;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: FormMetrics.sectionActionGap),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Expanded(
            child: Text(
              explanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
        ],
      ),
    ),
  );
}

class EditorEmptyState extends StatelessWidget {
  const EditorEmptyState(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(12), child: Text(text));
}

class EditableEntryCard extends StatelessWidget {
  const EditableEntryCard({
    super.key,
    required this.title,
    required this.deleteTooltip,
    required this.onDelete,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.headerAction,
  });
  final String title, deleteTooltip;
  final VoidCallback onDelete;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget? headerAction;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            ?headerAction,
            IconButton(
              tooltip: deleteTooltip,
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}
