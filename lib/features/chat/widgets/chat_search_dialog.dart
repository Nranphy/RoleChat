import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

class ChatSearchDialog extends StatefulWidget {
  const ChatSearchDialog({
    super.key,
    required this.conversation,
    required this.roles,
  });
  final Conversation conversation;
  final List<RoleProfile> roles;
  @override
  State<ChatSearchDialog> createState() => _ChatSearchDialogState();
}

class _ChatSearchDialogState extends State<ChatSearchDialog> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final results = widget.conversation.messages.reversed
        .where((m) => m.text.contains(query))
        .toList();
    return AlertDialog(
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
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: query.isEmpty
                  ? const EmptyState(title: '搜索消息', subtitle: '输入关键词搜索当前会话')
                  : results.isEmpty
                  ? const EmptyState(title: '没有找到消息', subtitle: '换一个关键词试试')
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final m = results[index];
                        final role = widget.roles
                            .where((r) => r.id == m.roleId)
                            .firstOrNull;
                        final sender = m.isUser ? '你' : role?.name ?? '已离开的角色';
                        return ListTile(
                          leading: RoleAvatar(
                            sender,
                            imageData: role?.avatar,
                            size: 36,
                          ),
                          title: Text(
                            sender,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          subtitle: Text(
                            m.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            m.time,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => Navigator.pop(context, m.id),
                        );
                      },
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
    );
  }
}
