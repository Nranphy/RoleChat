import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import '../models/preview_models.dart';

class CurrentActivity {
  const CurrentActivity(this.key, this.name, this.probability);
  final String key, name;
  final double probability;
}

abstract final class SchedulePolicy {
  static CurrentActivity match(
    RoleProfile role,
    List<ScheduleEntry> rules,
    DateTime now,
  ) {
    final local = tz.TZDateTime.from(
      now,
      role.timezone == 'UTC' ? tz.UTC : tz.getLocation(role.timezone),
    );
    for (final s in rules.reversed.where((s) => s.roleId == role.id)) {
      for (final offset in [0, -1]) {
        final day = tz.TZDateTime(
          local.location,
          local.year,
          local.month,
          local.day + offset,
        );
        final date =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final matches = switch (s.ruleKind) {
          ScheduleRuleKind.daily => true,
          ScheduleRuleKind.weekly => s.weekdays.contains(day.weekday),
          ScheduleRuleKind.annual =>
            s.annualMonth == day.month && s.annualDay == day.day,
          ScheduleRuleKind.date => s.dateFrom == date,
          ScheduleRuleKind.range =>
            date.compareTo(s.dateFrom!) >= 0 &&
                date.compareTo(s.dateUntil!) <= 0,
        };
        if (!matches) continue;
        final start = s.start.split(':').map(int.parse).toList();
        final end = s.end.split(':').map(int.parse).toList();
        final begin = tz.TZDateTime(
          local.location,
          day.year,
          day.month,
          day.day,
          start[0],
          start[1],
        );
        final cross = end[0] * 60 + end[1] < start[0] * 60 + start[1];
        final finish = tz.TZDateTime(
          local.location,
          day.year,
          day.month,
          day.day + (cross ? 1 : 0),
          end[0],
          end[1],
        );
        if (!local.isBefore(begin) && local.isBefore(finish)) {
          return CurrentActivity(
            '${s.id}:${begin.toUtc().toIso8601String()}',
            s.activity,
            s.probability / 100,
          );
        }
      }
    }
    return CurrentActivity(
      'free',
      '自由活动',
      role.defaultActivationProbability / 100,
    );
  }

  static double probability(double base, int aiCount, bool mentioned) =>
      min(1.0, base * (mentioned ? 2 : 1)) *
      max(.05, pow(2, -max(0, aiCount - 6) / 4).toDouble());
  static Duration transitionDelay(double p, Random random) => Duration(
    milliseconds:
        ((5 * (1 - p) + random.nextDouble() * (5 + 50 * (1 - p))) * 1000)
            .round(),
  );
}
