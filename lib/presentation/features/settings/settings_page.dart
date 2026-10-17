import 'package:rolechat/presentation/features/data/archive_dialog.dart';
import 'package:rolechat/presentation/features/data/data_transfer_dialog.dart';
import 'package:rolechat/presentation/features/settings/settings_dialogs.dart';
import 'package:rolechat/presentation/features/settings/widgets/runtime_settings.dart';
import 'package:rolechat/presentation/features/settings/widgets/data_cleanup_settings.dart';
import 'package:rolechat/domain/models/workspace_cleanup.dart';
import 'package:rolechat/presentation/features/settings/widgets/appearance_settings.dart';
import 'package:rolechat/presentation/features/settings/widgets/api_settings.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';
import 'package:rolechat/presentation/shared/widgets/content_page.dart';
import 'package:rolechat/presentation/features/settings/api_editor.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final AppStore store;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> clearData(WorkspaceCleanup scope) async {
    if (widget.store.transferring) return;
    final accepted = await confirm(
      context,
      title: '${scope.label}？',
      body: '${scope.explanation}\n\n此操作无法撤销，请确认已保存需要的数据。',
      action: '确认清除',
      destructive: true,
    );
    if (!accepted || !mounted) return;
    try {
      await widget.store.clearData(scope);
      if (mounted) {
        toast(
          context,
          scope == WorkspaceCleanup.all
              ? '已清空所有数据，刷新页面后重新初始化。'
              : '已完成${scope.label}。',
        );
      }
    } catch (_) {
      if (mounted) toast(context, '清理失败，请检查本地存储后重试。');
    }
  }

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
                store.removeApi(a.id);
              }
            },
          ),
          const SizedBox(height: 26),
          const Text('运行与数据', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          RuntimeSettings(
            background: store.runtimeData['background'] != false,
            onArchive: () => managedDialog<void>(
              context: context,
              builder: (_) => ArchiveDialog(store: store),
            ),
            onBackgroundChanged: (v) {
              store.runtimeData['background'] = v;
              store.changed();
            },
            onLocalData: () => managedDialog<void>(
              context: context,
              builder: (_) => DataTransferDialog(store: store),
            ),
            onAbout: () => showRoleChatAbout(context),
          ),
          const SizedBox(height: 26),
          const Text('数据清理', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DataCleanupSettings(onSelected: clearData, busy: store.transferring),
        ],
      ),
    );
  }
}
