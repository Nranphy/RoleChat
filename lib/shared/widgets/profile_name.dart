import 'package:flutter/material.dart';

class ProfileName extends StatefulWidget {
  const ProfileName({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onCommitted,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final ValueChanged<String> onCommitted;
  @override
  State<ProfileName> createState() => _ProfileNameState();
}

class _ProfileNameState extends State<ProfileName> {
  final focus = FocusNode();
  bool editing = false;
  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (!focus.hasFocus && editing) {
        widget.controller.text = widget.controller.text.trim();
        widget.onCommitted(widget.controller.text);
        if (mounted) setState(() => editing = false);
      }
    });
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => editing
      ? TextField(
          key: const ValueKey('profile-name-input'),
          controller: widget.controller,
          focusNode: focus,
          autofocus: true,
          style: Theme.of(context).textTheme.titleLarge,
          onChanged: (_) => widget.onChanged(),
          onSubmitted: (_) => focus.unfocus(),
          onTapOutside: (_) => focus.unfocus(),
          decoration: const InputDecoration(
            hintText: '未命名',
            border: UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(),
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        )
      : InkWell(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          onTap: () => setState(() => editing = true),
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.controller.text.isEmpty ? '未命名' : widget.controller.text,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        );
}
