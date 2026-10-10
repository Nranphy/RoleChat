import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/pages/chat_page.dart';

void main() {
  testWidgets(
    'message hover reveals only its menu and anchors it above the timestamp',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final mine in [false, true]) {
        var replies = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(
              AppTheme.seeds.first,
              mine ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: Column(
                children: [
                  MessageBubble(
                    message: ChatMessage(
                      id: 'untimed',
                      roleId: mine ? null : 'lin',
                      text: '第一条消息',
                      time: '16:38',
                    ),
                    name: '林间',
                    emoji: '',
                    nextSame: true,
                    onReply: () => replies++,
                  ),
                  MessageBubble(
                    message: ChatMessage(
                      id: 'timed',
                      roleId: mine ? null : 'lin',
                      text: '第二条消息',
                      time: '16:39',
                    ),
                    name: '林间',
                    emoji: '',
                    previousSame: true,
                    onReply: () => replies++,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final surfaces = [
          find.byKey(const ValueKey('untimed')),
          find.byKey(const ValueKey('timed')),
        ];
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: const Offset(0, 800));
        for (var i = 0; i < 2; i++) {
          final message = find.byType(MessageBubble).at(i);
          final opacity = find.descendant(
            of: message,
            matching: find.byType(AnimatedOpacity),
          );
          expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);
          final before = tester.getRect(surfaces[i]);
          final color =
              (tester.widget<AnimatedContainer>(surfaces[i]).decoration!
                      as BoxDecoration)
                  .color;
          await mouse.moveTo(tester.getCenter(surfaces[i]));
          await tester.pumpAndSettle();
          expect(tester.widget<AnimatedOpacity>(opacity).opacity, 1);
          expect(tester.getRect(surfaces[i]), before);
          expect(
            (tester.widget<AnimatedContainer>(surfaces[i]).decoration!
                    as BoxDecoration)
                .color,
            isNot(color),
          );
          final menu = find.descendant(
            of: message,
            matching: find.byType(PopupMenuButton<String>),
          );
          expect(tester.getBottomLeft(menu).dy, closeTo(before.bottom, .01));
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(find.text('引用回复'), findsOneWidget);
          await tester.tap(find.text('引用回复'));
          await tester.pumpAndSettle();
          await mouse.moveTo(const Offset(0, 800));
          await tester.pumpAndSettle();
          expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);
        }
        expect(replies, 2);
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
