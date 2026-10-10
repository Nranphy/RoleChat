import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/common.dart';
import '../design/app_theme.dart';
import 'shell.dart';
import 'editors.dart';
import 'roles_page.dart';

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
          child: ChatView(
            key: ValueKey(store.selectedId),
            store: store,
            wide: wide,
          ),
        ),
      ],
    );
  }
}

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
                onPressed: () => showSearch(context, c),
                icon: const Icon(Icons.search),
              ),
              PopupMenuButton<String>(
                position: PopupMenuPosition.under,
                offset: const Offset(0, 6),
                tooltip: '会话菜单',
                onSelected: (v) async {
                  if (v == 'info') showInfo(context, store, c);
                  if (v == 'mute') {
                    c.muted = !c.muted;
                    store.changed();
                  }
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
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(c.muted ? '取消免打扰' : '免打扰'),
                  ),
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
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: '表情',
                            onPressed: () => showEmoji(context),
                            icon: const Icon(Icons.sentiment_satisfied_alt),
                          ),
                          Expanded(
                            child: TextField(
                              controller: input,
                              minLines: 1,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText: '输入消息',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onSubmitted: (_) => send(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            tooltip: '发送消息',
                            onPressed: send,
                            icon: const Icon(Icons.send_outlined),
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

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.name,
    required this.emoji,
    this.onReply,
    this.onDelete,
    this.onCopy,
    this.avatar,
    this.onAvatarTap,
  });
  final ChatMessage message;
  final String name, emoji;
  final String? avatar;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onReply, onDelete, onCopy;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.isUser;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bubbleText = mine
        ? (dark ? scheme.onPrimaryContainer : scheme.onPrimary)
        : scheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine) ...[
                GestureDetector(
                  onTap: onAvatarTap,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: RoleAvatar(name, size: 48, imageData: avatar),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 570),
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!mine)
                        Padding(
                          padding: const EdgeInsets.only(left: 3, bottom: 6),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        decoration: BoxDecoration(
                          color: mine
                              ? (dark
                                    ? scheme.primaryContainer
                                    : scheme.primary)
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(mine ? 18 : 3),
                            topRight: const Radius.circular(18),
                            bottomLeft: const Radius.circular(18),
                            bottomRight: Radius.circular(mine ? 3 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.reply != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: (mine ? bubbleText : scheme.primary)
                                      .withValues(alpha: .09),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  message.reply!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mine ? bubbleText : scheme.primary,
                                  ),
                                ),
                              ),
                            SelectableText(
                              message.text,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: bubbleText,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.time,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mine
                                        ? bubbleText.withValues(alpha: .7)
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onReply != null)
                Align(
                  widthFactor: 1,
                  alignment: Alignment.bottomRight,
                  child: PopupMenuButton<String>(
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 6),
                    tooltip: '',
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      Icons.more_horiz,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: (v) {
                      if (v == 'reply') onReply?.call();
                      if (v == 'delete') onDelete?.call();
                      if (v == 'copy') onCopy?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'reply', child: Text('引用回复')),
                      const PopupMenuItem(value: 'copy', child: Text('复制')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showSearch(BuildContext context, Conversation c) {
  var query = '';
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('搜索聊天记录'),
        content: SizedBox(
          width: 520,
          height: 360,
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索聊天记录',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setLocal(() => query = v),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: query.isEmpty
                    ? const EmptyState(
                        emoji: '🔎',
                        title: '搜索消息',
                        subtitle: '输入关键词搜索当前会话',
                      )
                    : ListView(
                        children: c.messages
                            .where((m) => m.text.contains(query))
                            .map(
                              (m) => ListTile(
                                title: Text(m.text),
                                subtitle: Text(m.time),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    ),
  );
}

void showInfo(BuildContext context, PreviewStore store, Conversation c) {
  if (!c.group && c.members.isNotEmpty) {
    showRoleDetail(context, store, store.role(c.members.first));
    return;
  }
  editGroup(context, store, group: c);
}
