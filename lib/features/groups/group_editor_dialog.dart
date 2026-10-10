import 'package:rolechat/shared/widgets/document_editor_tab.dart';
import 'widgets/group_basic_tab.dart';
import 'widgets/group_members_tab.dart';
import 'package:rolechat/shared/widgets/profile_dialog_frame.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

class GroupEditorDialog extends StatefulWidget {
  const GroupEditorDialog({super.key, required this.store, this.group});
  final PreviewStore store;
  final Conversation? group;
  @override
  State<GroupEditorDialog> createState() => _GroupEditorDialogState();
}

class _GroupEditorDialogState extends State<GroupEditorDialog> {
  late final TextEditingController name, background;
  late final Set<String> members;
  String? avatar;
  int tab = 0;
  bool saving = false;
  String? createdId;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.group?.name ?? '');
    background = TextEditingController(text: widget.group?.background ?? '');
    members = {...widget.group?.members ?? []};
    avatar = widget.group?.avatar;
  }

  @override
  void dispose() {
    name.dispose();
    background.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfileDialogFrame(
    title: widget.group == null ? '新建群聊' : '群聊资料',
    saving: saving,
    onSave: save,
    selectedIndex: tab,
    onTabChanged: (i) => setState(() => tab = i),
    tabs: [
      ProfileDialogTab(
        '基础',
        GroupBasicTab(
          name: name,
          avatar: avatar,
          memberCount: members.length,
          onAvatarChanged: (v) => setState(() => avatar = v),
          onNameChanged: () => setState(() {}),
          onNameCommitted: (value) {
            if (widget.group != null) {
              widget.group!.name = value.isEmpty ? '未命名' : value;
              widget.store.changed();
            }
            setState(() {});
          },
        ),
      ),
      ProfileDialogTab(
        '背景',
        DocumentEditorTab(
          controller: background,
          title: 'background.md',
          explanation: '介绍群聊的背景。',
        ),
      ),
      ProfileDialogTab(
        '成员',
        GroupMembersTab(
          roles: widget.store.roles,
          members: members,
          onMemberChanged: (id, v) =>
              setState(() => v ? members.add(id) : members.remove(id)),
        ),
      ),
    ],
  );
  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      setState(() => tab = 0);
      toast(context, '请填写群聊名称');
      return;
    }
    if (members.isEmpty) {
      setState(() => tab = 2);
      toast(context, '至少选择一个角色');
      return;
    }
    setState(() => saving = true);
    final store = widget.store;
    final group =
        widget.group ??
        store.conversations.where((c) => c.id == createdId).firstOrNull;
    if (group == null) {
      store.addGroup(
        name.text.trim(),
        members.toList(),
        avatar: avatar,
        background: background.text,
      );
      createdId = store.selected.id;
    } else {
      group.name = name.text.trim();
      group.avatar = avatar;
      group.background = background.text;
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
