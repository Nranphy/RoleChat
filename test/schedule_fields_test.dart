import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/widgets/anchored_select.dart';
import 'package:rolechat/widgets/schedule_rule_field.dart';

void main() {
  testWidgets('long selector stays below its field and scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 330, 20, 0),
            child: Column(
              children: [
                AnchoredSelect<int>(
                  label: '概率',
                  value: 0,
                  options: {for (var i = 0; i <= 100; i += 5) i: '$i%'},
                  onChanged: (v) => selected = v,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final field = find.byType(AnchoredSelect<int>);
    final bottom = tester.getBottomLeft(field).dy;
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(PopupMenuItem<int>).first).dy,
      greaterThan(bottom),
    );
    await tester.tap(find.text('10%'));
    await tester.pumpAndSettle();
    expect(selected, 10);
    expect(tester.takeException(), isNull);
  });
  test('annual and date range rules retain structured conditions', () {
    final annual = ScheduleDraft(
      ScheduleEntry(
        id: 'annual',
        roleId: 'lin',
        activity: '生日',
        condition: '每年某一天',
        dateDetail: '02-29',
        start: '23:00',
        end: '08:00',
        probability: 5,
      ),
    );
    final saved = annual.toEntry('lin', 'unused');
    expect(saved.ruleKind, ScheduleRuleKind.annual);
    expect(saved.annualMonth, 2);
    expect(saved.annualDay, 29);
    expect(saved.start, '23:00');
    expect(saved.end, '08:00');
    annual.dispose();
    final range = ScheduleDraft()
      ..kind = ScheduleRuleKind.range
      ..from = DateTime(2026, 10, 11)
      ..until = DateTime(2026, 10, 15);
    final copy = ScheduleDraft(range.toEntry('lin', 'range'));
    expect(copy.from, DateTime(2026, 10, 11));
    expect(copy.until, DateTime(2026, 10, 15));
    range.dispose();
    copy.dispose();
  });
}
