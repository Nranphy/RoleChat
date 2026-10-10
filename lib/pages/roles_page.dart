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
    padding: const EdgeInsets.all(28),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 26),
            if (store.roles.isEmpty)
              EmptyState(
                emoji: '🌱',
                title: '还没有角色',
                subtitle: '点击新建角色。',
                action: FilledButton(
                  onPressed: () => editRole(context, store),
                  child: const Text('新建角色'),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width > 900
                    ? 3
                    : width > 580
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: store.roles
                      .map(
                        (r) => SizedBox(
                          width: (width - (columns - 1) * 18) / columns,
                          child: SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    RoleAvatar(
                                      r.name,
                                      imageData: r.avatar,
                                      color: r.color,
                                      size: 80,
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      position: PopupMenuPosition.under,
                                      offset: const Offset(0, 6),
                                      tooltip: '角色操作',
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          editRole(context, store, role: r);
                                        }
                                        if (v == 'delete') {
                                          final groups = store.conversations
                                              .where(
                                                (c) =>
                                                    c.group &&
                                                    c.members.contains(r.id),
                                              )
                                              .map((c) => c.name)
                                              .join('、');
                                          if (await confirm(
                                            context,
                                            title: '删除 ${r.name}？',
                                            body:
                                                '参与群聊：${groups.isEmpty ? '无' : groups}\n仅从本次展示中移除，已有消息保留。',
                                          )) {
                                            store.removeRole(r.id);
                                          }
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('编辑角色'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('删除角色'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  r.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 7),
                                if (r.description.isNotEmpty)
                                  Text(
                                    r.description,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(
                                        r.model,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    const Chip(
                                      label: Text(
                                        '暂停 · 展示',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            showRoleDetail(context, store, r),
                                        child: const Text('角色资料'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton.filledTonal(
                                      tooltip: '进入私聊',
                                      onPressed: () {
                                        final c = store.conversations
                                            .where(
                                              (c) =>
                                                  !c.group &&
                                                  c.members.contains(r.id),
                                            )
                                            .firstOrNull;
                                        if (c != null) store.select(c.id);
                                      },
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
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
) {
  editRole(context, store, role: role);
}
