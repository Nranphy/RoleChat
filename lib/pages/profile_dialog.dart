import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/avatar_field.dart';
import '../widgets/common.dart';

class RoleEditorDialog extends StatefulWidget {
  const RoleEditorDialog({super.key, required this.store, this.role});
  final PreviewStore store;
  final RoleProfile? role;
  @override
  State<RoleEditorDialog> createState() => _RoleEditorDialogState();
}

class _RoleEditorDialogState extends State<RoleEditorDialog> {
  final dateDetails = <TextEditingController, String>{};
  final form = GlobalKey<FormState>();
  final controllers = <TextEditingController>[];
  late final TextEditingController name, description, model, identity, soul;
  late String id;
  String? avatar, api;
  int tab = 0;
  bool saving = false;
  final examples = <(TextEditingController, TextEditingController)>[];
  final memories = <(TextEditingController, String)>[];
  final schedules =
      <
        (
          TextEditingController,
          TextEditingController,
          TextEditingController,
          String,
          double,
        )
      >[];
  TextEditingController text(String value) {
    final c = TextEditingController(text: value);
    controllers.add(c);
    return c;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.role;
    id = r?.id ?? widget.store.newId();
    name = text(r?.name ?? '');
    description = text(r?.description ?? '');
    model = text(r?.model ?? 'gpt-4o');
    identity = text(r?.identity ?? '');
    soul = text(r?.soul ?? '');
    avatar = r?.avatar;
    api = r?.apiId;
    for (final e in r?.examples ?? <Map<String, String>>[]) {
      examples.add((text(e['question'] ?? ''), text(e['answer'] ?? '')));
    }
    for (final m in widget.store.memories.where((m) => m.roleId == id)) {
      memories.add((text(m.text), m.tag));
    }
    for (final s in widget.store.schedules.where((s) => s.roleId == id)) {
      schedules.add((
        text(s.activity),
        text(s.start),
        text(s.end),
        s.condition,
        s.probability,
      ));
      dateDetails[schedules.last.$1] = s.dateDetail;
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.role == null ? '新建角色' : '角色资料',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                6,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(['基础信息', '身份', '灵魂', '对话示例', '记忆', '行程'][i]),
                    selected: tab == i,
                    onSelected: (_) => setState(() => tab = i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    switch (tab) {
                      0 => basic(),
                      1 => document(identity, 'identity.md'),
                      2 => document(soul, 'soul.md'),
                      3 => qa(),
                      4 => memory(),
                      _ => schedule(),
                    },
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    saving
                        ? '保存中…'
                        : widget.role == null
                        ? '创建角色'
                        : '保存',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget basic() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AvatarField(
        imageData: avatar,
        onChanged: (v) => setState(() => avatar = v),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: name,
        decoration: const InputDecoration(labelText: '名称'),
        validator: (v) => v == null || v.trim().isEmpty ? '请填写角色名称' : null,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: description,
        decoration: const InputDecoration(labelText: '简介（可选）'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: api,
        borderRadius: BorderRadius.circular(16),
        decoration: const InputDecoration(labelText: 'API 配置（展示）'),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('暂不选择')),
          ...widget.store.apis.map(
            (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
          ),
        ],
        onChanged: (v) => api = v,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: model,
        decoration: const InputDecoration(labelText: '模型'),
      ),
    ],
  );
  Widget document(TextEditingController controller, String title) => TextField(
    controller: controller,
    minLines: 10,
    maxLines: 20,
    decoration: InputDecoration(labelText: title, alignLabelWithHint: true),
  );
  Widget qa() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Expanded(child: Text('QA 对话示例')),
          TextButton.icon(
            onPressed: () => setState(() => examples.add((text(''), text('')))),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      ...examples.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('示例 ${e.key + 1}')),
                    IconButton(
                      tooltip: '移除示例',
                      onPressed: () => setState(() => examples.removeAt(e.key)),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                TextField(
                  controller: e.value.$1,
                  decoration: const InputDecoration(labelText: '用户说'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: e.value.$2,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '角色回答'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  Widget memory() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Expanded(child: Text('记忆')),
          TextButton.icon(
            onPressed: () => setState(() => memories.add((text(''), '日常'))),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      if (memories.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Text('暂无记忆')),
      ...memories.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: e.value.$1,
                  minLines: 2,
                  maxLines: 6,
                  decoration: InputDecoration(labelText: e.value.$2),
                ),
              ),
              IconButton(
                tooltip: '删除记忆',
                onPressed: () => setState(() => memories.removeAt(e.key)),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget schedule() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Expanded(child: Text('行程规则')),
          TextButton.icon(
            onPressed: () => setState(
              () => schedules.add((
                text(''),
                text('09:00'),
                text('12:00'),
                '每天',
                80,
              )),
            ),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      if (schedules.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Text('暂无行程')),
      ...schedules.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('规则 ${e.key + 1}')),
                    IconButton(
                      tooltip: '删除行程',
                      onPressed: () =>
                          setState(() => schedules.removeAt(e.key)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                TextField(
                  controller: e.value.$1,
                  decoration: const InputDecoration(labelText: '活动'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: e.value.$4,
                  borderRadius: BorderRadius.circular(16),
                  decoration: const InputDecoration(labelText: '日期条件'),
                  items: ['每天', '每周一至周五', '每周六、日', '每年某一天', '具体日期', '日期范围']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(
                    () => schedules[e.key] = (
                      e.value.$1,
                      e.value.$2,
                      e.value.$3,
                      v!,
                      e.value.$5,
                    ),
                  ),
                ),
                if (['每年某一天', '具体日期', '日期范围'].contains(e.value.$4)) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    key: ValueKey(e.value.$1),
                    initialValue: dateDetails[e.value.$1] ?? '',
                    onChanged: (v) => dateDetails[e.value.$1] = v,
                    decoration: InputDecoration(labelText: e.value.$4),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value.$2,
                        decoration: const InputDecoration(labelText: '开始时间'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: e.value.$3,
                        decoration: const InputDecoration(labelText: '结束时间'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('接收概率'),
                    Expanded(
                      child: Slider(
                        value: e.value.$5,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        onChanged: (v) => setState(
                          () => schedules[e.key] = (
                            e.value.$1,
                            e.value.$2,
                            e.value.$3,
                            e.value.$4,
                            v,
                          ),
                        ),
                      ),
                    ),
                    Text('${e.value.$5.round()}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      setState(() => tab = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) form.currentState?.validate();
      });
      return;
    }
    setState(() => saving = true);
    final store = widget.store;
    final r =
        widget.role ??
        RoleProfile(
          id: id,
          name: name.text.trim(),
          color: const Color(0xffb8cfbb),
        );
    r.name = name.text.trim();
    r.description = description.text;
    r.avatar = avatar;
    r.apiId = api;
    r.model = model.text;
    r.identity = identity.text;
    r.soul = soul.text;
    r.examples = examples
        .map((e) => {'question': e.$1.text, 'answer': e.$2.text})
        .toList();
    if (!store.roles.any((old) => old.id == id)) {
      store.addRole(r);
    } else {
      for (final c in store.conversations.where(
        (c) => !c.group && c.members.contains(id),
      )) {
        c.name = r.name;
      }
      store.changed();
    }
    store.memories.removeWhere((m) => m.roleId == id);
    store.memories.addAll(
      memories.map(
        (m) => MemoryEntry(
          id: store.newId(),
          roleId: id,
          text: m.$1.text,
          tag: m.$2,
        ),
      ),
    );
    store.schedules.removeWhere((s) => s.roleId == id);
    store.schedules.addAll(
      schedules.map(
        (s) => ScheduleEntry(
          id: store.newId(),
          roleId: id,
          activity: s.$1.text,
          condition: s.$4,
          start: s.$2.text,
          end: s.$3.text,
          probability: s.$5,
          dateDetail: dateDetails[s.$1] ?? '',
        ),
      ),
    );
    if (!await store.saveProfiles()) {
      if (mounted) {
        setState(() => saving = false);
        toast(context, store.persistenceError!);
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }
}

class GroupEditorDialog extends StatefulWidget {
  const GroupEditorDialog({super.key, required this.store, this.group});
  final PreviewStore store;
  final Conversation? group;
  @override
  State<GroupEditorDialog> createState() => _GroupEditorDialogState();
}

class _GroupEditorDialogState extends State<GroupEditorDialog> {
  late final TextEditingController name;
  late final Set<String> members;
  String? avatar;
  int tab = 0;
  bool saving = false;
  String? createdId;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.group?.name ?? '');
    members = {...widget.group?.members ?? []};
    avatar = widget.group?.avatar;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.group == null ? '新建群聊' : '群聊资料',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                2,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(['基础信息', '成员'][i]),
                    selected: tab == i,
                    onSelected: (_) => setState(() => tab = i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tab == 0
                    ? [
                        AvatarField(
                          group: true,
                          imageData: avatar,
                          onChanged: (v) => setState(() => avatar = v),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: '群聊名称'),
                        ),
                        const SizedBox(height: 16),
                        Text('${members.length + 1} 位成员'),
                      ]
                    : widget.store.roles
                          .map(
                            (r) => CheckboxListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              secondary: RoleAvatar(
                                r.name,
                                size: 38,
                                imageData: r.avatar,
                              ),
                              title: Text(r.name),
                              value: members.contains(r.id),
                              onChanged: (v) => setState(
                                () => v == true
                                    ? members.add(r.id)
                                    : members.remove(r.id),
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? '保存中…' : '保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      setState(() => tab = 0);
      toast(context, '请填写群聊名称');
      return;
    }
    if (members.isEmpty) {
      setState(() => tab = 1);
      toast(context, '至少选择一个角色');
      return;
    }
    setState(() => saving = true);
    final store = widget.store;
    final group =
        widget.group ??
        store.conversations.where((c) => c.id == createdId).firstOrNull;
    if (group == null) {
      store.addGroup(name.text.trim(), members.toList(), avatar: avatar);
      createdId = store.selected.id;
    } else {
      group.name = name.text.trim();
      group.avatar = avatar;
      group.members = members.toList();
      store.changed();
    }
    if (!await store.saveProfiles()) {
      if (mounted) {
        setState(() => saving = false);
        toast(context, store.persistenceError!);
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }
}
