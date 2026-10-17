import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/role_avatar.dart';

Color senderNameColor(BuildContext context, String name) => Color.lerp(
  RoleAvatar.backgroundColor(context, name),
  Colors.black,
  Theme.of(context).brightness == Brightness.light ? .38 : .12,
)!;
