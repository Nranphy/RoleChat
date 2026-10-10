import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/avatar_field.dart';
import '../widgets/common.dart';
import '../widgets/anchored_select.dart';
import '../widgets/schedule_rule_field.dart';

class RoleEditorDialog extends StatefulWidget {
  const RoleEditorDialog({super.key, required this.store, this.role});
  final PreviewStore store;
  final RoleProfile? role;
  @override
  State<RoleEditorDialog> createState() => _RoleEditorDialogState();
}

class _RoleEditorDialogState extends State<RoleEditorDialog>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final form = GlobalKey<FormState>();
  final controllers = <TextEditingController>[];
  late final TextEditingController name,
      description,
      model,
      identity,
      soul,
      memoryDocument;
  late String id;
  String? avatar, api;
  int tab = 0;
  bool saving = false;
  final examples = <(TextEditingController, TextEditingController)>[];

  final schedules = <ScheduleDraft>[];
  final removedSchedules = <ScheduleDraft>[];
  TextEditingController text(String value) {
    final c = TextEditingController(text: value);
    controllers.add(c);
    return c;
  }

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 6, vsync: this);
    final r = widget.role;
    id = r?.id ?? widget.store.newId();
    name = text(r?.name ?? '');
    description = text(r?.description ?? '');
    model = text(r?.model ?? 'gpt-4o');
    identity = text(r?.identity ?? '');
    soul = text(r?.soul ?? '');
    memoryDocument = text(r?.memory ?? '');
    avatar = r?.avatar;
    api = r?.apiId;
    for (final e in r?.examples ?? <Map<String, String>>[]) {
      examples.add((text(e['question'] ?? ''), text(e['answer'] ?? '')));
    }
    for (final s in widget.store.schedules.where((s) => s.roleId == id)) {
      schedules.add(ScheduleDraft(s));
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final draft in [...schedules, ...removedSchedules]) {
      draft.dispose();
    }
    tabs.dispose();
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
          TabBar(
            controller: tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (i) => setState(() => tab = i),
            tabs: [
              '基础信息',
              '身份',
              '灵魂',
              '对话示例',
              '记忆',
              '行程',
            ].map((label) => Tab(text: label)).toList(),
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
                      4 => document(memoryDocument, 'Memory.md'),
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
      const SizedBox(height: 24),
      TextFormField(
        controller: name,
        decoration: const InputDecoration(labelText: '名称'),
        validator: (v) => v == null || v.trim().isEmpty ? '请填写角色名称' : null,
      ),
      const SizedBox(height: 20),
      TextField(
        controller: description,
        decoration: const InputDecoration(labelText: '简介（可选）'),
      ),
      const SizedBox(height: 20),
      AnchoredSelect<String>(
        label: 'API 配置（展示）',
        value: api ?? '',
        options: {'': '暂不选择', for (final a in widget.store.apis) a.id: a.name},
        onChanged: (v) => setState(() => api = v.isEmpty ? null : v),
      ),
      const SizedBox(height: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('示例 ${e.key + 1}')),
                    IconButton(
                      tooltip: '移除示例',
                      onPressed: () => setState(() => examples.removeAt(e.key)),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                TextField(
                  controller: e.value.$1,
                  decoration: const InputDecoration(
                    labelText: '用户说',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.value.$2,
                  minLines: 1,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: '角色回答',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
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
            onPressed: () => setState(() => schedules.add(ScheduleDraft())),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      if (schedules.isEmpty)
        const Padding(padding: EdgeInsets.all(12), child: Text('暂无行程')),
      ...schedules.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ScheduleRuleField(
            key: ObjectKey(e.value),
            draft: e.value,
            index: e.key,
            onChanged: () => setState(() {}),
            onDelete: () =>
                setState(() => removedSchedules.add(schedules.removeAt(e.key))),
          ),
        ),
      ),
    ],
  );
  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      tabs.animateTo(0);
      setState(() => tab = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) form.currentState?.validate();
      });
      return;
    }
    if (schedules.any(
      (s) =>
          s.activity.text.trim().isEmpty ||
          (s.kind == ScheduleRuleKind.weekly && s.weekdays.isEmpty) ||
          (s.kind == ScheduleRuleKind.range && s.until.isBefore(s.from)),
    )) {
      tabs.animateTo(5);
      setState(() => tab = 5);
      toast(context, '请填写活动，并检查星期和日期范围');
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
    r.memory = memoryDocument.text;
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
    store.schedules.removeWhere((s) => s.roleId == id);
    store.schedules.addAll(schedules.map((s) => s.toEntry(id, store.newId())));
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

class _GroupEditorDialogState extends State<GroupEditorDialog>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late final TextEditingController name;
  late final Set<String> members;
  String? avatar;
  int tab = 0;
  bool saving = false;
  String? createdId;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    name = TextEditingController(text: widget.group?.name ?? '');
    members = {...widget.group?.members ?? []};
    avatar = widget.group?.avatar;
  }

  @override
  void dispose() {
    name.dispose();
    tabs.dispose();
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
          TabBar(
            controller: tabs,
            onTap: (i) => setState(() => tab = i),
            tabs: const [
              Tab(text: '基础信息'),
              Tab(text: '成员'),
            ],
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
      tabs.animateTo(0);
      setState(() => tab = 0);
      toast(context, '请填写群聊名称');
      return;
    }
    if (members.isEmpty) {
      tabs.animateTo(1);
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
