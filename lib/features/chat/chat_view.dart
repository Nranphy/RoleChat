import 'package:rolechat/models/preview_models.dart';
import 'widgets/chat_timeline.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_composer.dart';
import 'chat_dialogs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/features/agents/agent_dialogs.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.store, required this.wide});
  final PreviewStore store;
  final bool wide;
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final timelineKey = GlobalKey<ChatTimelineState>();
  MessageReference? reply;
  bool showTyping = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> searchMessages() async {
    final id = await showChatSearch(
      context,
      widget.store.selected,
      widget.store.roles,
    );
    if (!mounted || id == null) return;
    await jumpToMessage(id);
  }

  Future<void> jumpToMessage(String id) async {
    final found = await timelineKey.currentState?.scrollToMessage(id) ?? false;
    if (mounted && !found) toast(context, '这条消息已不在当前会话中');
  }

  void send() {
    if (input.text.trim().isEmpty) return;
    widget.store.send(input.text, reply: reply);
    input.clear();
    setState(() => reply = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final c = store.selected;
    return Column(
      children: [
        ChatHeader(
          c: c,
          avatar: store.avatarFor(c),
          wide: widget.wide,
          onBack: () {
            store.showChatOnMobile = false;
            store.changed();
          },
          onInfo: () => showInfo(context, store, c),
          onSearch: searchMessages,
          onMenuSelected: (v) async {
            if (v == 'info') showInfo(context, store, c);
            if (v == 'archive') {
              store.archiveChat(c);
            }
            if (v == 'typing') setState(() => showTyping = !showTyping);
            if (v == 'clear' &&
                await confirm(
                  context,
                  title: '清空消息？',
                  body: '清空当前会话的所有消息，无法恢复。',
                  action: '清空',
                )) {
              c.messages.clear();
              store.changed();
            }
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: ChatTimeline(
            key: timelineKey,
            c: c,
            roles: store.roles,
            scroll: scroll,
            onRoleTap: (r) => showRoleDetail(context, store, r),
            onJumpToMessage: jumpToMessage,
            onReply: (m) => setState(
              () => reply = MessageReference(
                messageId: m.id,
                text: m.text,
                roleId: m.roleId,
                senderName: m.isUser
                    ? '你'
                    : store.roles
                              .where((r) => r.id == m.roleId)
                              .firstOrNull
                              ?.name ??
                          '已离开的角色',
              ),
            ),
            onDelete: (m) async {
              if (await confirm(
                context,
                title: '删除这条消息？',
                body: '此操作将从本地文件中删除消息。',
              )) {
                c.messages.remove(m);
                store.changed();
              }
            },
            onCopy: (m) async {
              await Clipboard.setData(ClipboardData(text: m.text));
              if (context.mounted) toast(context, '已复制消息');
            },
          ),
        ),
        if (showTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('角色正在输入…（展示效果）', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => setState(() => showTyping = false),
                  child: const Text('停止'),
                ),
              ],
            ),
          ),
        ChatComposer(
          input: input,
          reply: reply,
          onClearReply: () => setState(() => reply = null),
          onJumpToReply: reply == null
              ? null
              : () => jumpToMessage(reply!.messageId),
          onEmoji: () => showEmoji(context),
          onSend: send,
        ),
      ],
    );
  }

  void showEmoji(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              [
                    '🌼',
                    '🌿',
                    '✨',
                    '☕',
                    '🌙',
                    '🍊',
                    '😊',
                    '💛',
                    '🎬',
                    '📷',
                    '🌷',
                    '🐈',
                  ]
                  .map(
                    (e) => InkWell(
                      onTap: () {
                        input.text += e;
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
