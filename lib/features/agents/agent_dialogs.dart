import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'role_editor_dialog.dart';

Future<void> editRole(
  BuildContext context,
  PreviewStore store, {
  RoleProfile? role,
}) => managedDialog<void>(
  context: context,
  builder: (_) => RoleEditorDialog(store: store, role: role),
);

void showRoleDetail(
  BuildContext context,
  PreviewStore store,
  RoleProfile role,
) => editRole(context, store, role: role);
