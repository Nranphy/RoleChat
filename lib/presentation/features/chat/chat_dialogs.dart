import 'package:rolechat/presentation/features/chat/widgets/chat_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';
import 'package:rolechat/presentation/features/groups/group_dialogs.dart';
import 'package:rolechat/presentation/features/agents/agent_dialogs.dart';

Future<String?> showChatSearch(
  BuildContext context,
  Conversation c,
  List<RoleProfile> roles,
) => managedDialog<String>(
  context: context,
  builder: (_) => ChatSearchDialog(conversation: c, roles: roles),
);

void showInfo(BuildContext context, AppStore store, Conversation c) {
  if (!c.group && c.members.isNotEmpty) {
    showRoleDetail(context, store, store.role(c.members.first));
    return;
  }
  editGroup(context, store, group: c);
}
