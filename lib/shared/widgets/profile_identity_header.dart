import 'package:flutter/material.dart';
import 'avatar_field.dart';
import 'profile_name.dart';

class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    super.key,
    required this.name,
    required this.avatar,
    required this.onAvatarChanged,
    required this.onNameChanged,
    required this.onNameCommitted,
    this.group = false,
  });
  final TextEditingController name;
  final String? avatar;
  final bool group;
  final ValueChanged<String?> onAvatarChanged;
  final VoidCallback onNameChanged;
  final ValueChanged<String> onNameCommitted;
  @override
  Widget build(BuildContext context) => AvatarField(
    group: group,
    name: name.text,
    imageData: avatar,
    onChanged: onAvatarChanged,
    trailing: ProfileName(
      controller: name,
      onChanged: onNameChanged,
      onCommitted: onNameCommitted,
    ),
  );
}
