import 'package:flutter/material.dart';

class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key, this.text = '界面预览 · 所有角色与对话均为展示数据，未连接模型'});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.science_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
