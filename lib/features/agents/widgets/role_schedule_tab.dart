import '../editing/schedule_draft.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/editor_section.dart';
import 'schedule_rule_field.dart';

class RoleScheduleTab extends StatelessWidget {
  const RoleScheduleTab({
    super.key,
    required this.schedules,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
  });
  final List<ScheduleDraft> schedules;
  final VoidCallback onAdd, onChanged;
  final ValueChanged<int> onDelete;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      EditorSectionNote('用于 Agent 的角色扮演。', onAdd: onAdd),
      if (schedules.isEmpty) EditorEmptyState('暂无行程'),
      ...schedules.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ScheduleRuleField(
            key: ObjectKey(e.value),
            draft: e.value,
            index: e.key,
            onChanged: onChanged,
            onDelete: () => onDelete(e.key),
          ),
        ),
      ),
    ],
  );
}
