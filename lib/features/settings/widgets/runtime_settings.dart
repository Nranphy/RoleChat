import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/common.dart';

class RuntimeSettings extends StatelessWidget {
  const RuntimeSettings({
    super.key,
    required this.background,
    required this.onBackgroundChanged,
    required this.onLocalData,
    required this.onAbout,
  });
  final bool background;
  final ValueChanged<bool> onBackgroundChanged;
  final VoidCallback onLocalData, onAbout;
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
          subtitle: const Text('展示开关；浏览器后台调度尚未实现'),
          value: background,
          onChanged: onBackgroundChanged,
        ),
        const Divider(),
        SettingsRow(
          icon: Icons.storage_outlined,
          title: '本地数据',
          subtitle: '头像与角色、群聊资料保存在浏览器本地',
          onTap: onLocalData,
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
