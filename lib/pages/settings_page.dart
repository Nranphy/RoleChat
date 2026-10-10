import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../design/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/reference_page_body.dart';
import 'editors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final PreviewStore store;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool background = true;
  bool compact = false;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.sizeOf(context).width > 840 ? 72 : 56,
        scrolledUnderElevation: 0,
      ),
      body: ReferencePageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSection(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '明暗模式',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('浅色'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('深色'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('跟随系统'),
                        icon: Icon(Icons.auto_mode_outlined),
                      ),
                    ],
                    selected: {store.mode},
                    onSelectionChanged: (values) =>
                        store.setMode(values.single),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    '主题配色',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: List.generate(AppTheme.seeds.length, (i) {
                      final color = AppTheme.seeds[i];
                      final selected =
                          store.seed.toARGB32() == color.toARGB32();
                      return Semantics(
                        label: '${AppTheme.seedNames[i]}配色',
                        selected: selected,
                        button: true,
                        child: InkWell(
                          onTap: () => store.setSeed(color),
                          borderRadius: BorderRadius.circular(14),
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 0,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTheme.seedNames[i],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => customColor(context, store),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('自定义颜色'),
                  ),
                  const Divider(height: 28),
                  const Text(
                    '颜色与明暗选择会保存在当前浏览器。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'API 配置',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => editApi(context, store),
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (store.apis.isEmpty)
                    const EmptyState(
                      emoji: '',
                      title: '还没有接口配置',
                      subtitle: '这里只展示表单，不会连接外部接口。',
                    ),
                  ...store.apis.map(
                    (a) => SettingsRow(
                      icon: Icons.dns_outlined,
                      title: a.name,
                      subtitle: a.url,
                      onTap: () => editApi(context, store, profile: a),
                      trailing: IconButton(
                        tooltip: '删除 API 配置',
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () async {
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
                            for (final r in store.roles.where(
                              (r) => r.apiId == a.id,
                            )) {
                              r.apiId = null;
                            }
                            store.apis.remove(a);
                            store.changed();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text('运行与数据', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SettingsSection(
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
                    onChanged: (v) => setState(() => background = v),
                  ),
                  const Divider(),
                  SettingsRow(
                    icon: Icons.storage_outlined,
                    title: '本地数据',
                    subtitle: '头像与角色、群聊资料保存在浏览器本地',
                    onTap: () => managedDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('关于本地数据'),
                        content: const Text(
                          '主题、头像以及角色与群聊资料保存在当前浏览器。消息仍为临时展示数据。导入导出与模型运行尚未实现。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('知道了'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.info_outline,
                    title: '关于 RoleChat',
                    subtitle: '版本与许可信息',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'RoleChat',
                      applicationVersion: 'UI Preview 0.1',
                      applicationIcon: const RoleAvatar(
                        '',
                        icon: Icons.chat_bubble_outline,
                      ),
                      children: [
                        const Text(
                          '界面风格借鉴 FluffyChat，独立实现 Flutter Web 组件。\n\n本版本用于 UI 验收，不连接模型接口。',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> customColor(BuildContext context, PreviewStore store) async {
    final controller = TextEditingController(
      text: store.seed.toARGB32().toRadixString(16).substring(2).toUpperCase(),
    );
    final form = GlobalKey<FormState>();
    await managedDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义主题颜色'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '十六进制颜色',
              prefixText: '#',
              hintText: '597B66',
            ),
            validator: (v) => RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v ?? '')
                ? null
                : '请输入六位颜色值',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              store.setSeed(
                Color(int.parse('ff${controller.text}', radix: 16)),
              );
              Navigator.pop(context);
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}
