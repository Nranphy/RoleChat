import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.name,
    required this.emoji,
    this.avatar,
    this.onAvatarTap,
    this.onReply,
    this.onDelete,
    this.onCopy,
    this.previousSame = false,
    this.nextSame = false,
    this.showName = true,
    this.nameColor,
  });
  final ChatMessage message;
  final String name, emoji;
  final String? avatar;
  final VoidCallback? onAvatarTap, onReply, onDelete, onCopy;
  final bool previousSame, nextSame, showName;
  final Color? nameColor;
  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool hovered = false;
  bool menuOpen = false;
  final menuKey = GlobalKey<PopupMenuButtonState<String>>();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final mine = widget.message.isUser,
        dark = theme.brightness == Brightness.dark;
    final foreground = mine
        ? (dark ? colors.onPrimaryContainer : colors.onPrimary)
        : colors.onSurface;
    final shape = BorderRadius.only(
      topLeft: Radius.circular(mine ? 18 : 3),
      topRight: Radius.circular(mine && widget.previousSame ? 3 : 18),
      bottomLeft: Radius.circular(!mine && widget.nextSame ? 3 : 18),
      bottomRight: Radius.circular(mine ? 3 : 18),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Align(
        alignment: mine ? Alignment.topRight : Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            widget.previousSame ? 1 : 8,
            8,
            widget.nextSame ? 1 : 8,
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mine || widget.previousSame)
                  const SizedBox(width: 48)
                else
                  GestureDetector(
                    onTap: widget.onAvatarTap,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: RoleAvatar(
                        widget.name,
                        size: 48,
                        imageData: widget.avatar,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 570),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: mine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!mine && !widget.previousSame)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 2),
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.showName
                                    ? widget.nameColor ?? colors.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onSecondaryTap: widget.onReply == null
                              ? null
                              : () => menuKey.currentState?.showButtonMenu(),
                          onLongPress: widget.onReply == null
                              ? null
                              : () => menuKey.currentState?.showButtonMenu(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  right: widget.onReply == null ? 0 : 32,
                                ),
                                child: AnimatedContainer(
                                  key: ValueKey(widget.message.id),
                                  duration: const Duration(milliseconds: 120),
                                  decoration: BoxDecoration(
                                    borderRadius: shape,
                                    color: Color.alphaBlend(
                                      foreground.withValues(
                                        alpha: hovered ? .06 : 0,
                                      ),
                                      mine
                                          ? (dark
                                                ? colors.primaryContainer
                                                : colors.primary)
                                          : colors.surfaceContainerHigh,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.message.reply != null)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                width: 3,
                                                color: mine
                                                    ? foreground
                                                    : colors.primary,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            widget.message.reply!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: foreground,
                                            ),
                                          ),
                                        ),
                                      SelectableText(
                                        widget.message.text,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: foreground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.onReply != null)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: IgnorePointer(
                                    ignoring: !(hovered || menuOpen),
                                    child: AnimatedOpacity(
                                      opacity: hovered || menuOpen ? 1 : 0,
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      alwaysIncludeSemantics: true,
                                      child: PopupMenuButton<String>(
                                        key: menuKey,
                                        onOpened: () =>
                                            setState(() => menuOpen = true),
                                        onCanceled: () =>
                                            setState(() => menuOpen = false),
                                        clipBehavior: Clip.antiAlias,
                                        tooltip: '',
                                        position: PopupMenuPosition.under,
                                        offset: const Offset(0, 6),
                                        padding: EdgeInsets.zero,
                                        iconSize: 16,
                                        style: IconButton.styleFrom(
                                          minimumSize: const Size(32, 32),
                                          maximumSize: const Size(32, 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                        icon: Icon(
                                          Icons.more_horiz,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        onSelected: (v) {
                                          setState(() => menuOpen = false);
                                          if (v == 'reply') {
                                            widget.onReply?.call();
                                          }
                                          if (v == 'copy') {
                                            widget.onCopy?.call();
                                          }
                                          if (v == 'delete') {
                                            widget.onDelete?.call();
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'reply',
                                            child: Text('引用回复'),
                                          ),
                                          PopupMenuItem(
                                            value: 'copy',
                                            child: Text('复制'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('删除'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!widget.nextSame)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              8,
                              2,
                              mine && widget.onReply != null ? 40 : 8,
                              2,
                            ),
                            child: Text(
                              widget.message.time,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.onReply != null) const SizedBox(width: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
