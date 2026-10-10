import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/design/app_theme.dart';
import 'message_bubble.dart';

class ChatTimeline extends StatelessWidget {
  const ChatTimeline({
    super.key,
    required this.c,
    required this.roles,
    required this.scroll,
    required this.onRoleTap,
    required this.onReply,
    required this.onDelete,
    required this.onCopy,
  });
  final Conversation c;
  final List<RoleProfile> roles;
  final ScrollController scroll;
  final ValueChanged<RoleProfile> onRoleTap;
  final ValueChanged<ChatMessage> onReply, onDelete, onCopy;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      child: c.messages.isEmpty
          ? const EmptyState(emoji: '💬', title: '暂无消息', subtitle: '发送消息开始聊天。')
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
                    final role = roles
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
                          : (Theme.of(context).brightness == Brightness.light
                                ? AppTheme.nameColors(role.name).primary
                                : AppTheme.nameColors(
                                    role.name,
                                  ).primaryContainer),
                      name: m.isUser ? '你' : role?.name ?? '已离开的角色',
                      emoji: '',
                      avatar: role?.avatar,
                      onAvatarTap: role == null ? null : () => onRoleTap(role),
                      onReply: () => onReply(m),
                      onDelete: () => onDelete(m),
                      onCopy: () => onCopy(m),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
