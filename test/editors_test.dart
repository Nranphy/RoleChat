import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';
import 'package:rolechat/pages/editors.dart';
import 'package:rolechat/pages/roles_page.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/widgets/anchored_select.dart';

void main() {
  Future<PreviewStore> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = PreviewStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(RoleChatApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets(
    'group editor creates the selected member set on a narrow screen',
    (tester) async {
      final store = await setup(tester);
      editGroup(tester.element(find.byType(Scaffold)), store);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '群聊名称'),
        '雨天茶会',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, '成员'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '林间'));
      await tester.tap(find.widgetWithText(CheckboxListTile, '月白'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(store.selected.name, '雨天茶会');
      expect(store.selected.members, ['lin', 'moon']);
      expect(store.selected.messages, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('role detail tabs and document edit survive modal dismissal', (
    tester,
  ) async {
    final store = await setup(tester);
    showRoleDetail(
      tester.element(find.byType(Scaffold)),
      store,
      store.roles.first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '灵魂'));
    await tester.tap(find.widgetWithText(ChoiceChip, '灵魂'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'soul.md'),
      '喜欢在雨天听故事。',
    );
    for (final label in ['记忆', '行程', '对话示例']) {
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(store.roles.first.soul, '喜欢在雨天听故事。');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'API editor validates the URL before saving preview configuration',
    (tester) async {
      final store = await setup(tester);
      editApi(tester.element(find.byType(Scaffold)), store);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '配置名称'),
        '测试配置',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '接口地址'),
        'invalid',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入有效的 HTTP 或 HTTPS 地址'), findsOneWidget);
      expect(store.apis.length, 1);
      await tester.enterText(
        find.widgetWithText(TextFormField, '接口地址'),
        'https://example.com/v1',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(store.apis.last.name, '测试配置');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('structured schedule and Memory.md persist after editing', (
    tester,
  ) async {
    final store = await setup(tester);
    store.schedules.clear();
    store.schedules.add(
      ScheduleEntry(
        id: 'weekly',
        roleId: 'lin',
        activity: '上课',
        condition: '每周',
        weekdays: [1, 3],
        start: '09:00',
        end: '12:00',
        probability: 20,
      ),
    );
    editRole(
      tester.element(find.byType(Scaffold)),
      store,
      role: store.roles.first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '记忆'));
    await tester.tap(find.widgetWithText(ChoiceChip, '记忆'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Memory.md'),
      '# 记忆\n喜欢雨天。',
    );
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '行程'));
    await tester.tap(find.widgetWithText(ChoiceChip, '行程'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '五'));
    await tester.ensureVisible(
      find.widgetWithText(AnchoredSelect<int>, '接收概率'),
    );
    await tester.tap(find.widgetWithText(AnchoredSelect<int>, '接收概率'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('35%').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('35%').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final restored = PreviewStore(store.preferences);
    expect(restored.roles.first.memory, '# 记忆\n喜欢雨天。');
    expect(restored.schedules.single.weekdays, [1, 3, 5]);
    expect(restored.schedules.single.probability, 35);
    expect(restored.schedules.single.start, '09:00');
    expect(tester.takeException(), isNull);
  });
}
