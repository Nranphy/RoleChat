import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/features/chat/widgets/chat_timeline.dart';
import 'package:rolechat/features/chat/widgets/message_bubble.dart';

void main() {
  testWidgets(
    'search shows senders and locates distant variable-height messages in both directions',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = PreviewStore(await SharedPreferences.getInstance());
      store.selected.messages.clear();
      for (var i = 0; i < 180; i++) {
        store.selected.messages.add(
          ChatMessage(
            id: 'search-$i',
            roleId: i == 0 ? null : '11111111-1111-4111-8111-111111111111',
            text: i == 145
                ? '远处命中消息'
                : i == 0
                ? '开头命中消息'
                : i < 70
                ? List.filled(8, '第 $i 条日常消息').join('\n')
                : '第 $i 条日常消息',
          ),
        );
      }
      await tester.pumpWidget(RoleChatApp(store: store));
      await tester.pumpAndSettle();
      final timeline = tester.widget<ChatTimeline>(find.byType(ChatTimeline));
      expect(timeline.scroll.position.extentAfter, lessThanOrEqualTo(.5));
      expect(find.byKey(const ValueKey('search-179')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-145')), findsNothing);
      Future<void> search(String query) async {
        await tester.tap(find.byTooltip('搜索聊天记录'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, query);
        await tester.pumpAndSettle();
      }

      await search('命中消息');
      expect(
        tester
            .widgetList<ListTile>(find.byType(ListTile))
            .map((tile) => (tile.subtitle! as Text).data)
            .toList(),
        ['远处命中消息', '开头命中消息'],
      );
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      await search('远处命中');
      expect(find.widgetWithText(ListTile, '林间'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, '远处命中消息'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final target = find.byKey(const ValueKey('search-145'));
      expect(target, findsOneWidget);
      final bounds = tester.getRect(find.byType(ChatTimeline));
      expect(tester.getRect(target).top, greaterThanOrEqualTo(bounds.top));
      expect(tester.getRect(target).bottom, lessThanOrEqualTo(bounds.bottom));
      expect(
        tester
            .widget<MessageBubble>(
              find.ancestor(of: target, matching: find.byType(MessageBubble)),
            )
            .highlighted,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MessageBubble>(
              find.ancestor(of: target, matching: find.byType(MessageBubble)),
            )
            .highlighted,
        isFalse,
      );
      await search('开头命中');
      expect(
        (tester.widget<ListTile>(find.widgetWithText(ListTile, '开头命中消息')).title!
                as Text)
            .data,
        '你',
      );
      await tester.tap(find.widgetWithText(ListTile, '开头命中消息'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('search-0')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await search('不存在的关键词');
      expect(find.text('没有找到消息'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
