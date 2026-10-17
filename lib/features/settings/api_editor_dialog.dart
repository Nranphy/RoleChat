import 'widgets/model_configuration_fields.dart';
import 'package:rolechat/shared/widgets/editor_section.dart';
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
  bool saving = false;
  late final List<ModelConfigurationDraft> models;
  final removedModels = <ModelConfigurationDraft>[];
  @override
  void initState() {
    super.initState();
    models = [
      for (final e
          in (widget.profile?.models ?? <String, ModelSettings>{}).entries)
        ModelConfigurationDraft(e.key, e.value),
    ];
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
    for (final model in [...models, ...removedModels]) {
      model.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: check,
    builder: (context, _) => AppDialog.content(
      title: Text(widget.profile == null ? '添加 API 配置' : '编辑 API 配置'),
      content: SizedBox(
        width: 560,
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '模型',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                if (models.isEmpty) const EditorEmptyState('暂无模型'),
                for (final model in models)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EditableEntryCard(
                      key: ObjectKey(model),
                      title: '模型 ${models.indexOf(model) + 1}',
                      deleteTooltip: '删除模型配置',
                      onDelete: () => setState(() {
                        models.remove(model);
                        removedModels.add(model);
                      }),
                      children: [
                        ModelConfigurationFields(draft: model),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => models.add(ModelConfigurationDraft(''))),
                    icon: const Icon(Icons.add),
                    label: const Text('添加模型'),
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
          onPressed: saving ? null : save,
          child: const Text('保存'),
        ),
      ],
    ),
  );
  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await _save();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    final configured = <String, ModelSettings>{};
    try {
      for (final model in models) {
        final id = model.name.text.trim();
        if (configured.containsKey(id)) {
          throw const FormatException('同一 API 下的模型 ID 不能重复');
        }
        configured[id] = model.value();
      }
    } catch (e) {
      toast(context, e is FormatException ? e.message.toString() : '请检查模型参数');
      return;
    }
    final renamed = {
      for (final model in models)
        if (model.original.isNotEmpty) model.original: model.name.text.trim(),
    };
    final affected = widget.store.profileActions.affectedByRemovedModels(
      widget.profile?.id,
      configured.keys.toSet(),
      renamed,
    );
    if (affected.isNotEmpty) {
      final accepted = await confirm(
        context,
        title: '删除正在使用的模型？',
        body:
            '以下角色需要重新选择模型：${affected.map((r) => r.name).join('、')}。聊天记录和角色资料会保留。',
      );
      if (!accepted || !mounted) return;
    }
    final draft = ApiProfile(
      id: widget.profile?.id ?? widget.store.newId(),
      name: name.text.trim(),
      url: url.text.trim(),
      key: key.text,
      models: configured,
    );
    final saved = await widget.store.saveApi(draft, renamed: renamed);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      toast(context, widget.store.persistenceError!);
    }
  }
}
