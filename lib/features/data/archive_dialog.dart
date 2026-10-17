import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/shared/widgets/app_dialog.dart';
import 'package:rolechat/shared/widgets/dialog_helpers.dart';

class ArchiveDialog extends StatelessWidget {
  const ArchiveDialog({super.key, required this.store});
  final PreviewStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => AppDialog.content(
      title: const Text('归档'),
      content: SizedBox(
        height: 400,
        child: ListView(
          children: [
            if (!store.roles.any((r) => r.archived) &&
                !store.conversations.any((c) => c.archived))
              const Center(child: Text('暂无归档')),
            for (final r in store.roles.where((r) => r.archived))
              ListTile(
                title: Text(r.name),
                subtitle: const Text('角色'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '恢复角色',
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () {
                        r.archived = false;
                        for (final c in store.conversations.where(
                          (c) => !c.group && c.members.contains(r.id),
                        )) {
                          c.archived = false;
                        }
                        store.ensureSelection();
                        store.changed();
                      },
                    ),
                    IconButton(
                      tooltip: '永久删除角色',
                      color: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        var keep = true;
                        final remove = await managedDialog<bool>(
                          context: context,
                          builder: (_) => StatefulBuilder(
                            builder: (context, update) => AppDialog.content(
                              title: Text('永久删除 ${r.name}？'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('将删除角色配置、身份、灵魂、记忆和行程。群聊历史不受影响。'),
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: keep,
                                    title: const Text('保留私聊历史'),
                                    onChanged: (v) => update(() => keep = v!),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('永久删除'),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (remove == true) {
                          store.deleteRole(r.id, keepHistory: keep);
                          store.ensureSelection();
                        }
                      },
                    ),
                  ],
                ),
              ),
            for (final c in store.conversations.where((c) => c.archived))
              ListTile(
                title: Text(c.name),
                subtitle: Text(c.group ? '群聊' : '私聊'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '恢复会话',
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () {
                        if (c.members.any((id) => store.role(id).archived)) {
                          toast(context, '请先恢复关联角色');
                          return;
                        }
                        c.archived = false;
                        store.ensureSelection();
                        store.changed();
                      },
                    ),
                    IconButton(
                      tooltip: '永久删除会话',
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () async {
                        if (await confirm(
                          context,
                          title: '永久删除 ${c.name}？',
                          body: '这会删除${c.group ? '群聊' : '私聊'}历史消息和相关配置，无法恢复。',
                          action: '永久删除',
                        )) {
                          store.conversations.remove(c);
                          store.ensureSelection();
                          store.changed();
                        }
                      },
                    ),
                  ],
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
  );
}
