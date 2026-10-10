import 'package:flutter/material.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/shared/widgets/profile_identity_header.dart';
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
    required this.onCheckModel,
    required this.onModelChanged,
    this.modelCheckMessage,
    this.modelCheckSucceeded = false,
  });
  final TextEditingController name, model;
  final String? avatar, api;
  final Map<String, String> apiOptions;
  final ValueChanged<String?> onAvatarChanged;
  final ValueChanged<String> onApiChanged, onNameCommitted;
  final VoidCallback onNameChanged, onCheckModel;
  final ValueChanged<String> onModelChanged;
  final String? modelCheckMessage;
  final bool modelCheckSucceeded;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ProfileIdentityHeader(
        name: name,
        avatar: avatar,
        group: false,
        onAvatarChanged: onAvatarChanged,
        onNameChanged: onNameChanged,
        onNameCommitted: onNameCommitted,
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
        onChanged: onModelChanged,
        decoration: FormMetrics.decoration('模型').copyWith(
          suffixIcon: IconButton(
            tooltip: '检测模型',
            onPressed: onCheckModel,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ),
      if (modelCheckMessage != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              modelCheckMessage!,
              style: TextStyle(
                fontSize: 12,
                color: modelCheckSucceeded
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade300
                          : Colors.green.shade700)
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
    ],
  );
}
