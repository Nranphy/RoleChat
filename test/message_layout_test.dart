import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/features/chat/widgets/message_bubble.dart';
import 'package:rolechat/models/preview_models.dart';

void main() {
  testWidgets('wrapped consecutive bubbles contain all lines without overlap', (
    tester,
  ) async {
    for (final width in [390.0, 850.0]) {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      for (final mine in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(AppTheme.seeds.first, Brightness.dark),
            home: Scaffold(
              body: ListView(
                children: [
                  for (var i = 0; i < 3; i++)
                    MessageBubble(
                      message: ChatMessage(
                        id: 'wrapped-$i',
                        roleId: mine ? null : 'role',
                        text: List.filled(
                          i + 2,
                          '周六下午我们先去看花，然后到咖啡店门口见面。',
                        ).join(),
                      ),
                      name: '夏芽',
                      previousSame: i > 0,
                      nextSame: i < 2,
                      onReply: () {},
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          final bubble = find.byType(MessageBubble).at(i);
          final text = find.descendant(
            of: bubble,
            matching: find.byType(SelectableText),
          );
          final element = tester.element(text);
          final widget = tester.widget<SelectableText>(text);
          final painter = TextPainter(
            text: TextSpan(
              text: widget.data,
              style: DefaultTextStyle.of(element).style.merge(widget.style),
            ),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(element),
          )..layout(maxWidth: tester.getSize(text).width);
          final surface = tester.getRect(find.byKey(ValueKey('wrapped-$i')));
          expect(
            surface.height,
            greaterThanOrEqualTo(painter.height + 16 - .01),
          );
          if (i < 2) {
            expect(
              tester.getRect(find.byKey(ValueKey('wrapped-${i + 1}'))).top,
              greaterThanOrEqualTo(surface.bottom),
            );
          }
          painter.dispose();
        }
        expect(tester.takeException(), isNull);
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
