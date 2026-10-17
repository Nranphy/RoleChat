import 'package:flutter/material.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';
import 'package:rolechat/presentation/features/groups/group_editor_dialog.dart';

Future<void> editGroup(
  BuildContext context,
  AppStore store, {
  Conversation? group,
}) => managedDialog<void>(
  context: context,
  builder: (_) => GroupEditorDialog(store: store, group: group),
);
