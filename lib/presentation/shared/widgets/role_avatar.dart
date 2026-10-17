import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rolechat/presentation/theme/app_theme.dart';

class RoleAvatar extends StatefulWidget {
  const RoleAvatar(
    this.name, {
    super.key,
    this.size = 48,
    this.imageData,
    this.icon = Icons.person_outline,
  });
  final String name;
  final String? imageData;
  final IconData icon;
  final double size;
  static Color backgroundColor(BuildContext context, String name) =>
      name.isEmpty
      ? Theme.of(context).colorScheme.secondaryContainer
      : AppTheme.nameColors(name.characters.first).primaryContainer;

  @override
  State<RoleAvatar> createState() => _RoleAvatarState();
}

class _RoleAvatarState extends State<RoleAvatar> {
  MemoryImage? image;

  @override
  void initState() {
    super.initState();
    updateImage();
  }

  @override
  void didUpdateWidget(covariant RoleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData) updateImage();
  }

  void updateImage() {
    final data = widget.imageData;
    image = null;
    if (data == null || data.isEmpty) return;
    try {
      // A stable provider keeps Flutter's decoded image and stream cache intact.
      image = MemoryImage(base64Decode(data));
    } on FormatException {
      // Invalid supplied data is an image error, not a missing-avatar placeholder.
    }
  }

  Widget brokenImage() => Center(
    child: Icon(
      Icons.broken_image_outlined,
      size: widget.size * .48,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageData?.isNotEmpty ?? false;
    final name = widget.name;
    final size = widget.size;
    final icon = widget.icon;
    return Material(
      color: hasImage
          ? Colors.transparent
          : RoleAvatar.backgroundColor(context, name),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(size / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: !hasImage
              ? name.isNotEmpty &&
                        RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(name)
                    ? ExcludeSemantics(
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: TextStyle(
                            fontSize: size / 2.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nameColors(
                              name.characters.first,
                            ).onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: size * .48,
                        color: name.isEmpty
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : AppTheme.nameColors(
                                name.characters.first,
                              ).onPrimaryContainer,
                      )
              : image == null
              ? brokenImage()
              : Image(
                  image: image!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, error, stack) => brokenImage(),
                ),
        ),
      ),
    );
  }
}
