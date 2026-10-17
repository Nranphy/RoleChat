import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/main.dart';
import 'fixtures/test_store.dart';

void main() {
  testWidgets(
    'cleanup buttons require confirmation and cancellation preserves data',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = createTestStore(await SharedPreferences.getInstance());
      await store.storage.markInitialized();
      await store.saveProfiles();
      store.navigate(2);
      await tester.pumpWidget(RoleChatApp(store: store));
      await tester.pumpAndSettle();
      final roles = store.roles.length;
      final count = store.conversations.fold<int>(
        0,
        (n, c) => n + c.messages.length,
      );
      final all = find.text('清空所有数据');
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(find.text('清空所有数据？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.roles.length, roles);
      expect(await store.storage.isInitialized(), isTrue);
      final messages = find.text('清除所有聊天数据');
      await tester.ensureVisible(messages);
      await tester.tap(messages);
      await tester.pumpAndSettle();
      expect(
        store.conversations.fold<int>(0, (n, c) => n + c.messages.length),
        count,
      );
      await tester.tap(find.text('确认清除'));
      await tester.pumpAndSettle();
      expect(store.conversations.every((c) => c.messages.isEmpty), isTrue);
      expect(store.roles.length, roles);
      expect(await store.storage.isInitialized(), isTrue);
      expect(tester.takeException(), isNull);
      store.dispose();
    },
  );
}
