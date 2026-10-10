import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/features/groups/group_dialogs.dart';
import 'package:rolechat/features/agents/roles_page.dart';

void showChatSearch(BuildContext context, Conversation c) {
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
