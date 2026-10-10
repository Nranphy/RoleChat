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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              '故事里的朋友',
              '每一个角色，都有自己的小小世界。',
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
                subtitle: '创建第一位朋友，开启你的故事。',
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
                                      r.emoji,
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
                                Text(
                                  r.description.isEmpty
                                      ? '等待写下属于自己的故事'
                                      : r.description,
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
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .92,
      child: RoleDetail(store: store, role: role),
    ),
  );
}

class RoleDetail extends StatefulWidget {
  const RoleDetail({super.key, required this.store, required this.role});
  final PreviewStore store;
  final RoleProfile role;
  @override
  State<RoleDetail> createState() => _RoleDetailState();
}

class _RoleDetailState extends State<RoleDetail> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final r = widget.role;
      final store = widget.store;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 18),
            child: Row(
              children: [
                RoleAvatar(r.emoji, color: r.color, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        r.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '编辑角色',
                  onPressed: () => editRole(context, store, role: r),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(['身份与灵魂', '记忆', '行程', '对话示例'][i]),
                    selected: tab == i,
                    onSelected: (_) => setState(() => tab = i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: switch (tab) {
                    0 => documents(context, r, store),
                    1 => memories(context, r, store),
                    2 => schedules(context, r, store),
                    _ => examples(context, r, store),
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  Widget documents(BuildContext context, RoleProfile r, PreviewStore store) =>
      Column(
        children: [
          docCard(context, 'identity.md', '角色身份与表达方式', r.identity, () async {
            final text = await editText(context, '编辑 identity.md', r.identity);
            if (text != null) {
              r.identity = text;
              store.changed();
            }
          }),
          const SizedBox(height: 18),
          docCard(context, 'soul.md', '角色的内在世界 · 自动变化为未来功能', r.soul, () async {
            final text = await editText(context, '编辑 soul.md', r.soul);
            if (text != null) {
              r.soul = text;
              store.changed();
            }
          }),
          const SizedBox(height: 18),
          const PreviewNotice(text: '资料修改仅影响展示。自动更新与版本历史尚未接入。'),
        ],
      );
  Widget docCard(
    BuildContext context,
    String title,
    String subtitle,
    String text,
    VoidCallback onEdit,
  ) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: '编辑 $title',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 18),
        SelectableText(
          text.isEmpty ? '还没有内容，点击编辑写下第一句。' : text,
          style: const TextStyle(height: 1.8),
        ),
      ],
    ),
  );
  Widget memories(BuildContext context, RoleProfile r, PreviewStore store) {
    final entries = store.memories.where((m) => m.roleId == r.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          '记忆碎片',
          '那些值得留下的小事。',
          action: TextButton.icon(
            onPressed: () async {
              final text = await editText(context, '添加记忆', '');
              if (text != null && text.trim().isNotEmpty) {
                store.memories.add(
                  MemoryEntry(id: store.newId(), roleId: r.id, text: text),
                );
                store.changed();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ),
        if (entries.isEmpty)
          const EmptyState(
            emoji: '🫙',
            title: '记忆罐还是空的',
            subtitle: '在这里展示属于这个角色的记忆。',
          ),
        ...entries.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(m.tag)),
                      const Spacer(),
                      Text(
                        m.date,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'delete') {
                            if (await confirm(
                              context,
                              title: '删除记忆？',
                              body: m.text,
                            )) {
                              store.memories.remove(m);
                              store.changed();
                            }
                          } else {
                            final text = await editText(
                              context,
                              '编辑记忆',
                              m.text,
                            );
                            if (text != null) {
                              m.text = text;
                              store.changed();
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('删除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(m.text, style: const TextStyle(height: 1.7)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget schedules(BuildContext context, RoleProfile r, PreviewStore store) {
    final entries = store.schedules.where((s) => s.roleId == r.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          '一天的节奏',
          '每段日常，都有不同的心情。',
          action: TextButton.icon(
            onPressed: () => editSchedule(context, store, r.id),
            icon: const Icon(Icons.add),
            label: const Text('添加规则'),
          ),
        ),
        const PreviewNotice(text: '规则与接收概率仅供预览，不执行定时检查或自动更新。'),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          const EmptyState(
            emoji: '🗓️',
            title: '还没有行程',
            subtitle: '为角色安排一段日常吧。',
          ),
        ...entries.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.activity,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: '编辑行程',
                        onPressed: () =>
                            editSchedule(context, store, r.id, entry: s),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: '删除行程',
                        onPressed: () async {
                          if (await confirm(
                            context,
                            title: '删除行程规则？',
                            body: s.activity,
                          )) {
                            store.schedules.remove(s);
                            store.changed();
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Text(
                    '${s.condition} · ${s.start} — ${s.end}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: s.probability / 100,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '消息接收概率 ${s.probability.round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget examples(
    BuildContext context,
    RoleProfile r,
    PreviewStore store,
  ) => Column(
    children: [
      PageHeading(
        '对话示例',
        '让角色找到自己的表达方式。',
        action: TextButton(
          onPressed: () => editRole(context, store, role: r),
          child: const Text('编辑'),
        ),
      ),
      if (r.examples.isEmpty)
        const EmptyState(
          emoji: '📝',
          title: '还没有对话示例',
          subtitle: '在角色编辑页添加任意数量的 QA 示例。',
        ),
      ...r.examples.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('用户', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e['question'] ?? ''),
                const Divider(height: 28),
                Text(
                  r.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(e['answer'] ?? '', style: const TextStyle(height: 1.7)),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> editSchedule(
  BuildContext context,
  PreviewStore store,
  String roleId, {
  ScheduleEntry? entry,
}) async {
  final name = TextEditingController(text: entry?.activity ?? '');
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
}
