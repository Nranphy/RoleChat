import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/common.dart';
import 'editors.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key, required this.store});
  final PreviewStore store;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeading(
              '角色',
              '',
              action: FilledButton.icon(
                onPressed: () => editRole(context, store),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('新建角色'),
              ),
            ),
            const PreviewNotice(),
            const SizedBox(height: 16),
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
            ...store.roles.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          RoleAvatar(
                            r.name,
                            imageData: r.avatar,
                            color: r.color,
                            size: 80,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                            !c.group &&
                                            c.members.contains(r.id),
                                      )
                                      .firstOrNull;
                                  if (chat != null) store.select(chat.id);
                                },
                              ),
                              PopupMenuButton<String>(
                                tooltip: '角色操作',
                                position: PopupMenuPosition.under,
                                offset: const Offset(0, 6),
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    editRole(context, store, role: r);
                                    return;
                                  }
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
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('角色资料'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('删除角色'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showRoleDetail(
  BuildContext context,
  PreviewStore store,
  RoleProfile role,
) => editRole(context, store, role: role);
