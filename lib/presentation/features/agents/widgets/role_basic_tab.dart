import 'package:rolechat/presentation/shared/widgets/check_result_note.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/profile_identity_header.dart';
import 'package:rolechat/presentation/shared/widgets/anchored_select.dart';

class RoleBasicTab extends StatelessWidget {
  const RoleBasicTab({
    super.key,
    required this.name,
    required this.model,
    required this.avatar,
    required this.api,
    required this.apiOptions,
    required this.modelOptions,
    required this.onAvatarChanged,
    required this.onApiChanged,
    required this.onNameChanged,
    required this.onNameCommitted,
    required this.onCheckModel,
    required this.onModelChanged,
    this.modelCheckMessage,
    this.modelCheckSucceeded = false,
    this.checkingModel = false,
    this.runtimeFields,
  });
  final TextEditingController name;
  final String model;
  final Widget? runtimeFields;
  final String? avatar, api;
  final Map<String, String> apiOptions, modelOptions;
  final ValueChanged<String?> onAvatarChanged;
  final ValueChanged<String> onApiChanged, onNameCommitted;
  final VoidCallback onNameChanged, onCheckModel;
  final ValueChanged<String> onModelChanged;
  final String? modelCheckMessage;
  final bool modelCheckSucceeded, checkingModel;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 8),
      ProfileIdentityHeader(
        name: name,
        avatar: avatar,
        group: false,
        onAvatarChanged: onAvatarChanged,
        onNameChanged: onNameChanged,
        onNameCommitted: onNameCommitted,
      ),
      const SizedBox(height: 16),
      _SectionHeading('模型连接'),
      const SizedBox(height: 14),
      AnchoredSelect<String>(
        label: 'API 配置',
        value: api ?? '',
        options: apiOptions,
        onChanged: onApiChanged,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: AnchoredSelect<String>(
              label: '模型',
              value: model,
              options: modelOptions,
              onChanged: onModelChanged,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '检测模型',
            onPressed: checkingModel || model.isEmpty ? null : onCheckModel,
            icon: checkingModel
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      if (api != null && modelOptions.length == 1)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('此 API 尚未配置模型，请前往设置添加。'),
        ),
      if (modelCheckMessage != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CheckResultNote(
              message: modelCheckMessage!,
              success: modelCheckSucceeded,
            ),
          ),
        ),
      if (runtimeFields != null) ...[
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _SectionHeading('运行设置'),
        const SizedBox(height: 16),
        runtimeFields!,
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}
