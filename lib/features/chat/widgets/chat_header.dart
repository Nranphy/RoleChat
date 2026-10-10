import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.c,
    required this.avatar,
    required this.wide,
    required this.onBack,
    required this.onInfo,
    required this.onSearch,
    required this.onMenuSelected,
  });
  final Conversation c;
  final String? avatar;
  final bool wide;
  final VoidCallback onBack, onInfo, onSearch;
  final ValueChanged<String> onMenuSelected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (!wide)
            IconButton(
              tooltip: '返回会话',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                onTap: onInfo,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      RoleAvatar(
                        c.name,
                        size: 56,
                        imageData: avatar,
                        icon: c.group
                            ? Icons.group_outlined
                            : Icons.person_outline,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (c.group)
                              Text(
                                '${c.members.length + 1} 位成员',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '搜索聊天记录',
            onPressed: onSearch,
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            clipBehavior: Clip.antiAlias,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            tooltip: '会话菜单',
            onSelected: onMenuSelected,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'info', child: Text('会话资料')),
              const PopupMenuItem(value: 'typing', child: Text('切换输入中效果')),
              const PopupMenuItem(value: 'clear', child: Text('清空展示消息')),
            ],
          ),
        ],
      ),
    );
  }
}
