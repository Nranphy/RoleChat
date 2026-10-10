import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/common.dart';

class ApiConfigurationForm extends StatelessWidget {
  const ApiConfigurationForm({
    super.key,
    required this.name,
    required this.url,
    required this.apiKey,
    required this.hidden,
    required this.onToggleVisibility,
  });
  final TextEditingController name, url, apiKey;
  final bool hidden;
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
      const SizedBox(height: 16),
      const PreviewNotice(text: '只预览配置表单。不测试连接、不保存真实密钥，请勿填写有效凭据。'),
    ],
  );
}
