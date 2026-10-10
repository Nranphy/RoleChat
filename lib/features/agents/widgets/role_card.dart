import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/role_avatar.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.r,
    required this.onOpen,
    required this.onChat,
    required this.onDelete,
  });
  final RoleProfile r;
  final VoidCallback onOpen, onChat, onDelete;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            RoleAvatar(r.name, imageData: r.avatar, size: 80),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(r.model, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '进入私聊',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onChat,
                ),
                IconButton(
                  tooltip: '删除角色',
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
