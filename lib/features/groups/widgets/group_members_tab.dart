import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/role_avatar.dart';

class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({
    super.key,
    required this.roles,
    required this.members,
    required this.onMemberChanged,
  });
  final List<RoleProfile> roles;
  final Set<String> members;
  final void Function(String, bool) onMemberChanged;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: roles
        .map(
          (r) => CheckboxListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            secondary: RoleAvatar(r.name, size: 38, imageData: r.avatar),
            title: Text(r.name),
            value: members.contains(r.id),
            onChanged: (v) => onMemberChanged(r.id, v == true),
          ),
        )
        .toList(),
  );
}
