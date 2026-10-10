import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../design/app_theme.dart';
import '../widgets/common.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading('设置', '让这里，更像你的空间。'),
              const PreviewNotice(),
              const SizedBox(height: 26),
              Text('外观', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '明暗模式',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(
                        3,
                        (i) => ChoiceChip(
                          avatar: Icon(
                            [
                              Icons.brightness_auto,
                              Icons.light_mode_outlined,
                              Icons.dark_mode_outlined,
                            ][i],
                            size: 18,
                          ),
                          label: Text(['跟随系统', '浅色', '深色'][i]),
                          selected: store.mode.index == i,
                          onSelected: (_) => store.setMode(ThemeMode.values[i]),
                        ),
                      ),
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color: selected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface
                                          : Colors.transparent,
                                      width: 3,
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
                      style: Theme.of(context).textTheme.titleMedium,
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
              SectionCard(
                child: Column(
                  children: [
                    if (store.apis.isEmpty)
                      const EmptyState(
                        emoji: '🔌',
                        title: '还没有接口配置',
                        subtitle: '这里只展示表单，不会连接外部接口。',
                      ),
                    ...store.apis.map(
                      (a) => SettingsRow(
                        icon: Icons.dns_outlined,
                        title: a.name,
                        subtitle: a.url,
                        onTap: () => editApi(context, store, profile: a),
                        trailing: PopupMenuButton<String>(
                          tooltip: '配置操作',
                          onSelected: (v) async {
                            if (v == 'edit') {
                              editApi(context, store, profile: a);
                              return;
                            }
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
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('编辑'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('删除'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text('运行与数据', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('后台运行偏好'),
                      subtitle: const Text('展示开关；浏览器后台调度尚未实现'),
                      value: background,
                      onChanged: (v) => setState(() => background = v),
                    ),
                    const Divider(),
                    SettingsRow(
                      icon: Icons.storage_outlined,
                      title: '本地数据',
                      subtitle: '消息及角色编辑仅保留本次预览；刷新后恢复样例',
                      onTap: () => managedDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('关于本地数据'),
                          content: const Text(
                            '当前阶段仅实现 UI。主题偏好已保存在浏览器，其他编辑是临时展示状态。聊天数据库、导入导出与模型运行尚未实现。',
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
                      subtitle: '一个属于角色与故事的空间',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'RoleChat',
                        applicationVersion: 'UI Preview 0.1',
                        applicationIcon: const RoleAvatar('✳'),
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
              const SizedBox(height: 30),
            ],
          ),
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
