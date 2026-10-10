import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/common.dart';
import '../widgets/reference_page_body.dart';
import 'editors.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key, required this.store});
  final PreviewStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('角色'),
      automaticallyImplyLeading: false,
      toolbarHeight: MediaQuery.sizeOf(context).width > 840 ? 72 : 56,
      actions: [
        TextButton.icon(
          onPressed: () => editRole(context, store),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('新建角色'),
        ),
      ],
    ),
    body: ReferencePageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.roles.isEmpty)
            EmptyState(
              emoji: '',
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
                bottom: index == store.roles.length - 1 ? 0 : 8,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => showRoleDetail(context, store, r),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        RoleAvatar(r.name, imageData: r.avatar, size: 80),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  r.model,
                                  if (r.description.isNotEmpty) r.description,
                                ].join('\n'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '进入私聊',
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {
                                final chat = store.conversations
                                    .where(
                                      (c) =>
                                          !c.group && c.members.contains(r.id),
                                    )
                                    .firstOrNull;
                                if (chat != null) store.select(chat.id);
                              },
                            ),
                            IconButton(
                              tooltip: '删除角色',
                              icon: const Icon(Icons.delete_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () async {
                                final groups = store.conversations
                                    .where(
                                      (c) =>
                                          c.group && c.members.contains(r.id),
                                    )
                                    .map((c) => c.name)
                                    .join('、');
                                if (await confirm(
                                  context,
                                  title: '删除 ${r.name}？',
                                  body:
                                      '参与群聊：${groups.isEmpty ? '无' : groups}\n已有消息保留。',
                                )) {
                                  store.removeRole(r.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

void showRoleDetail(
  BuildContext context,
  PreviewStore store,
  RoleProfile role,
) => editRole(context, store, role: role);
