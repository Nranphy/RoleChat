import 'package:rolechat/presentation/shared/avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';

class AvatarField extends StatelessWidget {
  const AvatarField({
    super.key,
    required this.imageData,
    required this.onChanged,
    this.group = false,
    this.name = '',
    this.trailing,
  });
  final String? imageData;
  final ValueChanged<String?> onChanged;
  final bool group;
  final String name;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _AvatarButton(field: this),
      if (trailing != null) ...[
        const SizedBox(width: 16),
        Expanded(child: trailing!),
      ],
    ],
  );
}

class _AvatarButton extends StatefulWidget {
  const _AvatarButton({required this.field});
  final AvatarField field;
  @override
  State<_AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<_AvatarButton> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: Semantics(
      button: true,
      label: '编辑头像',
      child: Material(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(48),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          onTap: () async {
            final avatar = await selectAvatar(context);
            if (mounted && avatar != null) widget.field.onChanged(avatar);
          },
          child: SizedBox.square(
            dimension: 96,
            child: Stack(
              children: [
                RoleAvatar(
                  widget.field.name,
                  imageData: widget.field.imageData,
                  size: 96,
                  icon: widget.field.group
                      ? Icons.group_outlined
                      : Icons.person_outline,
                ),
                if (hovered)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: .06),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  bottom: hovered ? 0 : -32,
                  child: Container(
                    height: 32,
                    color: Colors.black54,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '编辑',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
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
