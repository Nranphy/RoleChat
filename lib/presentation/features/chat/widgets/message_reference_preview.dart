import 'package:flutter/material.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/presentation/features/chat/widgets/sender_color.dart';

class MessageReferencePreview extends StatelessWidget {
  const MessageReferencePreview({
    super.key,
    required this.reference,
    this.onTap,
    this.textColor,
    this.maxLines = 2,
  });
  final MessageReference reference;
  final VoidCallback? onTap;
  final Color? textColor;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: onTap == null ? null : '跳转到引用消息',
    child: MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: reference.senderName,
                style: TextStyle(
                  color: reference.roleId == null
                      ? textColor ?? Theme.of(context).colorScheme.primary
                      : senderNameColor(context, reference.senderName),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ': ${reference.text}'),
            ],
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ),
    ),
  );
}
