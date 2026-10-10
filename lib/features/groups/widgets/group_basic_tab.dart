import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/avatar_field.dart';
import 'package:rolechat/shared/widgets/profile_name.dart';

class GroupBasicTab extends StatelessWidget {
  const GroupBasicTab({
    super.key,
    required this.name,
    required this.avatar,
    required this.memberCount,
    required this.onAvatarChanged,
    required this.onNameChanged,
    required this.onNameCommitted,
  });
  final TextEditingController name;
  final String? avatar;
  final int memberCount;
  final ValueChanged<String?> onAvatarChanged;
  final VoidCallback onNameChanged;
  final ValueChanged<String> onNameCommitted;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AvatarField(
        group: true,
        name: name.text,
        imageData: avatar,
        onChanged: onAvatarChanged,
        trailing: ProfileName(
          controller: name,
          onChanged: onNameChanged,
          onCommitted: onNameCommitted,
        ),
      ),
      const SizedBox(height: 16),
      Text('${memberCount + 1} 位成员'),
    ],
  );
}
