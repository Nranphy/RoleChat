import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../widgets/common.dart';
import '../design/app_theme.dart';
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
      final wide = constraints.maxWidth > AppTheme.wideBreakpoint;
      Widget page = switch (store.destination) {
        0 => ChatPage(store: store, wide: wide),
        1 => RolesPage(store: store),
        2 => SettingsPage(store: store),
        _ => ShowcasePage(store: store),
      };
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) _RoleNavigationRail(store: store),
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
                  key: const ValueKey('create-menu'),
                  tooltip: '',
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: const Icon(Icons.add),
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
                    return Material(
                      color: c.id == store.selectedId
                          ? scheme.secondaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppTheme.cornerRadius,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: '编辑 ${c.name}',
                              child: GestureDetector(
                                onTap: () => c.group
                                    ? editGroup(context, store, group: c)
                                    : c.members.isEmpty
                                    ? null
                                    : editRole(
                                        context,
                                        store,
                                        role: store.role(c.members.first),
                                      ),
                                child: RoleAvatar(
                                  c.name,
                                  imageData: store.avatarFor(c),
                                  size: 56,
                                  icon: c.group
                                      ? Icons.group_outlined
                                      : Icons.person_outline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => store.select(c.id),
                                hoverColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: c.unread > 0
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (c.muted)
                                            const Icon(
                                              Icons.notifications_off_outlined,
                                              size: 14,
                                            ),
                                          Text(
                                            c.messages.isEmpty
                                                ? ''
                                                : c.messages.last.time,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.messages.isEmpty
                                            ? '暂无消息'
                                            : c.messages.last.text.replaceAll(
                                                '\n',
                                                ' ',
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RoleNavigationRail extends StatelessWidget {
  const _RoleNavigationRail({required this.store});
  final PreviewStore store;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppTheme.railWidth,
      child: Column(
        children: [
          const SizedBox(height: 4),
          ...List.generate(AppShell.labels.length, (i) {
            final selected = store.destination == i;
            return SizedBox(
              height: 64,
              child: Stack(
                children: [
                  if (selected)
                    Positioned(
                      left: 0,
                      top: 8,
                      bottom: 8,
                      child: Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(90),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Tooltip(
                      message: AppShell.labels[i],
                      child: Material(
                        color: selected
                            ? colors.secondaryContainer
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cornerRadius,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.cornerRadius,
                          ),
                          onTap: () => store.navigate(i),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              AppShell.icons[i],
                              color: selected
                                  ? colors.onSecondaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          const Tooltip(
            message: '界面预览，未连接模型',
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.science_outlined, size: 20),
            ),
          ),
          IconButton(
            tooltip: '切换浅色 / 深色',
            onPressed: () => store.setMode(
              Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: const Icon(Icons.contrast),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
