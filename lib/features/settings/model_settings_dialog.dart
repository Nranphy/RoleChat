import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/app_dialog.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';

class ModelSettingsDialog extends StatefulWidget {
  const ModelSettingsDialog({super.key, this.model = '', this.settings});
  final String model;
  final ModelSettings? settings;
  @override
  State<ModelSettingsDialog> createState() => _ModelSettingsDialogState();
}

class _ModelSettingsDialogState extends State<ModelSettingsDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final Map<String, TextEditingController> fields;
  String protocol = 'chat';
  String? error;
  final labels = const {
    'contextTokens': '上下文上限 tokens',
    'historyHigh': '历史高水位 tokens',
    'historyTarget': '裁剪后目标 tokens',
    'maxOutput': '最大输出 tokens',
    'concurrency': '请求并发数',
    'timeoutSeconds': '超时（秒）',
  };
  @override
  void initState() {
    super.initState();
    final settings = widget.settings ?? ModelSettings();
    name = TextEditingController(text: widget.model);
    fields = {
      for (final key in labels.keys)
        key: TextEditingController(text: settings.toJson()[key].toString()),
    };
    protocol = settings.protocol;
  }

  @override
  void dispose() {
    name.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDialog.content(
    title: const Text('模型配置'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: '模型'),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入模型' : null,
            ),
            const SizedBox(height: 16),
            AnchoredSelect<String>(
              label: '接口协议',
              value: protocol,
              options: const {
                'chat': 'Chat Completions',
                'responses': 'Responses',
              },
              onChanged: (v) => setState(() => protocol = v),
            ),
            for (final key in labels.keys)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: TextFormField(
                  controller: fields[key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: labels[key]),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? '请输入整数' : null,
                ),
              ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (widget.settings?.toolsUnsupported == true)
              const Text('保存后将重新尝试验证原生工具能力。'),
          ],
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
          final value = ModelSettings.fromJson({
            for (final e in fields.entries) e.key: int.parse(e.value.text),
            'protocol': protocol,
            'toolsUnsupported': false,
          });
          try {
            value.validate();
            Navigator.pop(context, (name.text.trim(), value));
          } on FormatException catch (e) {
            setState(() => error = e.message);
          }
        },
        child: const Text('保存'),
      ),
    ],
  );
}
