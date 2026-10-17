import 'package:flutter/material.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';
import 'package:rolechat/presentation/features/agents/role_editor_dialog.dart';

Future<void> editRole(
  BuildContext context,
  AppStore store, {
  RoleProfile? role,
}) => managedDialog<void>(
  context: context,
  builder: (_) => RoleEditorDialog(store: store, role: role),
);

void showRoleDetail(BuildContext context, AppStore store, RoleProfile role) =>
    editRole(context, store, role: role);
