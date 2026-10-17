import 'package:flutter/material.dart';
import '../../../models/preview_models.dart';
import '../../../shared/widgets/anchored_select.dart';

/// Unsaved API-owned model settings; disposed by the API editor.
class ModelConfigurationDraft {
  ModelConfigurationDraft(String model, [ModelSettings? settings])
    : original = model,
      name = TextEditingController(text: model) {
    final value = settings ?? ModelSettings();
    protocol = value.protocol;
    fields = {
      for (final key in labels.keys)
        key: TextEditingController(text: value.toJson()[key].toString()),
    };
  }
  static const labels = {
    'contextTokens': '上下文上限 tokens',
    'historyHigh': '历史高水位 tokens',
    'historyTarget': '裁剪后目标 tokens',
    'maxOutput': '最大输出 tokens',
    'concurrency': '请求并发数',
    'timeoutSeconds': '超时（秒）',
  };
  final String original;
  final TextEditingController name;
  late final Map<String, TextEditingController> fields;
  late String protocol;
  ModelSettings value() {
    final value = ModelSettings.fromJson({
      for (final entry in fields.entries)
        entry.key: int.parse(entry.value.text),
      'protocol': protocol,
    });
    value.validate();
    return value;
  }

  void dispose() {
    name.dispose();
    for (final field in fields.values) {
      field.dispose();
    }
  }
}

class ModelConfigurationFields extends StatefulWidget {
  const ModelConfigurationFields({super.key, required this.draft});
  final ModelConfigurationDraft draft;
  @override
  State<ModelConfigurationFields> createState() =>
      _ModelConfigurationFieldsState();
}

class _ModelConfigurationFieldsState extends State<ModelConfigurationFields> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: draft.name,
          decoration: const InputDecoration(
            labelText: '模型 ID',
            hintText: '服务端使用的模型名称',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? '请输入模型 ID' : null,
        ),
        const SizedBox(height: 14),
        AnchoredSelect<String>(
          label: '接口协议',
          value: draft.protocol,
          options: const {'chat': 'Chat Completions', 'responses': 'Responses'},
          onChanged: (v) => setState(() => draft.protocol = v),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 420
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final entry in ModelConfigurationDraft.labels.entries)
                    SizedBox(
                      width: width,
                      child: TextFormField(
                        controller: draft.fields[entry.key],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: entry.value),
                        validator: (v) =>
                            int.tryParse(v ?? '') == null ? '请输入整数' : null,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
