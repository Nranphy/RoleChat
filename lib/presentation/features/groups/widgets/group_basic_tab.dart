import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/profile_identity_header.dart';

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
      ProfileIdentityHeader(
        name: name,
        avatar: avatar,
        group: true,
        onAvatarChanged: onAvatarChanged,
        onNameChanged: onNameChanged,
        onNameCommitted: onNameCommitted,
      ),
      const SizedBox(height: 16),
      Text('${memberCount + 1} 位成员'),
    ],
  );
}
