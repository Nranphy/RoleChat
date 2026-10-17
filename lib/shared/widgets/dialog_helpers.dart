import 'package:rolechat/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  String action = '删除',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog.content(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<T?> managedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}
