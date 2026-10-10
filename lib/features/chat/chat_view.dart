import 'widgets/message_bubble.dart';
import 'chat_dialogs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/features/agents/roles_page.dart';

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
  String? reply;
  bool showTyping = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (!widget.wide)
                IconButton(
                  tooltip: '返回会话',
                  onPressed: () {
                    store.showChatOnMobile = false;
                    store.changed();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showInfo(context, store, c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          RoleAvatar(
                            c.name,
                            size: 56,
                            imageData: store.avatarFor(c),
                            icon: c.group
                                ? Icons.group_outlined
                                : Icons.person_outline,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (c.group)
                                  Text(
                                    '${c.members.length + 1} 位成员',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '搜索聊天记录',
                onPressed: () => showChatSearch(context, c),
                icon: const Icon(Icons.search),
              ),
              PopupMenuButton<String>(
                clipBehavior: Clip.antiAlias,
                position: PopupMenuPosition.under,
                offset: const Offset(0, 6),
                tooltip: '会话菜单',
                onSelected: (v) async {
                  if (v == 'info') showInfo(context, store, c);
                  if (v == 'typing') setState(() => showTyping = !showTyping);
                  if (v == 'clear' &&
                      await confirm(
                        context,
                        title: '清空展示消息？',
                        body: '只清空当前预览会话，不影响其他会话。',
                        action: '清空',
                      )) {
                    c.messages.clear();
                    store.changed();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'info', child: Text('会话资料')),
                  const PopupMenuItem(value: 'typing', child: Text('切换输入中效果')),
                  const PopupMenuItem(value: 'clear', child: Text('清空展示消息')),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: scheme.surface,
            child: c.messages.isEmpty
                ? const EmptyState(
                    emoji: '💬',
                    title: '暂无消息',
                    subtitle: '发送消息开始聊天。',
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.timelineWidth,
                      ),
                      child: ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                        itemCount: c.messages.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  '今天 · 示例对话',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }
                          final m = c.messages[i - 1];
                          final role = store.roles
                              .where((r) => r.id == m.roleId)
                              .firstOrNull;
                          return MessageBubble(
                            message: m,
                            showName: c.group,
                            previousSame:
                                i > 1 && c.messages[i - 2].roleId == m.roleId,
                            nextSame:
                                i < c.messages.length &&
                                c.messages[i].roleId == m.roleId,
                            nameColor: role == null
                                ? null
                                : (Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.nameColors(role.name).primary
                                      : AppTheme.nameColors(
                                          role.name,
                                        ).primaryContainer),
                            name: m.isUser ? '你' : role?.name ?? '已离开的角色',
                            emoji: '',
                            avatar: role?.avatar,
                            onAvatarTap: role == null
                                ? null
                                : () => showRoleDetail(context, store, role),
                            onReply: () => setState(() => reply = m.text),
                            onDelete: () async {
                              if (await confirm(
                                context,
                                title: '删除这条展示消息？',
                                body: '此操作只影响当前预览。',
                              )) {
                                c.messages.remove(m);
                                store.changed();
                              }
                            },
                            onCopy: () async {
                              await Clipboard.setData(
                                ClipboardData(text: m.text),
                              );
                              if (context.mounted) toast(context, '已复制消息');
                            },
                          );
                        },
                      ),
                    ),
                  ),
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
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.timelineWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
              child: Column(
                children: [
                  if (reply != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.reply, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reply!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => reply = null),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                    ),
                  Material(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(32),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 56,
                            child: Center(
                              child: IconButton(
                                tooltip: '表情',
                                onPressed: () => showEmoji(context),
                                color: scheme.onPrimaryContainer,
                                icon: const Icon(Icons.add_reaction_outlined),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: input,
                              minLines: 1,
                              maxLines: 8,
                              style: const TextStyle(fontSize: 16),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                hintText: '输入消息',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onSubmitted: (_) => send(),
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: IconButton.filled(
                                tooltip: '发送消息',
                                onPressed: send,
                                icon: const Icon(Icons.send_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
