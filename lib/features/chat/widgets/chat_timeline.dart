import 'sender_color.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/design/app_theme.dart';
import 'message_bubble.dart';

class ChatTimeline extends StatefulWidget {
  const ChatTimeline({
    super.key,
    required this.c,
    required this.roles,
    required this.scroll,
    required this.onRoleTap,
    required this.onReply,
    required this.onJumpToMessage,
    required this.onDelete,
    required this.onCopy,
  });
  final Conversation c;
  final List<RoleProfile> roles;
  final ScrollController scroll;
  final ValueChanged<RoleProfile> onRoleTap;
  final ValueChanged<ChatMessage> onReply, onDelete, onCopy;
  final ValueChanged<String> onJumpToMessage;
  @override
  State<ChatTimeline> createState() => ChatTimelineState();
}

class ChatTimelineState extends State<ChatTimeline> {
  final messageKeys = <String, GlobalKey>{};
  String? highlightedId;
  Timer? highlightTimer;
  @override
  void dispose() {
    highlightTimer?.cancel();
    super.dispose();
  }

  /// Locate by stable ID, including messages outside the lazy list's viewport.
  Future<bool> scrollToMessage(String id) async {
    final indexes = {
      for (final entry in widget.c.messages.indexed) entry.$2.id: entry.$1,
    };
    final target = indexes[id];
    if (target == null || !widget.scroll.hasClients) return false;
    if (messageKeys[id]?.currentContext == null) {
      final position = widget.scroll.position;
      final fraction = (target + 1) / widget.c.messages.length;
      widget.scroll.jumpTo(position.maxScrollExtent * fraction);
      await WidgetsBinding.instance.endOfFrame;
    }
    for (var attempt = 0; attempt <= indexes.length + 2; attempt++) {
      if (!mounted ||
          !widget.scroll.hasClients ||
          !widget.c.messages.any((m) => m.id == id)) {
        return false;
      }
      final targetContext = messageKeys[id]?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: .35,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        if (!mounted) return false;
        highlightTimer?.cancel();
        setState(() => highlightedId = id);
        highlightTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => highlightedId = null);
        });
        return true;
      }
      final visible =
          messageKeys.entries
              .where(
                (e) =>
                    e.value.currentContext != null &&
                    indexes.containsKey(e.key),
              )
              .map((e) => indexes[e.key]!)
              .toList()
            ..sort();
      final position = widget.scroll.position;
      final direction = visible.isNotEmpty && target < visible.first ? -1 : 1;
      final next =
          (position.pixels + direction * position.viewportDimension * .75)
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble();
      if (next == position.pixels) return false;
      widget.scroll.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.timelineWidth),
          child: ListView.builder(
            controller: widget.scroll,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            itemCount: widget.c.messages.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      widget.c.messages.isEmpty ? '暂无对话' : '今天 · 示例对话',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              final m = widget.c.messages[i - 1];
              final role = widget.roles
                  .where((r) => r.id == m.roleId)
                  .firstOrNull;
              return MessageBubble(
                key: messageKeys.putIfAbsent(m.id, () => GlobalKey()),
                highlighted: highlightedId == m.id,
                message: m,
                showName: widget.c.group,
                previousSame:
                    i > 1 && widget.c.messages[i - 2].roleId == m.roleId,
                nextSame:
                    i < widget.c.messages.length &&
                    widget.c.messages[i].roleId == m.roleId,
                nameColor: role == null
                    ? null
                    : senderNameColor(context, role.name),
                onReferenceTap: m.reply == null
                    ? null
                    : () => widget.onJumpToMessage(m.reply!.messageId),
                name: m.isUser ? '你' : role?.name ?? '已离开的角色',

                avatar: role?.avatar,
                onAvatarTap: role == null ? null : () => widget.onRoleTap(role),
                onReply: () => widget.onReply(m),
                onDelete: () => widget.onDelete(m),
                onCopy: () => widget.onCopy(m),
              );
            },
          ),
        ),
      ),
    );
  }
}
