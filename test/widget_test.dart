import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';

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
    final store = PreviewStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(RoleChatApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('send and quote update the selected conversation', (
    tester,
  ) async {
    final store = await setup(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '说点什么，让故事继续…'),
      '一起去看花吧',
    );
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();
    expect(store.selected.messages.last.text, '一起去看花吧');
    expect(find.text('一起去看花吧'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('new role creates an empty private conversation', (tester) async {
    final store = await setup(tester);
    store.navigate(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建角色'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '名称'), '小雪');
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
      for (var i = 0; i < 4; i++) {
        store.navigate(i);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'destination $i at $size',
        );
      }
    }
  });
}
