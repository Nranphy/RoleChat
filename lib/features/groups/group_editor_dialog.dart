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

class _GroupEditorDialogState extends State<GroupEditorDialog>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late final TextEditingController name, background;
  late final Set<String> members;
  String? avatar;
  int tab = 0;
  bool saving = false;
  String? createdId;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    name = TextEditingController(text: widget.group?.name ?? '');
    background = TextEditingController(text: widget.group?.background ?? '');
    members = {...widget.group?.members ?? []};
    avatar = widget.group?.avatar;
  }

  @override
  void dispose() {
    name.dispose();
    background.dispose();
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
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      onTap: (i) => setState(() => tab = i),
      tabs: const [
        Tab(text: '基础'),
        Tab(text: '成员'),
        Tab(text: '背景'),
      ],
    ),
    child: tab == 2
        ? DocumentEditorTab(
            controller: background,
            title: 'background.md',
            explanation: '介绍群聊的背景。',
          )
        : tab == 0
        ? GroupBasicTab(
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
          )
        : GroupMembersTab(
            roles: widget.store.roles,
            members: members,
            onMemberChanged: (id, v) =>
                setState(() => v ? members.add(id) : members.remove(id)),
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
