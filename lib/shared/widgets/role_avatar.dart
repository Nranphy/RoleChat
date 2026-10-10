import 'dart:convert';
import 'package:flutter/material.dart';
import '../../design/app_theme.dart';

class RoleAvatar extends StatelessWidget {
  const RoleAvatar(
    this.name, {
    super.key,
    this.color,
    this.size = 48,
    this.imageData,
    this.icon = Icons.person_outline,
  });
  final String name;
  final String? imageData;
  final IconData icon;
  final Color? color;
  final double size;
  static Color backgroundColor(BuildContext context, String name) =>
      name.isEmpty
      ? Theme.of(context).colorScheme.secondaryContainer
      : AppTheme.nameColors(name.characters.first).primaryContainer;

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? backgroundColor(context, name),
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(size / 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox.square(
      dimension: size,
      child: Center(
        child: imageData == null
            ? name.isNotEmpty &&
                      RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(name)
                  ? ExcludeSemantics(
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: TextStyle(
                          fontSize: size / 2.5,
                          fontWeight: FontWeight.bold,
                          color: color == null
                              ? AppTheme.nameColors(
                                  name.characters.first,
                                ).onPrimaryContainer
                              : ThemeData.estimateBrightnessForColor(color!) ==
                                    Brightness.light
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: size * .48,
                      color: color == null
                          ? (name.isEmpty
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer
                                : AppTheme.nameColors(
                                    name.characters.first,
                                  ).onPrimaryContainer)
                          : ThemeData.estimateBrightnessForColor(color!) ==
                                Brightness.light
                          ? Colors.black87
                          : Colors.white,
                    )
            : Image.memory(
                base64Decode(imageData!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => Icon(icon, size: size * .48),
              ),
      ),
    ),
  );
}
