import '../../fixtures/test_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/app/role_chat_app.dart';
import 'package:rolechat/presentation/features/agents/agent_dialogs.dart';
import 'package:rolechat/presentation/features/groups/group_dialogs.dart';
import 'package:rolechat/presentation/features/settings/api_editor.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/presentation/shared/widgets/anchored_select.dart';

void main() {
  Future<AppStore> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = createTestStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(RoleChatApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets(
    'profile documents share spacing and group validation selects members',
    (tester) async {
      final store = await setup(tester);
      final context = tester.element(find.byType(Scaffold));
      editRole(context, store, role: store.roles.first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, '身份'));
      await tester.pumpAndSettle();
      final roleGap =
          tester.getTopLeft(find.text('声明 Agent 的身份。')).dy -
          tester.getBottomLeft(find.byType(TabBar)).dy;
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      editGroup(context, store);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Tab>(find.byType(Tab))
            .map((tab) => tab.text)
            .toList(),
        ['基础', '背景', '成员'],
      );
      await tester.tap(find.text('未命名'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-name-input')),
        '背景测试群',
      );
      await tester.tap(find.widgetWithText(Tab, '背景'));
      await tester.pumpAndSettle();
      final groupGap =
          tester.getTopLeft(find.text('介绍群聊的背景。')).dy -
          tester.getBottomLeft(find.byType(TabBar)).dy;
      expect(groupGap, closeTo(roleGap, .01));
      await tester.enterText(
        find.widgetWithText(TextField, 'background.md'),
        '保留的背景草稿',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNWidgets(store.roles.length));
      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabs.controller!.index, 2);
      await tester.tap(find.widgetWithText(Tab, '背景'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'background.md'))
            .controller!
            .text,
        '保留的背景草稿',
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'group editor creates the selected member set on a narrow screen',
    (tester) async {
      final store = await setup(tester);
      editGroup(tester.element(find.byType(Scaffold)), store);
      await tester.pumpAndSettle();
      await tester.tap(find.text('未命名'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-name-input')),
        '雨天茶会',
      );
      await tester.tap(find.widgetWithText(Tab, '背景'));
      await tester.pumpAndSettle();
      expect(find.text('介绍群聊的背景。'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'background.md'),
        '# 背景\n雨天的茶馆。',
      );
      await tester.tap(find.widgetWithText(Tab, '成员'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '林间'));
      await tester.tap(find.widgetWithText(CheckboxListTile, '月白'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(store.selected.name, '雨天茶会');
      expect(store.selected.members, [
        '11111111-1111-4111-8111-111111111111',
        '22222222-2222-4222-8222-222222222222',
      ]);
      expect(store.selected.messages, isEmpty);
      expect(store.selected.background, '# 背景\n雨天的茶馆。');
      final restored = createTestStore(
        store.preferences,
        storage: store.storage,
      );
      await restored.initialize();
      final group = restored.conversations.firstWhere((c) => c.name == '雨天茶会');
      expect(group.background, '# 背景\n雨天的茶馆。');
      editGroup(
        tester.element(find.byType(Scaffold)),
        store,
        group: store.selected,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, '背景'));
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, 'background.md');
      expect(tester.widget<TextField>(field).controller!.text, '# 背景\n雨天的茶馆。');
      await tester.enterText(field, '不应保存的草稿');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.selected.background, '# 背景\n雨天的茶馆。');

      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty examples show a placeholder and update when adding or removing',
    (tester) async {
      final store = await setup(tester);
      showRoleDetail(
        tester.element(find.byType(Scaffold)),
        store,
        store.roles[1],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, '样例'));
      await tester.pumpAndSettle();
      expect(find.text('暂无样例'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '添加'));
      await tester.pumpAndSettle();
      expect(find.text('暂无样例'), findsNothing);
      expect(find.widgetWithText(TextField, 'user'), findsOneWidget);
      await tester.tap(find.byTooltip('移除示例'));
      await tester.pumpAndSettle();
      expect(find.text('暂无样例'), findsOneWidget);
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
    await tester.ensureVisible(find.widgetWithText(Tab, '灵魂'));
    await tester.tap(find.widgetWithText(Tab, '灵魂'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'soul.md'),
      '喜欢在雨天听故事。',
    );
    for (final label in ['记忆', '行程', '样例']) {
      await tester.ensureVisible(find.widgetWithText(Tab, label));
      await tester.tap(find.widgetWithText(Tab, label));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      if (label == '行程') {
        expect(find.text('用于 Agent 的角色扮演。'), findsOneWidget);
      }
      if (label == '样例') {
        expect(find.text('供 Agent 参考对话风格。'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'user'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'assistant'), findsOneWidget);
      }
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
  testWidgets('structured schedule and memory.md persist after editing', (
    tester,
  ) async {
    final store = await setup(tester);
    store.schedules.clear();
    store.schedules.add(
      ScheduleEntry(
        id: 'weekly',
        roleId: '11111111-1111-4111-8111-111111111111',
        activity: '上课',
        ruleKind: ScheduleRuleKind.weekly,
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
    await tester.ensureVisible(find.widgetWithText(Tab, '记忆'));
    await tester.tap(find.widgetWithText(Tab, '记忆'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'memory.md'),
      '# 记忆\n喜欢雨天。',
    );
    await tester.ensureVisible(find.widgetWithText(Tab, '行程'));
    await tester.tap(find.widgetWithText(Tab, '行程'));
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
    final restored = createTestStore(store.preferences, storage: store.storage);
    await restored.initialize();
    expect(restored.roles.first.memory, '# 记忆\n喜欢雨天。');
    expect(restored.schedules.single.weekdays, [1, 3, 5]);
    expect(restored.schedules.single.probability, 35);
    expect(restored.schedules.single.start, '09:00');
    expect(tester.takeException(), isNull);
  });
}
