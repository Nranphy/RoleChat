import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/models/preview_models.dart';

class ApiSettings extends StatelessWidget {
  const ApiSettings({
    super.key,
    required this.apis,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final List<ApiProfile> apis;
  final VoidCallback onAdd;
  final ValueChanged<ApiProfile> onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'API 配置',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SettingsSection(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            if (apis.isEmpty)
              const EmptyState(title: '还没有接口配置', subtitle: '这里只展示表单，不会连接外部接口。'),
            ...apis.map(
              (a) => SettingsRow(
                icon: Icons.dns_outlined,
                title: a.name,
                subtitle: a.url,
                onTap: () => onEdit(a),
                trailing: IconButton(
                  tooltip: '删除 API 配置',
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => onDelete(a),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
