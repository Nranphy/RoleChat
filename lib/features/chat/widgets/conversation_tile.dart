import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/design/app_theme.dart';
import 'package:rolechat/shared/widgets/role_avatar.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.c,
    required this.avatar,
    required this.selected,
    required this.hovered,
    required this.onHoverChanged,
    required this.onSelect,
    required this.onEdit,
  });
  final Conversation c;
  final String? avatar;
  final bool selected, hovered;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: TweenAnimationBuilder<Color?>(
        duration: Duration(milliseconds: selected ? 0 : 100),
        curve: Curves.easeOut,
        tween: ColorTween(
          end: selected
              ? scheme.secondaryContainer
              : hovered
              ? scheme.surfaceContainerHigh
              : scheme.surface,
        ),
        builder: (context, color, child) => Material(
          key: ValueKey(c.id),
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelect,
            excludeFromSemantics: true,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: '编辑 ${c.name}',
                    child: GestureDetector(
                      onTap: onEdit,
                      child: RoleAvatar(
                        c.name,
                        imageData: avatar,
                        size: 56,
                        icon: c.group
                            ? Icons.group_outlined
                            : Icons.person_outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: onSelect,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Text(
                                  c.messages.isEmpty
                                      ? ''
                                      : c.messages.last.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.messages.isEmpty
                                  ? '暂无消息'
                                  : c.messages.last.text.replaceAll('\n', ' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
