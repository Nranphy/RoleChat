import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';

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
