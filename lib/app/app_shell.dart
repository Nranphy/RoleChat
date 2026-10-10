import 'navigation_rail.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/features/chat/chat_page.dart';
import 'package:rolechat/features/agents/roles_page.dart';
import 'package:rolechat/features/settings/settings_page.dart';
import 'package:rolechat/features/showcase/showcase_page.dart';

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
              if (wide) RoleNavigationRail(store: store),
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
