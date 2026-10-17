import 'package:flutter/material.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/presentation/theme/app_theme.dart';
import 'package:rolechat/app/layout/app_shell.dart';

class RoleChatApp extends StatelessWidget {
  const RoleChatApp({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'RoleChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(store.seed, Brightness.light),
      darkTheme: AppTheme.build(store.seed, Brightness.dark),
      themeMode: store.mode,
      home: AppShell(store: store),
    ),
  );
}
