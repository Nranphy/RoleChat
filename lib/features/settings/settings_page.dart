import 'settings_dialogs.dart';
import 'widgets/runtime_settings.dart';
import 'widgets/appearance_settings.dart';
import 'widgets/api_settings.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/shared/widgets/content_page.dart';
import 'package:rolechat/features/settings/api_editor.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final PreviewStore store;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool background = true;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ContentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppearanceSettings(
            mode: store.mode,
            seed: store.seed,
            onModeChanged: store.setMode,
            onSeedChanged: store.setSeed,
            onCustomColor: () =>
                editThemeColor(context, store.seed, store.setSeed),
          ),
          const SizedBox(height: 26),
          ApiSettings(
            apis: store.apis,
            onAdd: () => editApi(context, store),
            onEdit: (a) => editApi(context, store, profile: a),
            onDelete: (a) async {
              final used = store.roles
                  .where((r) => r.apiId == a.id)
                  .map((r) => r.name)
                  .join('、');
              if (await confirm(
                context,
                title: '删除 API 配置？',
                body:
                    '使用此配置的角色：${used.isEmpty ? '无' : used}\n移除后，这些角色的配置选择会清空。',
              )) {
                for (final r in store.roles.where((r) => r.apiId == a.id)) {
                  r.apiId = null;
                }
                store.apis.remove(a);
                store.changed();
              }
            },
          ),
          const SizedBox(height: 26),
          const Text('运行与数据', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          RuntimeSettings(
            background: background,
            onBackgroundChanged: (v) => setState(() => background = v),
            onLocalData: () => showLocalDataInfo(context),
            onAbout: () => showRoleChatAbout(context),
          ),
        ],
      ),
    );
  }
}
