import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';
import 'package:rolechat/shared/widgets/field_action.dart';
import 'package:rolechat/features/agents/widgets/schedule_rule_field.dart';

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
  testWidgets('schedule controls keep one compact height at both widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = ScheduleDraft()..kind = ScheduleRuleKind.date;
    addTearDown(draft.dispose);
    for (final (width, brightness) in [
      (390.0, Brightness.light),
      (900.0, Brightness.light),
      (390.0, Brightness.dark),
      (900.0, Brightness.dark),
    ]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppTheme.seeds.first, brightness),
          home: Scaffold(
            body: ScheduleRuleField(
              draft: draft,
              index: 0,
              onChanged: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InputDecorator), findsNWidgets(6));
      final borderHeights = <double>[];
      for (final field in find.byType(InputDecorator).evaluate()) {
        expect(
          tester.getSize(find.byWidget(field.widget)).height,
          FormMetrics.compactFieldHeight,
        );
        final text = find
            .descendant(
              of: find.byWidget(field.widget),
              matching: find.byType(Text),
            )
            .first;
        borderHeights.add(
          InputDecorator.containerOf(tester.element(text))!.size.height,
        );
      }
      expect(borderHeights.toSet().length, 1);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'field hover uses the outlined container without changing bounds',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: AnchoredSelect<int>(
                  label: '接口',
                  value: 0,
                  options: const {0: '默认'},
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final decorator = find.byType(InputDecorator);
      final before = tester.getRect(decorator);
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(decorator));
      await tester.pumpAndSettle();
      expect(tester.widget<InputDecorator>(decorator).decoration.filled, true);
      expect(
        tester.widget<InputDecorator>(decorator).decoration.fillColor,
        isNot(Colors.transparent),
      );
      expect(tester.getRect(decorator), before);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(
        tester.widget<InputDecorator>(decorator).decoration.fillColor,
        Colors.transparent,
      );
    },
  );
  testWidgets('time picker opens as numeric input and saves the time', (
    tester,
  ) async {
    final draft = ScheduleDraft();
    addTearDown(draft.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleRuleField(
            draft: draft,
            index: 0,
            onChanged: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is FieldAction && w.decoration.labelText == '开始时间',
      ),
    );
    await tester.pumpAndSettle();
    final inputs = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    expect(inputs, findsNWidgets(2));
    await tester.enterText(inputs.first, '14');
    await tester.enterText(inputs.last, '30');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(draft.start, const TimeOfDay(hour: 14, minute: 30));
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
