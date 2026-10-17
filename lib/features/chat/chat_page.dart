import 'chat_view.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/features/chat/conversation_list.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.store, required this.wide});
  final PreviewStore store;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    if (!wide && !store.showChatOnMobile) return ConversationList(store: store);
    return Row(
      children: [
        if (wide)
          SizedBox(
            width: AppTheme.conversationWidth,
            child: ConversationList(store: store),
          ),
        if (wide) const VerticalDivider(width: 1),
        Expanded(
          child: store.activeChats.isEmpty
              ? const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无对话', style: TextStyle(fontSize: 11)),
                  ),
                )
              : ChatView(
                  key: ValueKey('${store.selectedId}:${store.dataEpoch}'),
                  store: store,
                  wide: wide,
                ),
        ),
      ],
    );
  }
}
