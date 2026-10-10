import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../widgets/common.dart';
import 'chat_page.dart';
import 'roles_page.dart';
import 'settings_page.dart';
import 'showcase_page.dart';
import 'editors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.store});
  final PreviewStore store;
  static const labels = ['聊天', '角色', '设置', '界面展览'];
  static const icons = [
    Icons.chat_bubble_outline,
    Icons.people_outline,
    Icons.tune,
    Icons.widgets_outlined,
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 880;
      Widget page = switch (store.destination) {
        0 => ChatPage(store: store, wide: wide),
        1 => RolesPage(store: store),
        2 => SettingsPage(store: store),
        _ => ShowcasePage(store: store),
      };
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                Container(
                  width: 88,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border(
                      right: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const RoleAvatar(
                        '',
                        size: 44,
                        icon: Icons.chat_bubble_outline,
                      ),
                      const SizedBox(height: 34),
                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            children: [
                              IconButton.filledTonal(
                                isSelected: store.destination == i,
                                onPressed: () => store.navigate(i),
                                tooltip: labels[i],
                                icon: Icon(icons[i]),
                                style: IconButton.styleFrom(
                                  backgroundColor: store.destination == i
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer
                                      : Colors.transparent,
                                ),
                              ),
                              Text(
                                labels[i],
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: '切换浅色 / 深色',
                        child: IconButton(
                          onPressed: () => store.setMode(
                            Theme.of(context).brightness == Brightness.dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          ),
                          icon: const Icon(Icons.contrast),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              Expanded(child: page),
            ],
          ),
        ),
        bottomNavigationBar: wide || store.showChatOnMobile
            ? null
            : NavigationBar(
                selectedIndex: store.destination,
                onDestinationSelected: store.navigate,
                destinations: List.generate(
                  4,
                  (i) => NavigationDestination(
                    icon: Icon(icons[i]),
                    label: labels[i],
                  ),
                ),
              ),
      );
    },
  );
}

class ConversationList extends StatefulWidget {
  const ConversationList({super.key, required this.store});
  final PreviewStore store;
  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  String query = '';
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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RoleChat',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                key: const ValueKey('create-menu'),
                tooltip: '',
                icon: const Icon(Icons.add_circle_outline),
                onSelected: (v) => v == 'role'
                    ? editRole(context, store)
                    : editGroup(context, store),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'role', child: Text('新建角色')),
                  const PopupMenuItem(value: 'group', child: Text('新建群聊')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              hintText: '搜索会话',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: chats.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 5),
                  itemBuilder: (context, i) {
                    final c = chats[i];
                    return Material(
                      color: c.id == store.selectedId
                          ? scheme.secondaryContainer.withValues(alpha: .65)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        leading: GestureDetector(
                          onTap: () => c.group
                              ? editGroup(context, store, group: c)
                              : (c.members.isEmpty
                                    ? null
                                    : editRole(
                                        context,
                                        store,
                                        role: store.role(c.members.first),
                                      )),
                          child: RoleAvatar(
                            c.name,
                            imageData: store.avatarFor(c),
                            icon: c.group
                                ? Icons.group_outlined
                                : Icons.person_outline,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (c.muted)
                              const Icon(
                                Icons.notifications_off_outlined,
                                size: 14,
                              ),
                            Text(
                              c.messages.isEmpty ? '' : c.messages.last.time,
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            c.messages.isEmpty
                                ? '暂无消息'
                                : c.messages.last.text.replaceAll('\n', ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        onTap: () => store.select(c.id),
                      ),
                    );
                  },
                ),
        ),
        const Padding(
          padding: EdgeInsets.all(18),
          child: PreviewNotice(text: 'UI 预览 · 不会发送网络请求'),
        ),
      ],
    );
  }
}
