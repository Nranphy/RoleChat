import '../editing/schedule_draft.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';
import 'package:rolechat/shared/widgets/editor_section.dart';
import 'package:rolechat/shared/widgets/field_action.dart';

class ScheduleRuleField extends StatelessWidget {
  const ScheduleRuleField({
    super.key,
    required this.draft,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });
  final ScheduleDraft draft;
  final int index;
  final VoidCallback onChanged, onDelete;
  @override
  Widget build(BuildContext context) => EditableEntryCard(
    title: '活动 ${index + 1}',
    deleteTooltip: '删除行程',
    onDelete: onDelete,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: draft.activity,
        style: FormMetrics.textStyle,
        decoration: FormMetrics.decoration('活动内容', compact: true),
        validator: (v) => v == null || v.trim().isEmpty ? '请输入活动名称' : null,
      ),
      const SizedBox(height: 10),
      AnchoredSelect<ScheduleRuleKind>(
        label: '日期条件',
        compact: true,
        value: draft.kind,
        options: ruleLabels,
        onChanged: (v) {
          draft.kind = v;
          onChanged();
        },
      ),
      if (draft.kind == ScheduleRuleKind.weekly)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: List.generate(
              7,
              (i) => FilterChip(
                label: Text(['一', '二', '三', '四', '五', '六', '日'][i]),
                selected: draft.weekdays.contains(i + 1),
                visualDensity: VisualDensity.compact,
                onSelected: (v) {
                  v ? draft.weekdays.add(i + 1) : draft.weekdays.remove(i + 1);
                  onChanged();
                },
              ),
            ),
          ),
        ),
      if ([
        ScheduleRuleKind.annual,
        ScheduleRuleKind.date,
        ScheduleRuleKind.range,
      ].contains(draft.kind))
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(child: dateButton(context, false)),
              if (draft.kind == ScheduleRuleKind.range) ...[
                const SizedBox(width: 8),
                Expanded(child: dateButton(context, true)),
              ],
            ],
          ),
        ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final timeRange = Row(
            children: [
              Expanded(child: timeButton(context, false)),
              const SizedBox(width: 8),
              Expanded(child: timeButton(context, true)),
            ],
          );
          final probability = AnchoredSelect<int>(
            label: '接收概率',
            compact: true,
            value: draft.probability.round(),
            options: {
              for (var i = 0; i <= 100; i += 5) i: '$i%',
              draft.probability.round(): '${draft.probability.round()}%',
            },
            onChanged: (v) {
              draft.probability = v.toDouble();
              onChanged();
            },
          );
          return constraints.maxWidth >= 480
              ? Row(
                  children: [
                    Expanded(flex: 2, child: timeRange),
                    const SizedBox(width: 8),
                    Expanded(child: probability),
                  ],
                )
              : Column(
                  children: [
                    timeRange,
                    const SizedBox(height: 10),
                    probability,
                  ],
                );
        },
      ),
      if (draft.end.hour * 60 + draft.end.minute <=
          draft.start.hour * 60 + draft.start.minute)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('结束时间属于次日', style: Theme.of(context).textTheme.bodySmall),
        ),
    ],
  );
  Widget dateButton(BuildContext context, bool last) {
    final annual = draft.kind == ScheduleRuleKind.annual;
    final value = last ? draft.until : draft.from;
    return FieldAction(
      decoration: FormMetrics.decoration(
        annual
            ? '月日'
            : last
            ? '结束日期'
            : '日期',
        compact: true,
      ),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: last ? draft.from : DateTime(1900),
          lastDate: DateTime(2200),
          helpText: annual
              ? '选择月日（每年重复）'
              : last
              ? '结束日期'
              : '开始日期',
        );
        if (selected == null) return;
        if (last) {
          draft.until = selected;
        } else {
          draft.from = selected;
          if (draft.until.isBefore(selected)) draft.until = selected;
        }
        onChanged();
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              ScheduleDraft.dateText(value, annual: annual),
              style: FormMetrics.textStyle,
            ),
          ),
          const Icon(Icons.calendar_today_outlined, size: 18),
        ],
      ),
    );
  }

  Widget timeButton(BuildContext context, bool last) => FieldAction(
    decoration: FormMetrics.decoration(last ? '结束时间' : '开始时间', compact: true),
    onTap: () async {
      final selected = await showTimePicker(
        context: context,
        initialEntryMode: TimePickerEntryMode.inputOnly,
        initialTime: last ? draft.end : draft.start,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (selected == null) return;
      if (last) {
        draft.end = selected;
      } else {
        draft.start = selected;
      }
      onChanged();
    },
    child: Row(
      children: [
        Expanded(
          child: Text(
            ScheduleDraft.timeText(last ? draft.end : draft.start),
            style: FormMetrics.textStyle,
          ),
        ),
        const Icon(Icons.schedule, size: 18),
      ],
    ),
  );
}
