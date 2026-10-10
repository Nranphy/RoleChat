import 'package:flutter/material.dart';
import 'package:rolechat/design/app_theme.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.input,
    required this.reply,
    required this.onClearReply,
    required this.onEmoji,
    required this.onSend,
  });
  final TextEditingController input;
  final String? reply;
  final VoidCallback onClearReply, onEmoji, onSend;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.timelineWidth),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
          child: Column(
            children: [
              if (reply != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reply!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: onClearReply,
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
              Material(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(32),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 56,
                        child: Center(
                          child: IconButton(
                            tooltip: '表情',
                            onPressed: onEmoji,
                            color: scheme.onPrimaryContainer,
                            icon: const Icon(Icons.add_reaction_outlined),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: input,
                          minLines: 1,
                          maxLines: 8,
                          style: const TextStyle(fontSize: 16),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: '输入消息',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 16,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: IconButton.filled(
                            tooltip: '发送消息',
                            onPressed: onSend,
                            icon: const Icon(Icons.send_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
