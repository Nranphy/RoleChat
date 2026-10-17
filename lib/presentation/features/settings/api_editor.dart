import 'package:flutter/material.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/application/apis/ports/api_checker.dart';
import 'package:rolechat/presentation/shared/widgets/dialog_helpers.dart';
import 'package:rolechat/presentation/features/settings/api_editor_dialog.dart';

Future<void> editApi(
  BuildContext context,
  AppStore store, {
  ApiProfile? profile,
  ApiChecker? checker,
}) => managedDialog<void>(
  context: context,
  builder: (_) =>
      ApiEditorDialog(store: store, profile: profile, checker: checker),
);
