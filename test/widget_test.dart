import 'fixtures/test_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

void main() {
  Future<PreviewStore> setup(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = createTestStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(RoleChatApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('send and quote update the selected conversation', (
    tester,
  ) async {
    final store = await setup(tester);
    await tester.enterText(find.widgetWithText(TextField, '输入消息'), '一起去看花吧');
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();
    expect(store.selected.messages.last.text, '一起去看花吧');
    expect(find.text('一起去看花吧'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Shift Enter inserts newline and Enter sends the draft', (
    tester,
  ) async {
    final store = await setup(tester);
    final field = find.widgetWithText(TextField, '输入消息');
    await tester.tap(field);
    await tester.enterText(field, '第一行');
    final count = store.selected.messages.length;
    expect(
      tester.widget<TextField>(field).textInputAction,
      TextInputAction.newline,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      tester.widget<TextField>(field).keyboardType,
      TextInputType.multiline,
    );
    expect(store.selected.messages.length, count);
    await tester.enterText(field, '第一行\n第二行');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(store.selected.messages.length, count);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(store.selected.messages.length, count + 1);
    expect(store.selected.messages.last.text, '第一行\n第二行');
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('role card edits initials and delete opens confirmation', (
    tester,
  ) async {
    final store = await setup(tester);
    store.navigate(1);
    await tester.pumpAndSettle();
    expect(find.byTooltip('角色操作'), findsNothing);
    await tester.tap(find.text('林间'));
    await tester.pumpAndSettle();
    final dialogAvatar = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(RoleAvatar),
    );
    expect(tester.widget<RoleAvatar>(dialogAvatar).name, '林间');
    expect(find.text('简介（可选）'), findsNothing);
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('林间')).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-input')),
      '青禾',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<RoleAvatar>(dialogAvatar).name, '青禾');
    await tester.tap(find.widgetWithText(Tab, '样例'));
    await tester.pumpAndSettle();
    expect(store.role('11111111-1111-4111-8111-111111111111').name, '青禾');
    expect(
      store.conversations
          .firstWhere((c) => c.id == '66666666-6666-4666-8666-666666666666')
          .name,
      '青禾',
    );
    await store.saveProfiles();
    final restoredName = createTestStore(
      store.preferences,
      storage: store.storage,
    );
    await restoredName.initialize();
    expect(
      restoredName.role('11111111-1111-4111-8111-111111111111').name,
      '青禾',
    );
    restoredName.dispose();
    final userHeight = tester
        .getSize(find.widgetWithText(TextField, 'user'))
        .height;
    final assistantHeight = tester
        .getSize(find.widgetWithText(TextField, 'assistant'))
        .height;
    expect(userHeight, greaterThanOrEqualTo(48));
    expect(assistantHeight, userHeight);
    await tester.enterText(
      find.widgetWithText(TextField, 'assistant'),
      '第一行\n第二行\n第三行',
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.widgetWithText(TextField, 'assistant')).height,
      userHeight,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除角色').first);
    await tester.pumpAndSettle();
    expect(find.text('归档 青禾？'), findsOneWidget);
    expect(store.roles.length, 3);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(store.roles.length, 3);
  });
  testWidgets('API row opens editor and delete requires confirmation', (
    tester,
  ) async {
    final store = await setup(tester);
    store.navigate(2);
    await tester.pumpAndSettle();
    expect(find.byTooltip('配置操作'), findsNothing);
    await tester.ensureVisible(find.text('我的模型接口'));
    await tester.tap(find.text('我的模型接口'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '配置名称'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除 API 配置'));
    await tester.pumpAndSettle();
    expect(find.text('删除 API 配置？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(store.apis.length, 1);
  });
  testWidgets('new role creates an empty private conversation', (tester) async {
    final store = await setup(tester);
    store.navigate(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建角色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未命名'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-input')),
      '小雪',
    );
    await tester.tap(find.text('创建角色'));
    await tester.pumpAndSettle();
    expect(store.roles.last.name, '小雪');
    expect(store.conversations.last.messages, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile navigation and theme preference work', (tester) async {
    final store = await setup(tester, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(store.mode, ThemeMode.dark);
    expect(store.preferences.getInt('themeMode'), ThemeMode.dark.index);
    expect(tester.takeException(), isNull);
  });
  testWidgets('all destinations render at narrow and wide sizes', (
    tester,
  ) async {
    final store = await setup(tester);
    for (final size in [const Size(1280, 900), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      Rect? rolePanel;
      for (var i = 0; i < 3; i++) {
        store.navigate(i);
        await tester.pumpAndSettle();
        if (i == 1 || i == 2) {
          expect(find.byType(AppBar), findsNothing);
          final panel = tester.getRect(
            find.byKey(const ValueKey('content-page-panel')),
          );
          expect(panel.top, lessThanOrEqualTo(32));
          if (i == 1) {
            rolePanel = panel;
          } else {
            expect(panel.topLeft, rolePanel!.topLeft);
            expect(panel.width, rolePanel.width);
          }
        }
        expect(
          tester.takeException(),
          isNull,
          reason: 'destination $i at $size',
        );
      }
    }
  });
  testWidgets('conversation title opens chat while avatar opens its editor', (
    tester,
  ) async {
    final store = await setup(tester, size: const Size(390, 844));
    await tester.tap(find.text('周末小花园'));
    await tester.pumpAndSettle();
    expect(store.showChatOnMobile, isTrue);
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byTooltip('返回会话'));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();

    await tester.tap(find.bySemanticsLabel('编辑 周末小花园'));
    await tester.pumpAndSettle();
    semantics.dispose();
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('周末小花园')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('consecutive role messages share one sender heading and avatar', (
    tester,
  ) async {
    final store = await setup(tester);
    store.selected.messages = [
      ChatMessage(
        id: 'a',
        roleId: '11111111-1111-4111-8111-111111111111',
        text: '第一条',
      ),
      ChatMessage(
        id: 'b',
        roleId: '11111111-1111-4111-8111-111111111111',
        text: '第二条',
      ),
    ];
    store.changed();
    await tester.pumpAndSettle();
    expect(find.text('第一条'), findsOneWidget);
    expect(find.text('第二条'), findsNWidgets(2));
    expect(find.text('林间'), findsNWidgets(2));
    expect(
      find.byWidgetPredicate((w) => w is RoleAvatar && w.name == '林间'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });
}
