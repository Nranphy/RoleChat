import 'model_settings_dialog.dart';
import 'package:rolechat/shared/widgets/dialog_helpers.dart';
import 'package:rolechat/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/services/api_check_controller.dart';
import 'package:rolechat/services/model_availability_checker.dart';
import 'widgets/api_configuration_form.dart';

class ApiEditorDialog extends StatefulWidget {
  const ApiEditorDialog({
    super.key,
    required this.store,
    this.profile,
    this.checker,
  });
  final PreviewStore store;
  final ApiProfile? profile;
  final ModelAvailabilityChecker? checker;
  @override
  State<ApiEditorDialog> createState() => _ApiEditorDialogState();
}

class _ApiEditorDialogState extends State<ApiEditorDialog> {
  late final TextEditingController name, url, key;
  final form = GlobalKey<FormState>();
  final check = ApiCheckController();
  bool hidden = true;
  late final Map<String, ModelSettings> models;
  @override
  void initState() {
    super.initState();
    models = {
      for (final e
          in (widget.profile?.models ?? <String, ModelSettings>{}).entries)
        e.key: ModelSettings.fromJson(e.value.toJson()),
    };
    name = TextEditingController(text: widget.profile?.name ?? '');
    url = TextEditingController(text: widget.profile?.url ?? '');
    key = TextEditingController(text: widget.profile?.key ?? '');
  }

  @override
  void dispose() {
    check.dispose();
    name.dispose();
    url.dispose();
    key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: check,
    builder: (context, _) => AppDialog.content(
      title: Text(widget.profile == null ? '添加 API 配置' : '编辑 API 配置'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApiConfigurationForm(
                  name: name,
                  url: url,
                  apiKey: key,
                  hidden: hidden,
                  onToggleVisibility: () => setState(() => hidden = !hidden),
                  checkMessage: check.result?.message,
                  checkSucceeded: check.result?.success ?? false,
                  onConnectionChanged: (_) => check.invalidate(),
                ),
                const SizedBox(height: 16),
                for (final e in models.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.key),
                    subtitle: Text(
                      '并发 ${e.value.concurrency} · 超时 ${e.value.timeoutSeconds}s',
                    ),
                    onTap: () => editModel(e.key, e.value),
                    trailing: IconButton(
                      tooltip: '删除模型配置',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => models.remove(e.key)),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => editModel('', null),
                    icon: const Icon(Icons.add),
                    label: const Text('添加模型配置'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: check.running
              ? null
              : () => check.run(
                  () => (widget.checker ?? ModelAvailabilityChecker()).checkApi(
                    address: url.text,
                    apiKey: key.text,
                  ),
                ),
          child: Text(check.running ? '检查中…' : '检查接口'),
        ),
        FilledButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: save,
          child: const Text('保存'),
        ),
      ],
    ),
  );
  Future<void> editModel(String original, ModelSettings? value) async {
    final result = await managedDialog<(String, ModelSettings)>(
      context: context,
      builder: (_) => ModelSettingsDialog(model: original, settings: value),
    );
    if (result == null || !mounted) return;
    setState(() {
      models.remove(original);
      models[result.$1] = result.$2;
    });
  }

  void save() {
    if (!form.currentState!.validate()) return;
    final profile =
        widget.profile ??
        ApiProfile(id: widget.store.newId(), name: '', url: '');
    profile.name = name.text.trim();
    profile.url = url.text.trim();
    profile.key = key.text;
    profile.models = models;
    if (widget.profile == null) widget.store.apis.add(profile);
    widget.store.changed();
    Navigator.pop(context);
  }
}
