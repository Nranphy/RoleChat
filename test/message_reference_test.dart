import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/features/chat/widgets/chat_composer.dart';
import 'package:rolechat/features/chat/widgets/message_bubble.dart';
import 'package:rolechat/features/chat/widgets/message_reference_preview.dart';
import 'package:rolechat/features/chat/widgets/sender_color.dart';

void main() {
  testWidgets(
    'bubble and composer references preserve sender color and jump by ID',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = PreviewStore(await SharedPreferences.getInstance());
      store.selected.messages = [
        ChatMessage(id: 'first', roleId: 'lin', text: '同样的内容'),
        ChatMessage(id: 'target', roleId: 'summer', text: '同样的内容'),
        ChatMessage(
          id: 'quoted',
          text: '带引用的回复',
          reply: const MessageReference(
            messageId: 'target',
            roleId: 'summer',
            senderName: '夏芽',
            text: '同样的内容',
          ),
        ),
      ];
      await tester.pumpWidget(RoleChatApp(store: store));
      await tester.pumpAndSettle();
      Finder bubble(String id) => find.ancestor(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(MessageBubble),
      );
      final quote = find.descendant(
        of: bubble('quoted'),
        matching: find.byType(MessageReferencePreview),
      );
      final label = tester.widget<Text>(
        find.descendant(of: quote, matching: find.byType(Text)),
      );
      expect(label.textSpan!.toPlainText(), '夏芽: 同样的内容');
      final name = (label.textSpan! as TextSpan).children!.first as TextSpan;
      expect(name.style!.color, senderNameColor(tester.element(quote), '夏芽'));
      await tester.tap(quote);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MessageBubble>(bubble('target')).highlighted,
        isTrue,
      );
      expect(
        tester.widget<MessageBubble>(bubble('first')).highlighted,
        isFalse,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      tester.widget<MessageBubble>(bubble('target')).onReply!();
      await tester.pumpAndSettle();
      final composerQuote = find.descendant(
        of: find.byType(ChatComposer),
        matching: find.byType(MessageReferencePreview),
      );
      await tester.enterText(find.widgetWithText(TextField, '输入消息'), '未发送内容');
      await tester.tap(composerQuote);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MessageBubble>(bubble('target')).highlighted,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, '输入消息'))
            .controller!
            .text,
        '未发送内容',
      );
      await tester.tap(find.byTooltip('发送消息'));
      await tester.pumpAndSettle();
      final sent = store.selected.messages.last;
      expect(sent.reply!.messageId, 'target');
      expect(sent.reply!.senderName, '夏芽');
      expect(sent.reply!.text, '同样的内容');
      expect(composerQuote, findsNothing);
      store.selected.messages.removeWhere((m) => m.id == 'target');
      store.changed();
      await tester.pumpAndSettle();
      final retained = find.descendant(
        of: bubble(sent.id),
        matching: find.byType(MessageReferencePreview),
      );
      await tester.tap(retained);
      await tester.pumpAndSettle();
      expect(find.text('这条消息已不在当前会话中'), findsOneWidget);
      expect(
        tester.widget<MessageReferencePreview>(retained).reference.senderName,
        '夏芽',
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
