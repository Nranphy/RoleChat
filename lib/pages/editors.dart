import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/common.dart';
import '../widgets/avatar_field.dart';

Future<void> editRole(
  BuildContext context,
  PreviewStore store, {
  RoleProfile? role,
}) async {
  final name = TextEditingController(text: role?.name ?? '');
  final description = TextEditingController(text: role?.description ?? '');
  final model = TextEditingController(text: role?.model ?? 'gpt-4o');
  final identity = TextEditingController(text: role?.identity ?? '');
  final retiredControllers = <TextEditingController>[];
  String? avatar = role?.avatar;
  var api = role?.apiId;
  final form = GlobalKey<FormState>();
  final examples = (role?.examples ?? [])
      .map(
        (e) => (
          TextEditingController(text: e['question']),
          TextEditingController(text: e['answer']),
        ),
      )
      .toList();
  await managedDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        role == null ? '新建角色' : '编辑角色',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarField(
                          imageData: avatar,
                          onChanged: (value) => setLocal(() => avatar = value),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: '名称'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? '请填写角色名称' : null,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: description,
                          decoration: const InputDecoration(labelText: '一句话介绍'),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          borderRadius: BorderRadius.circular(16),
                          initialValue: api,
                          decoration: const InputDecoration(
                            labelText: 'API 配置（展示）',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('暂不选择'),
                            ),
                            ...store.apis.map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => api = v,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: model,
                          decoration: const InputDecoration(labelText: '模型'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: identity,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'identity.md',
                            hintText: '这个角色是谁？喜欢什么，如何说话？',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'QA 对话示例',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => setLocal(
                                () => examples.add((
                                  TextEditingController(),
                                  TextEditingController(),
                                )),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('添加'),
                            ),
                          ],
                        ),
                        ...examples.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: SectionCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('示例 ${entry.key + 1}'),
                                      ),
                                      IconButton(
                                        tooltip: '移除示例',
                                        onPressed: () => setLocal(() {
                                          final removed = examples.removeAt(
                                            entry.key,
                                          );
                                          retiredControllers.addAll([
                                            removed.$1,
                                            removed.$2,
                                          ]);
                                        }),
                                        icon: const Icon(Icons.close, size: 18),
                                      ),
                                    ],
                                  ),
                                  TextField(
                                    controller: entry.value.$1,
                                    decoration: const InputDecoration(
                                      labelText: '用户说',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: entry.value.$2,
                                    decoration: const InputDecoration(
                                      labelText: '角色回答',
                                    ),
                                    minLines: 2,
                                    maxLines: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const PreviewNotice(text: '资料保存在当前浏览器，不会调用模型。'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        final profile =
                            role ??
                            RoleProfile(
                              id: store.newId(),
                              name: name.text.trim(),
                              avatar: avatar,
                              color: const Color(0xffb8cfbb),
                            );
                        profile.name = name.text.trim();
                        profile.avatar = avatar;
                        profile.description = description.text;
                        profile.model = model.text;
                        profile.apiId = api;
                        profile.identity = identity.text;
                        profile.examples = examples
                            .map(
                              (e) => {
                                'question': e.$1.text,
                                'answer': e.$2.text,
                              },
                            )
                            .toList();
                        if (role == null) {
                          store.addRole(profile);
                        } else {
                          for (final c in store.conversations.where(
                            (c) => !c.group && c.members.contains(role.id),
                          )) {
                            c.name = profile.name;
                            c.emoji = profile.emoji;
                          }
                          store.changed();
                        }
                        if (!await store.saveProfiles()) {
                          if (context.mounted) {
                            toast(context, store.persistenceError!);
                          }
                          return;
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(role == null ? '创建角色' : '保存'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  for (final c in [
    name,
    description,
    model,
    identity,
    ...examples.expand((e) => [e.$1, e.$2]),
    ...retiredControllers,
  ]) {
    c.dispose();
  }
}

Future<void> editGroup(
  BuildContext context,
  PreviewStore store, {
  Conversation? group,
}) async {
  final name = TextEditingController(text: group?.name ?? '');
  String? avatar = group?.avatar;
  final members = {...group?.members ?? []};
  final form = GlobalKey<FormState>();
  await managedDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(group == null ? '新建群聊' : '编辑群聊'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarField(
                    group: true,
                    imageData: avatar,
                    onChanged: (v) => setLocal(() => avatar = v),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '群聊名称'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '请填写名称' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('选择加入的角色'),
                  const SizedBox(height: 8),
                  ...store.roles.map(
                    (r) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: RoleAvatar(
                        r.name,
                        size: 38,
                        imageData: r.avatar,
                      ),
                      title: Text(r.name),
                      value: members.contains(r.id),
                      onChanged: (v) => setLocal(
                        () => v == true
                            ? members.add(r.id)
                            : members.remove(r.id),
                      ),
                    ),
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
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              if (members.isEmpty) {
                toast(context, '至少选择一个角色');
                return;
              }
              if (group == null) {
                store.addGroup(
                  name.text.trim(),
                  members.toList(),
                  avatar: avatar,
                );
              } else {
                group.name = name.text.trim();
                group.avatar = avatar;
                group.members = members.toList();
                store.changed();
              }
              if (!await store.saveProfiles()) {
                if (context.mounted) toast(context, store.persistenceError!);
                return;
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
}

Future<void> editApi(
  BuildContext context,
  PreviewStore store, {
  ApiProfile? profile,
}) async {
  final name = TextEditingController(text: profile?.name ?? '');
  final url = TextEditingController(text: profile?.url ?? '');
  final key = TextEditingController(text: profile?.key ?? '');
  var hidden = true;
  final form = GlobalKey<FormState>();
  await managedDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(profile == null ? '添加 API 配置' : '编辑 API 配置'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '配置名称'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '请输入名称' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: url,
                    decoration: const InputDecoration(
                      labelText: '接口地址',
                      hintText: 'https://api.example.com/v1',
                    ),
                    validator: (v) {
                      final u = Uri.tryParse(v ?? '');
                      return u == null ||
                              !u.hasAuthority ||
                              !['http', 'https'].contains(u.scheme)
                          ? '请输入有效的 HTTP 或 HTTPS 地址'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: key,
                    obscureText: hidden,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      suffixIcon: IconButton(
                        tooltip: hidden ? '显示密钥' : '隐藏密钥',
                        icon: Icon(
                          hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setLocal(() => hidden = !hidden),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const PreviewNotice(text: '只预览配置表单。不测试连接、不保存真实密钥，请勿填写有效凭据。'),
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
              final p =
                  profile ?? ApiProfile(id: store.newId(), name: '', url: '');
              p.name = name.text.trim();
              p.url = url.text.trim();
              p.key = key.text;
              if (profile == null) store.apis.add(p);
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
  url.dispose();
  key.dispose();
}

Future<String?> editText(
  BuildContext context,
  String title,
  String value, {
  String label = '内容',
}) async {
  final controller = TextEditingController(text: value);
  final result = await managedDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 14,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
