import 'package:flutter/material.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/shared/widgets/avatar_field.dart';
import 'package:rolechat/shared/widgets/profile_name.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';

class RoleBasicTab extends StatelessWidget {
  const RoleBasicTab({
    super.key,
    required this.name,
    required this.model,
    required this.avatar,
    required this.api,
    required this.apiOptions,
    required this.onAvatarChanged,
    required this.onApiChanged,
    required this.onNameChanged,
    required this.onNameCommitted,
  });
  final TextEditingController name, model;
  final String? avatar, api;
  final Map<String, String> apiOptions;
  final ValueChanged<String?> onAvatarChanged;
  final ValueChanged<String> onApiChanged, onNameCommitted;
  final VoidCallback onNameChanged;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AvatarField(
        name: name.text,
        imageData: avatar,
        onChanged: onAvatarChanged,
        trailing: ProfileName(
          controller: name,
          onChanged: onNameChanged,
          onCommitted: onNameCommitted,
        ),
      ),
      const SizedBox(height: 24),
      AnchoredSelect<String>(
        label: 'API 配置（展示）',
        value: api ?? '',
        options: apiOptions,
        onChanged: onApiChanged,
      ),
      const SizedBox(height: 20),
      TextField(
        controller: model,
        style: FormMetrics.textStyle,
        decoration: FormMetrics.decoration('模型'),
      ),
    ],
  );
}
