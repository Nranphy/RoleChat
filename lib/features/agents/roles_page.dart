import 'widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/shared/widgets/content_page.dart';
import 'package:rolechat/features/agents/agent_dialogs.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key, required this.store});
  final PreviewStore store;
  @override
  Widget build(BuildContext context) => ContentPage(
    action: TextButton.icon(
      onPressed: () => editRole(context, store),
      icon: const Icon(Icons.person_add_alt),
      label: const Text('新建角色'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (store.roles.isEmpty)
          EmptyState(
            title: '还没有角色',
            subtitle: '点击新建角色。',
            action: FilledButton(
              onPressed: () => editRole(context, store),
              child: const Text('新建角色'),
            ),
          ),
        ...store.roles.indexed.map((entry) {
          final (index, r) = entry;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == store.roles.length - 1 ? 0 : 4,
            ),
            child: RoleCard(
              r: r,
              onOpen: () => showRoleDetail(context, store, r),
              onChat: () {
                final chat = store.conversations
                    .where((c) => !c.group && c.members.contains(r.id))
                    .firstOrNull;
                if (chat != null) store.select(chat.id);
              },
              onDelete: () async {
                final groups = store.conversations
                    .where((c) => c.group && c.members.contains(r.id))
                    .map((c) => c.name)
                    .join('、');
                if (await confirm(
                  context,
                  title: '删除 ${r.name}？',
                  body: '参与群聊：${groups.isEmpty ? '无' : groups}\n已有消息保留。',
                )) {
                  store.removeRole(r.id);
                }
              },
            ),
          );
        }),
      ],
    ),
  );
}
