import 'editing/schedule_draft.dart';
import 'package:rolechat/shared/widgets/document_editor_tab.dart';
import 'widgets/role_examples_tab.dart';
import 'widgets/role_schedule_tab.dart';
import 'widgets/role_basic_tab.dart';
import 'package:rolechat/shared/widgets/profile_dialog_frame.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

class RoleEditorDialog extends StatefulWidget {
  const RoleEditorDialog({super.key, required this.store, this.role});
  final PreviewStore store;
  final RoleProfile? role;
  @override
  State<RoleEditorDialog> createState() => _RoleEditorDialogState();
}

class _RoleEditorDialogState extends State<RoleEditorDialog> {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfileDialogFrame(
    title: widget.role == null ? '新建角色' : '角色资料',
    saving: saving,
    onSave: save,
    saveLabel: widget.role == null ? '创建角色' : '保存',
    selectedIndex: tab,
    onTabChanged: (i) => setState(() => tab = i),
    formKey: form,
    tabs: [
      ProfileDialogTab(
        '基础',
        RoleBasicTab(
          name: name,
          model: model,
          avatar: avatar,
          api: api,
          apiOptions: {
            '': '暂不选择',
            for (final a in widget.store.apis) a.id: a.name,
          },
          onAvatarChanged: (v) => setState(() => avatar = v),
          onApiChanged: (v) => setState(() => api = v.isEmpty ? null : v),
          onNameChanged: () => setState(() {}),
          onNameCommitted: commitName,
        ),
      ),
      ProfileDialogTab(
        '样例',
        RoleExamplesTab(
          examples: examples,
          onAdd: () => setState(() => examples.add((text(''), text('')))),
          onDelete: (i) => setState(() => examples.removeAt(i)),
        ),
      ),
      ProfileDialogTab(
        '身份',
        DocumentEditorTab(
          controller: identity,
          title: 'identity.md',
          explanation: '声明 Agent 的身份。',
        ),
      ),
      ProfileDialogTab(
        '灵魂',
        DocumentEditorTab(
          controller: soul,
          title: 'soul.md',
          explanation: '控制 Agent 的性格和观念（会自主更新）。',
        ),
      ),
      ProfileDialogTab(
        '记忆',
        DocumentEditorTab(
          controller: memoryDocument,
          title: 'memory.md',
          explanation: '记录 Agent 的记忆内容（会自主更新）。',
        ),
      ),
      ProfileDialogTab(
        '行程',
        RoleScheduleTab(
          schedules: schedules,
          onAdd: () => setState(() => schedules.add(ScheduleDraft())),
          onChanged: () => setState(() {}),
          onDelete: (i) =>
              setState(() => removedSchedules.add(schedules.removeAt(i))),
        ),
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

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
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
