import 'fixtures/test_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/main.dart';
import 'package:rolechat/features/agents/agent_dialogs.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';

void main() {
  testWidgets(
    'role editor keeps runtime fields compact and saves locks from their tabs',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [
        const Size(390, 844),
        const Size(1280, 900),
        const Size(1280, 720),
      ]) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          tester.view.physicalSize = size;
          SharedPreferences.setMockInitialValues({});
          final store = createTestStore(await SharedPreferences.getInstance());
          await store.setMode(mode);
          await tester.pumpWidget(RoleChatApp(store: store));
          await tester.pumpAndSettle();
          final role = store.roles.first;
          final schedule = store.schedules.firstWhere(
            (s) => s.roleId == role.id,
          );
          editRole(tester.element(find.byType(Scaffold)), store, role: role);
          await tester.pumpAndSettle();
          expect(find.text('模型连接'), findsOneWidget);
          expect(find.widgetWithText(TextField, '时区'), findsNothing);
          final timezone = find.byWidgetPredicate(
            (widget) =>
                widget is AnchoredSelect<String> && widget.label == '时区',
          );
          await tester.ensureVisible(timezone);
          await tester.tap(timezone);
          await tester.pumpAndSettle();
          await tester.tap(find.text('上海 · Asia/Shanghai').last);
          await tester.pumpAndSettle();
          final minimum = find.widgetWithText(TextField, '最短');
          final maximum = find.widgetWithText(TextField, '最长');
          expect(tester.getTopLeft(minimum).dy, tester.getTopLeft(maximum).dy);
          expect(find.byType(CheckboxListTile), findsNothing);
          for (final tab in ['灵魂', '记忆']) {
            await tester.tap(find.widgetWithText(Tab, tab));
            await tester.pumpAndSettle();
            final toggle = find.byType(SwitchListTile);
            await tester.ensureVisible(toggle);
            await tester.tap(toggle);
            await tester.pumpAndSettle();
          }
          final scheduleTab = find.widgetWithText(Tab, '行程');
          await tester.ensureVisible(scheduleTab);
          await tester.tap(scheduleTab);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('禁止角色修改此行程').first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('保存'));
          await tester.pumpAndSettle();
          expect(role.lockSoul, isTrue);
          expect(role.timezone, 'Asia/Shanghai');
          expect(role.lockMemory, isTrue);
          expect(role.lockedSchedules, contains(schedule.id));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          store.dispose();
        }
      }
    },
  );
}
