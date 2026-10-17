import 'package:flutter/material.dart';

/// Paint feedback inside the decorator's outline, excluding its floating label.
class FieldAction extends StatefulWidget {
  const FieldAction({
    super.key,
    required this.decoration,
    required this.child,
    required this.onTap,
  });
  final InputDecoration decoration;
  final Widget child;
  final VoidCallback onTap;
  @override
  State<FieldAction> createState() => _FieldActionState();
}

class _FieldActionState extends State<FieldAction> {
  bool hovered = false;
  bool focused = false;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: widget.onTap,
    onHover: (v) => setState(() => hovered = v),
    onFocusChange: (v) => setState(() => focused = v),
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    borderRadius: BorderRadius.circular(9),
    child: InputDecorator(
      decoration: widget.decoration.copyWith(
        filled: true,
        fillColor: hovered || focused
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.transparent,
      ),
      child: widget.child,
    ),
  );
}
