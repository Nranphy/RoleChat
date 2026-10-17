enum ScheduleRuleKind { daily, weekly, annual, date, range }

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.roleId,
    required this.activity,
    required this.start,
    required this.end,
    required this.probability,
    this.weekdays = const [],
    this.ruleKind = ScheduleRuleKind.daily,
    this.dateFrom,
    this.dateUntil,
    this.annualMonth,
    this.annualDay,
  });
  final String id, roleId;
  String activity, start, end;
  double probability;
  List<int> weekdays;
  ScheduleRuleKind ruleKind;
  String? dateFrom, dateUntil;
  int? annualMonth, annualDay;
}
