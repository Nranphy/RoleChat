import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';
import 'package:rolechat/shared/widgets/editor_section.dart';
import 'package:rolechat/shared/widgets/field_action.dart';

const ruleLabels = {
  ScheduleRuleKind.daily: '每天',
  ScheduleRuleKind.weekly: '每周',
  ScheduleRuleKind.annual: '每年某一天',
  ScheduleRuleKind.date: '具体日期',
  ScheduleRuleKind.range: '日期范围',
};

/// Editing state keeps conditions separate from activity and time-of-day.
class ScheduleDraft {
  ScheduleDraft([ScheduleEntry? entry])
    : id = entry?.id,
      activity = TextEditingController(text: entry?.activity ?? ''),
      start = parseTime(entry?.start ?? '09:00'),
      end = parseTime(entry?.end ?? '12:00'),
      probability = entry?.probability ?? 80 {
    final condition = entry?.condition ?? '每天';
    kind =
        entry?.ruleKind ??
        (condition.startsWith('每周')
            ? ScheduleRuleKind.weekly
            : ruleLabels.entries
                      .where((e) => e.value == condition)
                      .firstOrNull
                      ?.key ??
                  ScheduleRuleKind.daily);
    weekdays = {...entry?.weekdays ?? []};
    if (kind == ScheduleRuleKind.weekly && weekdays.isEmpty) {
      weekdays = condition == '每周六、日' ? {6, 7} : {1, 2, 3, 4, 5};
    }
    final parts = (entry?.dateDetail ?? '').split(' ~ ');
    from = entry?.annualMonth != null && entry?.annualDay != null
        ? DateTime(2024, entry!.annualMonth!, entry.annualDay!)
        : parseDate(
            entry?.dateFrom ?? parts.first,
            kind == ScheduleRuleKind.annual,
          );
    until = entry?.dateUntil != null
        ? parseDate(entry!.dateUntil!, false)
        : parts.length > 1
        ? parseDate(parts.last, false)
        : from;
  }
  final String? id;
  final TextEditingController activity;
  late ScheduleRuleKind kind;
  late Set<int> weekdays;
  late DateTime from, until;
  TimeOfDay start, end;
  double probability;
  static TimeOfDay parseTime(String text) {
    final parts = text.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts.last) ?? 0 : 0,
    );
  }

  static DateTime parseDate(String text, bool annual) =>
      DateTime.tryParse(annual ? '2024-$text' : text) ?? DateTime.now();
  static String dateText(DateTime date, {bool annual = false}) {
    final monthDay =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return annual ? monthDay : '${date.year}-$monthDay';
  }

  static String timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  ScheduleEntry toEntry(String roleId, String newId) => ScheduleEntry(
    id: id ?? newId,
    roleId: roleId,
    activity: activity.text.trim(),
    condition: ruleLabels[kind]!,
    ruleKind: kind,
    dateFrom: [ScheduleRuleKind.date, ScheduleRuleKind.range].contains(kind)
        ? dateText(from)
        : null,
    dateUntil: kind == ScheduleRuleKind.range ? dateText(until) : null,
    annualMonth: kind == ScheduleRuleKind.annual ? from.month : null,
    annualDay: kind == ScheduleRuleKind.annual ? from.day : null,
    weekdays: weekdays.toList()..sort(),
    start: timeText(start),
    end: timeText(end),
    probability: probability,
    dateDetail: switch (kind) {
      ScheduleRuleKind.annual => dateText(from, annual: true),
      ScheduleRuleKind.date => dateText(from),
      ScheduleRuleKind.range => '${dateText(from)} ~ ${dateText(until)}',
      _ => '',
    },
  );
  void dispose() => activity.dispose();
}

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
