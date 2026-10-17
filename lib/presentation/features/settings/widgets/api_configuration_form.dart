import 'package:rolechat/presentation/shared/widgets/check_result_note.dart';
import 'package:flutter/material.dart';

class ApiConfigurationForm extends StatelessWidget {
  const ApiConfigurationForm({
    super.key,
    required this.name,
    required this.url,
    required this.apiKey,
    required this.hidden,
    required this.onToggleVisibility,
    this.onConnectionChanged,
    this.checkMessage,
    this.checkSucceeded = false,
  });
  final TextEditingController name, url, apiKey;
  final bool hidden, checkSucceeded;
  final String? checkMessage;
  final ValueChanged<String>? onConnectionChanged;
  final VoidCallback onToggleVisibility;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextFormField(
        controller: name,
        decoration: const InputDecoration(labelText: '配置名称'),
        validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: url,
        onChanged: onConnectionChanged,
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
        controller: apiKey,
        onChanged: onConnectionChanged,
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
            onPressed: onToggleVisibility,
          ),
        ),
      ),
      if (checkMessage != null) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: CheckResultNote(
            message: checkMessage!,
            success: checkSucceeded,
          ),
        ),
      ],
    ],
  );
}
