import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';

class RuntimeSettings extends StatelessWidget {
  const RuntimeSettings({
    super.key,
    required this.background,
    required this.onBackgroundChanged,
    required this.onLocalData,
    required this.onArchive,
    required this.onAbout,
  });
  final bool background;
  final ValueChanged<bool> onBackgroundChanged;
  final VoidCallback onLocalData, onAbout, onArchive;
  @override
  Widget build(BuildContext context) => SettingsSection(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        SwitchListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: const Text('后台运行偏好'),
          subtitle: const Text('允许页面在后台时检查消息；浏览器冻结页面后暂停运行'),
          value: background,
          onChanged: onBackgroundChanged,
        ),
        const Divider(),
        SettingsRow(
          icon: Icons.storage_outlined,
          title: '本地数据',
          subtitle: '文件存储、ZIP 导入与导出',
          onTap: onLocalData,
        ),
        SettingsRow(
          icon: Icons.archive_outlined,
          title: '归档',
          subtitle: '恢复或永久删除角色与会话',
          onTap: onArchive,
        ),
        SettingsRow(
          icon: Icons.info_outline,
          title: '关于 RoleChat',
          subtitle: '版本与许可信息',
          onTap: onAbout,
        ),
      ],
    ),
  );
}
