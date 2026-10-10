import 'package:rolechat/shared/widgets/profile_dialog_frame.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/avatar_field.dart';
import 'package:rolechat/shared/widgets/profile_name.dart';
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
