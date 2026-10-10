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
    kind = entry?.ruleKind ?? ScheduleRuleKind.daily;
    weekdays = {...entry?.weekdays ?? []};
    final today = DateTime.now();
    from = switch (kind) {
      ScheduleRuleKind.annual => DateTime(
        2024,
        entry!.annualMonth!,
        entry.annualDay!,
      ),
      ScheduleRuleKind.date ||
      ScheduleRuleKind.range => DateTime.parse(entry!.dateFrom!),
      ScheduleRuleKind.daily || ScheduleRuleKind.weekly => today,
    };
    until = kind == ScheduleRuleKind.range
        ? DateTime.parse(entry!.dateUntil!)
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
    if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(text)) {
      throw const FormatException('Time must use HH:mm format');
    }
    final parts = text.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

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
  );
  void dispose() => activity.dispose();
}
