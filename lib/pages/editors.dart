import 'package:flutter/material.dart';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import '../widgets/common.dart';
import 'profile_dialog.dart';

Future<void> editRole(
  BuildContext context,
  PreviewStore store, {
  RoleProfile? role,
}) => managedDialog<void>(
  context: context,
  builder: (_) => RoleEditorDialog(store: store, role: role),
);
Future<void> editGroup(
  BuildContext context,
  PreviewStore store, {
  Conversation? group,
}) => managedDialog<void>(
  context: context,
  builder: (_) => GroupEditorDialog(store: store, group: group),
);

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
