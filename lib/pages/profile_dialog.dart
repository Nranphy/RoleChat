import '../shared/widgets/profile_dialog_frame.dart';
import '../shared/widgets/editor_section.dart';
import 'package:flutter/material.dart';
import '../design/form_metrics.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/avatar_field.dart';
import '../widgets/profile_name.dart';
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
  late final TextEditingController name, model, identity, soul, memoryDocument;
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
  Widget build(BuildContext context) => ProfileDialogFrame(
    title: widget.role == null ? '新建角色' : '角色资料',
    saving: saving,
    onSave: save,
    saveLabel: widget.role == null ? '创建角色' : '保存',
    tabs: TabBar(
      controller: tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      onTap: (i) => setState(() => tab = i),
      tabs: [
        '基础',
        '样例',
        '身份',
        '灵魂',
        '记忆',
        '行程',
      ].map((label) => Tab(text: label)).toList(),
    ),
    child: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (tab) {
            0 => basic(),
            1 => qa(),
            2 => document(identity, 'identity.md', '声明 Agent 的身份。'),
            3 => document(soul, 'soul.md', '控制 Agent 的性格和观念（会自主更新）。'),
            4 => document(
              memoryDocument,
              'memory.md',
              '记录 Agent 的记忆内容（会自主更新）。',
            ),
            _ => schedule(),
          },
        ],
      ),
    ),
  );
  Widget basic() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AvatarField(
        name: name.text,
        imageData: avatar,
        onChanged: (v) => setState(() => avatar = v),
        trailing: ProfileName(
          controller: name,
          onChanged: () => setState(() {}),
          onCommitted: commitName,
        ),
      ),
      const SizedBox(height: 24),
      AnchoredSelect<String>(
        label: 'API 配置（展示）',
        value: api ?? '',
        options: {'': '暂不选择', for (final a in widget.store.apis) a.id: a.name},
        onChanged: (v) => setState(() => api = v.isEmpty ? null : v),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: model,
        style: FormMetrics.textStyle,
        decoration: FormMetrics.decoration('模型'),
      ),
    ],
  );
  void commitName(String value) {
    final role = widget.role;
    if (role != null) {
      role.name = value.isEmpty ? '未命名' : value;
      for (final c in widget.store.conversations.where(
        (c) => !c.group && c.members.contains(role.id),
      )) {
        c.name = role.name;
      }
      widget.store.changed();
    }
    setState(() {});
  }

  Widget note(String explanation, {VoidCallback? onAdd}) =>
      EditorSectionNote(explanation, onAdd: onAdd);
  Widget emptyTab(String text) => EditorEmptyState(text);
  Widget document(
    TextEditingController controller,
    String title,
    String explanation,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      note(explanation),
      TextField(
        controller: controller,
        minLines: 10,
        maxLines: 20,
        decoration: InputDecoration(labelText: title, alignLabelWithHint: true),
      ),
    ],
  );
  Widget qa() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      note(
        '供 Agent 参考对话风格。',
        onAdd: () => setState(() => examples.add((text(''), text('')))),
      ),
      if (examples.isEmpty) emptyTab('暂无样例'),
      ...examples.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EditableEntryCard(
            title: '示例 ${e.key + 1}',
            deleteTooltip: '移除示例',
            onDelete: () => setState(() => examples.removeAt(e.key)),
            children: [
              TextField(
                controller: e.value.$1,
                style: FormMetrics.textStyle,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                decoration: FormMetrics.decoration('user'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: e.value.$2,
                style: FormMetrics.textStyle,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                decoration: FormMetrics.decoration('assistant'),
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
      note(
        '用于 Agent 的角色扮演。',
        onAdd: () => setState(() => schedules.add(ScheduleDraft())),
      ),
      if (schedules.isEmpty) emptyTab('暂无行程'),
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
  Widget build(BuildContext context) => ProfileDialogFrame(
    title: widget.group == null ? '新建群聊' : '群聊资料',
    saving: saving,
    onSave: save,
    maxWidth: 640,
    maxHeight: 680,
    tabGap: 12,
    tabs: TabBar(
      controller: tabs,
      onTap: (i) => setState(() => tab = i),
      tabs: const [
        Tab(text: '基础'),
        Tab(text: '成员'),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tab == 0
          ? [
              AvatarField(
                group: true,
                name: name.text,
                imageData: avatar,
                onChanged: (v) => setState(() => avatar = v),
                trailing: ProfileName(
                  controller: name,
                  onChanged: () => setState(() {}),
                  onCommitted: (value) {
                    if (widget.group != null) {
                      widget.group!.name = value.isEmpty ? '未命名' : value;
                      widget.store.changed();
                    }
                    setState(() {});
                  },
                ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: RoleAvatar(
                      r.name,
                      size: 38,
                      imageData: r.avatar,
                    ),
                    title: Text(r.name),
                    value: members.contains(r.id),
                    onChanged: (v) => setState(
                      () =>
                          v == true ? members.add(r.id) : members.remove(r.id),
                    ),
                  ),
                )
                .toList(),
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
