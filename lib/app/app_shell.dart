import 'navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/features/chat/chat_page.dart';
import 'package:rolechat/features/agents/roles_page.dart';
import 'package:rolechat/features/settings/settings_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.store});
  final PreviewStore store;
  static const labels = ['聊天', '角色', '设置'];
  static const icons = [
    Icons.chat_bubble_outline,
    Icons.people_outline,
    Icons.tune,
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth > AppTheme.wideBreakpoint;
      Widget page = switch (store.destination) {
        0 => ChatPage(store: store, wide: wide),
        1 => RolesPage(store: store),
        _ => SettingsPage(store: store),
      };
      return AbsorbPointer(
        absorbing: store.transferring,
        child: Scaffold(
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  RoleNavigationRail(
                    selectedIndex: store.destination,
                    labels: labels,
                    icons: icons,
                    onSelected: store.navigate,
                    onToggleTheme: () => store.setMode(
                      Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (store.transferring)
                        const LinearProgressIndicator(minHeight: 2),
                      if (store.runtimeError != null)
                        MaterialBanner(
                          content: Text(store.runtimeError!),
                          actions: [
                            TextButton(
                              onPressed: () {
                                store.runtimeError = null;
                                store.refresh();
                              },
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      Expanded(child: page),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide || store.showChatOnMobile
              ? null
              : NavigationBar(
                  selectedIndex: store.destination,
                  onDestinationSelected: store.navigate,
                  destinations: List.generate(
                    labels.length,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                  ),
                ),
        ),
      );
    },
  );
}
