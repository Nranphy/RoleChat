import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'group_editor_dialog.dart';

Future<void> editGroup(
  BuildContext context,
  PreviewStore store, {
  Conversation? group,
}) => managedDialog<void>(
  context: context,
  builder: (_) => GroupEditorDialog(store: store, group: group),
);
