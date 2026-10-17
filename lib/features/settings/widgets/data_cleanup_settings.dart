import 'package:flutter/material.dart';
import 'package:rolechat/models/workspace_cleanup.dart';
import 'package:rolechat/shared/widgets/settings_section.dart';

extension CleanupDescription on WorkspaceCleanup {
  String get label => switch (this) {
    WorkspaceCleanup.all => '清空所有数据',
    WorkspaceCleanup.profiles => '清除所有群聊和角色数据',
    WorkspaceCleanup.messages => '清除所有聊天数据',
    WorkspaceCleanup.initialization => '清除初始化标记',
  };
  String get summary => switch (this) {
    WorkspaceCleanup.all => '删除全部本地数据，刷新后重新初始化',
    WorkspaceCleanup.profiles => '删除资料、文档、头像和关联聊天记录',
    WorkspaceCleanup.messages => '仅删除消息，保留角色和群聊配置',
    WorkspaceCleanup.initialization => '仅删除 initialized.json，保留现有数据',
  };
  String get explanation => switch (this) {
    WorkspaceCleanup.all =>
      '删除当前站点的全部 RoleChat 数据：API 配置和 Key、角色与群聊（含归档）、文档、头像、聊天记录、界面偏好及初始化标记。刷新页面后会重新初始化预设角色。',
    WorkspaceCleanup.profiles =>
      '删除全部角色和群聊（含归档），以及相关私聊、聊天记录、头像、身份、灵魂、记忆、背景和行程。保留 API 配置、Key、界面偏好和初始化标记，不会重新注入预设。',
    WorkspaceCleanup.messages =>
      '删除所有私聊和群聊（含归档）的消息、引用及运行游标。保留角色与群聊资料、身份、灵魂、记忆、行程、API 配置和初始化标记。清理后角色仍可继续发言。',
    WorkspaceCleanup.initialization =>
      '仅删除 OPFS 根目录的 initialized.json，保留当前数据。下次刷新按固定 UUID 补建缺失的预设角色、私聊和社团群聊，并确保五个预设角色入群；已有资料与聊天记录不覆盖。',
  };
  IconData get icon => switch (this) {
    WorkspaceCleanup.all => Icons.delete_forever_outlined,
    WorkspaceCleanup.profiles => Icons.person_remove_outlined,
    WorkspaceCleanup.messages => Icons.delete_sweep_outlined,
    WorkspaceCleanup.initialization => Icons.restart_alt,
  };
}

class DataCleanupSettings extends StatelessWidget {
  const DataCleanupSettings({
    super.key,
    required this.onSelected,
    required this.busy,
  });
  final ValueChanged<WorkspaceCleanup> onSelected;
  final bool busy;
  @override
  Widget build(BuildContext context) => SettingsSection(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final scope in WorkspaceCleanup.values)
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            leading: Icon(
              scope.icon,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              scope.label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
            subtitle: Text(scope.summary, style: const TextStyle(fontSize: 12)),
            enabled: !busy,
            onTap: busy ? null : () => onSelected(scope),
          ),
      ],
    ),
  );
}
