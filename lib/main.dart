import 'package:rolechat/infrastructure/storage/open_workspace.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/app_store.dart';

import 'package:rolechat/app/role_chat_app.dart';

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
  try {
    final store = AppStore(preferences, storage: await openWorkspace());
    try {
      await store.initialize();
    } catch (_) {
      store.dispose();
      rethrow;
    }
    store.startRuntime();
    runApp(RoleChatApp(store: store));
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('无法打开本地数据'),
                  const SizedBox(height: 12),
                  Text('$e'),
                  const Text('请使用支持OPFS的浏览器，确认没有其他RoleChat标签页运行后刷新。'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
