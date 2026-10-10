import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/common.dart';
import 'editors.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key, required this.store});
  final PreviewStore store;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              '角色',
              '',
              action: FilledButton.icon(
                onPressed: () => editRole(context, store),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('新建角色'),
              ),
            ),
            const PreviewNotice(),
            const SizedBox(height: 26),
            if (store.roles.isEmpty)
              EmptyState(
                emoji: '🌱',
                title: '还没有角色',
                subtitle: '点击新建角色。',
                action: FilledButton(
                  onPressed: () => editRole(context, store),
                  child: const Text('新建角色'),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width > 900
                    ? 3
                    : width > 580
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: store.roles
                      .map(
                        (r) => SizedBox(
                          width: (width - (columns - 1) * 18) / columns,
                          child: SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    RoleAvatar(
                                      r.name,
                                      imageData: r.avatar,
                                      color: r.color,
                                      size: 64,
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      tooltip: '角色操作',
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          editRole(context, store, role: r);
                                        }
                                        if (v == 'delete') {
                                          final groups = store.conversations
                                              .where(
                                                (c) =>
                                                    c.group &&
                                                    c.members.contains(r.id),
                                              )
                                              .map((c) => c.name)
                                              .join('、');
                                          if (await confirm(
                                            context,
                                            title: '删除 ${r.name}？',
                                            body:
                                                '参与群聊：${groups.isEmpty ? '无' : groups}\n仅从本次展示中移除，已有消息保留。',
                                          )) {
                                            store.removeRole(r.id);
                                          }
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('编辑角色'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('删除角色'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  r.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 7),
                                if (r.description.isNotEmpty)
                                  Text(
                                    r.description,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(
                                        r.model,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    const Chip(
                                      label: Text(
                                        '暂停 · 展示',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            showRoleDetail(context, store, r),
                                        child: const Text('角色资料'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton.filledTonal(
                                      tooltip: '进入私聊',
                                      onPressed: () {
                                        final c = store.conversations
                                            .where(
                                              (c) =>
                                                  !c.group &&
                                                  c.members.contains(r.id),
                                            )
                                            .firstOrNull;
                                        if (c != null) store.select(c.id);
                                      },
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void showRoleDetail(
  BuildContext context,
  PreviewStore store,
  RoleProfile role,
) {
  editRole(context, store, role: role);
}

Future<void> editSchedule(
  BuildContext context,
  PreviewStore store,
  String roleId, {
  ScheduleEntry? entry,
}) async {
  final name = TextEditingController(text: entry?.activity ?? '');
  final dateDetail = TextEditingController(text: entry?.dateDetail ?? '');
  var condition = entry?.condition ?? '每天';
  var probability = entry?.probability ?? 80;
  var start = entry?.start ?? '09:00';
  var end = entry?.end ?? '12:00';
  final form = GlobalKey<FormState>();
  await managedDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(entry == null ? '新增行程规则' : '编辑行程规则'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '活动名称'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '请输入活动' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: condition,
                    decoration: const InputDecoration(labelText: '日期条件'),
                    items: ['每天', '每周一至周五', '每周六、日', '每年某一天', '具体日期', '日期范围']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setLocal(() => condition = v!),
                  ),
                  if (['每年某一天', '具体日期', '日期范围'].contains(condition)) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: dateDetail,
                      decoration: InputDecoration(
                        labelText: condition,
                        hintText: condition == '每年某一天'
                            ? '例如 10-10'
                            : '例如 2026-10-10',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: int.parse(start.split(':')[0]),
                                minute: int.parse(start.split(':')[1]),
                              ),
                            );
                            if (t != null) {
                              setLocal(
                                () => start =
                                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(start),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('至'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: int.parse(end.split(':')[0]),
                                minute: int.parse(end.split(':')[1]),
                              ),
                            );
                            if (t != null) {
                              setLocal(
                                () => end =
                                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(end),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('消息接收概率 ${probability.round()}%'),
                  Slider(
                    value: probability,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${probability.round()}%',
                    onChanged: (v) => setLocal(() => probability = v),
                  ),
                  const Text(
                    '概率为 0 时不接收消息；跨午夜时间段允许展示。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
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
              final s =
                  entry ??
                  ScheduleEntry(
                    id: store.newId(),
                    roleId: roleId,
                    activity: '',
                    condition: condition,
                    start: start,
                    end: end,
                    probability: probability,
                  );
              s.activity = name.text;
              s.condition = condition;
              s.dateDetail = dateDetail.text;
              s.start = start;
              s.end = end;
              s.probability = probability;
              if (entry == null) store.schedules.add(s);
              store.changed();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  dateDetail.dispose();
}
