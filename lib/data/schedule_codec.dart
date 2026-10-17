import '../models/preview_models.dart';

abstract final class ScheduleCodec {
  static Map<String, dynamic> encode(ScheduleEntry s) => {
    'id': s.id,
    'activity': s.activity,
    'start': s.start,
    'end': s.end,
    'probability': s.probability,
    'weekdays': s.weekdays,
    'ruleKind': s.ruleKind.name,
    'dateFrom': s.dateFrom,
    'dateUntil': s.dateUntil,
    'annualMonth': s.annualMonth,
    'annualDay': s.annualDay,
  };
  static ScheduleEntry decode(Map<String, dynamic> j, String roleId) {
    final s = ScheduleEntry(
      id: j['id'] as String,
      roleId: roleId,
      activity: j['activity'] as String,
      start: j['start'] as String,
      end: j['end'] as String,
      probability: (j['probability'] as num).toDouble(),
      weekdays: List<int>.from(j['weekdays'] as List),
      ruleKind: ScheduleRuleKind.values.byName(j['ruleKind'] as String),
      dateFrom: j['dateFrom'] as String?,
      dateUntil: j['dateUntil'] as String?,
      annualMonth: j['annualMonth'] as int?,
      annualDay: j['annualDay'] as int?,
    );
    final time = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
    if (!time.hasMatch(s.start) ||
        !time.hasMatch(s.end) ||
        s.activity.trim().isEmpty ||
        !s.probability.isFinite ||
        s.probability < 0 ||
        s.probability > 100 ||
        s.weekdays.any((v) => v < 1 || v > 7) ||
        (s.ruleKind == ScheduleRuleKind.weekly && s.weekdays.isEmpty)) {
      throw const FormatException('行程规则无效');
    }
    if (s.ruleKind == ScheduleRuleKind.annual) {
      final date = DateTime(2024, s.annualMonth!, s.annualDay!);
      if (date.month != s.annualMonth || date.day != s.annualDay) {
        throw const FormatException('年度日期无效');
      }
    }
    if ([ScheduleRuleKind.date, ScheduleRuleKind.range].contains(s.ruleKind)) {
      final from = DateTime.parse(s.dateFrom!);
      if (s.ruleKind == ScheduleRuleKind.range &&
          DateTime.parse(s.dateUntil!).isBefore(from)) {
        throw const FormatException('行程日期范围无效');
      }
    }
    return s;
  }
}
