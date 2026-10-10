import 'widgets/conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/features/agents/agent_dialogs.dart';
import 'package:rolechat/features/groups/group_dialogs.dart';

class ConversationList extends StatefulWidget {
  const ConversationList({super.key, required this.store});
  final PreviewStore store;
  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  String query = '';
  String? hoveredId;
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final scheme = Theme.of(context).colorScheme;
    final chats = store.conversations
        .where(
          (c) =>
              c.name.contains(query) &&
              (filter == 0 ||
                  (filter == 1 && !c.group) ||
                  (filter == 2 && c.group)),
        )
        .toList();
    return Column(
      children: [
        SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                      hintText: '搜索会话',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.secondaryContainer,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  clipBehavior: Clip.antiAlias,
                  key: const ValueKey('create-menu'),
                  borderRadius: BorderRadius.circular(20),
                  constraints: const BoxConstraints.tightFor(width: 144),
                  padding: EdgeInsets.zero,
                  tooltip: '',
                  position: PopupMenuPosition.under,
                  offset: const Offset(-52, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SizedBox.square(
                    dimension: 40,
                    child: Center(child: Icon(Icons.add)),
                  ),
                  onSelected: (v) => v == 'role'
                      ? editRole(context, store)
                      : editGroup(context, store),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'role',
                      child: Center(child: Text('新建角色')),
                    ),
                    const PopupMenuItem(
                      value: 'group',
                      child: Center(child: Text('新建群聊')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(['全部', '私聊', '群聊'][i]),
                  selected: filter == i,
                  onSelected: (_) => setState(() => filter = i),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: chats.isEmpty
              ? const EmptyState(
                  emoji: '🔎',
                  title: '没有找到会话',
                  subtitle: '换一个关键词试试',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: chats.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 5),
                  itemBuilder: (context, i) {
                    final c = chats[i];
                    return ConversationTile(
                      c: c,
                      avatar: store.avatarFor(c),
                      selected: c.id == store.selectedId,
                      hovered: hoveredId == c.id,
                      onHoverChanged: (v) => setState(() {
                        if (v) {
                          hoveredId = c.id;
                        } else if (hoveredId == c.id) {
                          hoveredId = null;
                        }
                      }),
                      onSelect: () => store.select(c.id),
                      onEdit: () => c.group
                          ? editGroup(context, store, group: c)
                          : c.members.isEmpty
                          ? null
                          : editRole(
                              context,
                              store,
                              role: store.role(c.members.first),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
