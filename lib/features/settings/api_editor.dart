import 'package:flutter/material.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/services/api_checker.dart';
import 'package:rolechat/shared/widgets/dialog_helpers.dart';
import 'api_editor_dialog.dart';

Future<void> editApi(
  BuildContext context,
  PreviewStore store, {
  ApiProfile? profile,
  ApiChecker? checker,
}) => managedDialog<void>(
  context: context,
  builder: (_) =>
      ApiEditorDialog(store: store, profile: profile, checker: checker),
);
