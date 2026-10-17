import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/data/download.dart';
import 'package:rolechat/data/workspace_transfer.dart';
import 'package:rolechat/shared/widgets/app_dialog.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';
import 'package:rolechat/shared/widgets/dialog_helpers.dart';

class DataTransferDialog extends StatefulWidget {
  const DataTransferDialog({super.key, required this.store});
  final PreviewStore store;
  @override
  State<DataTransferDialog> createState() => _DataTransferDialogState();
}

class _DataTransferDialogState extends State<DataTransferDialog> {
  bool includeKeys = false, busy = false;
  String scope = '', message = '';
  bool success = false;
  final transfer = WorkspaceTransfer();
  Future<void> perform(Future<void> Function() task) async {
    setState(() {
      busy = true;
      message = '';
    });
    try {
      await task();
    } catch (e) {
      if (mounted) {
        setState(() {
          success = false;
          message = '操作失败：${e is FormatException ? e.message : '无法读写本地文件'}';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppDialog.content(
    title: const Text('本地数据'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('配置、角色文档和聊天记录保存在当前浏览器内部文件系统。清理站点数据会删除它们，请定期导出。'),
          const SizedBox(height: 20),
          AnchoredSelect<String>(
            label: '导出范围',
            value: scope,
            options: {
              '': '完整数据',
              for (final r in widget.store.roles) r.id: r.name,
            },
            onChanged: busy ? (_) {} : (v) => setState(() => scope = v),
          ),
          const SizedBox(height: 8),
          const Text(
            '单角色导出包含相关配置、头像、身份、灵魂、记忆和行程，不包含聊天记录。',
            style: TextStyle(fontSize: 12),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: includeKeys,
            title: const Text('同时导出 API Key'),
            subtitle: const Text('默认不包含；勾选后 ZIP 会包含明文凭据。'),
            onChanged: busy ? null : (v) => setState(() => includeKeys = v!),
          ),
          if (message.isNotEmpty)
            Text(
              message,
              style: TextStyle(
                color: success
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
      TextButton(
        onPressed: busy ? null : () => perform(importZip),
        child: const Text('导入 ZIP'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () => perform(() async {
                final bytes = transfer.export(
                  widget.store.data,
                  includeKeys: includeKeys,
                  roleId: scope.isEmpty ? null : scope,
                );
                downloadFile(
                  'RoleChat-${scope.isEmpty ? 'backup' : 'character'}-${DateTime.now().millisecondsSinceEpoch}.zip',
                  bytes,
                );
                setState(() {
                  success = true;
                  message = '已生成导出文件。';
                });
              }),
        child: Text(busy ? '处理中…' : '导出 ZIP'),
      ),
    ],
  );
  Future<void> importZip() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'RoleChat ZIP', extensions: ['zip']),
      ],
    );
    if (file == null || !mounted) return;
    if (await file.length() > WorkspaceTransfer.maxBytes) {
      throw const FormatException('导入包不能超过100MB');
    }
    final incoming = transfer.inspect(await file.readAsBytes());
    if (!mounted) return;
    final conflicts = transfer.conflicts(widget.store.data, incoming);
    final choices = {for (final c in conflicts) c.id: ImportChoice.keepBoth};
    final accepted = await managedDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, update) => AppDialog.content(
          title: const Text('确认导入'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '导入 ${incoming.roles.length} 个角色、${incoming.chats.length} 个会话。无冲突内容保留原 UUID，未勾选导出的 Key 需重新填写。',
                ),
                for (final c in conflicts)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AnchoredSelect<ImportChoice>(
                      label: '${c.type}：${c.name}',
                      value: choices[c.id]!,
                      options: const {
                        ImportChoice.keepBoth: '均保留（导入内容使用新标识）',
                        ImportChoice.replace: '覆盖（只保留导入目录）',
                      },
                      onChanged: (v) => update(() => choices[c.id] = v),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('导入'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    final merged = transfer.merge(widget.store.data, incoming, choices);
    await widget.store.importData(merged);
    if (mounted) {
      setState(() {
        success = true;
        message = '导入完成。';
      });
    }
  }
}
