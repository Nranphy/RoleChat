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
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            RoleAvatar(r.name, imageData: r.avatar, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 20,
                  tooltip: '进入私聊',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onChat,
                ),
                IconButton(
                  iconSize: 20,
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
