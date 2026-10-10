import 'package:flutter/material.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/shared/widgets/common.dart';

Future<String?> editText(
  BuildContext context,
  String title,
  String value, {
  String label = '内容',
}) async {
  final controller = TextEditingController(text: value);
  final result = await managedDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 14,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
