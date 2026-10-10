import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Selectors anchor to the field bounds and scroll within the available space.
class AnchoredSelect<T> extends StatelessWidget {
  const AnchoredSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Builder(
    builder: (fieldContext) => Semantics(
      button: true,
      label: '$label：${options[value] ?? ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final field = fieldContext.findRenderObject()! as RenderBox;
          final overlay =
              Navigator.of(context).overlay!.context.findRenderObject()!
                  as RenderBox;
          final origin = field.localToGlobal(Offset.zero, ancestor: overlay);
          final bottom = origin.dy + field.size.height;
          final below = overlay.size.height - bottom - 14;
          final above = origin.dy - 14;
          final openBelow = below >= 96 || below >= above;
          final height = math.min(
            280.0,
            math.max(48.0, openBelow ? below : above),
          );
          final top = openBelow ? bottom + 6 : origin.dy - height - 6;
          final selected = await showMenu<T>(
            context: context,
            position: RelativeRect.fromLTRB(
              origin.dx,
              top,
              overlay.size.width - origin.dx - field.size.width,
              overlay.size.height - top,
            ),
            constraints: BoxConstraints(
              minWidth: field.size.width,
              maxWidth: field.size.width,
              maxHeight: height,
            ),
            items: options.entries
                .map(
                  (e) => PopupMenuItem<T>(value: e.key, child: Text(e.value)),
                )
                .toList(),
          );
          if (context.mounted && selected != null) onChanged(selected);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, isDense: true),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  options[value] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.expand_more, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
