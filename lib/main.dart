import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/preview_store.dart';
import 'design/app_theme.dart';
import 'package:rolechat/app/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/LICENSE-Roboto.txt'));
    yield LicenseEntryWithLineBreaks([
      'Noto Sans CJK',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Noto Color Emoji',
    ], await rootBundle.loadString('assets/fonts/OFL-emoji.txt'));
  });
  final preferences = await SharedPreferences.getInstance();
  runApp(RoleChatApp(store: PreviewStore(preferences)));
}

class RoleChatApp extends StatelessWidget {
  const RoleChatApp({super.key, required this.store});
  final PreviewStore store;
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
