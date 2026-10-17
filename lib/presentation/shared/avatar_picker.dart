import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';

import 'package:rolechat/presentation/shared/widgets/avatar_crop_dialog.dart';

Future<String?> selectAvatar(BuildContext context) async {
  try {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: '图片',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
        ),
      ],
    );
    if (file == null || !context.mounted) return null;
    if (await file.length() > 10 * 1024 * 1024) {
      if (context.mounted) toast(context, '请选择不超过 10 MB 的图片');
      return null;
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted) return null;
    return await cropAvatar(context, bytes);
  } catch (_) {
    if (context.mounted) toast(context, '无法读取图片，请选择 PNG、JPEG 或 WebP 图片');
    return null;
  }
}

Future<String?> cropAvatar(BuildContext context, Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.Image? image;
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale =
        2048 /
        (descriptor.width > descriptor.height
            ? descriptor.width
            : descriptor.height);
    final codec = await descriptor.instantiateCodec(
      targetWidth: scale < 1
          ? (descriptor.width * scale).round()
          : descriptor.width,
      targetHeight: scale < 1
          ? (descriptor.height * scale).round()
          : descriptor.height,
    );
    image = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    if (!context.mounted) return null;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!context.mounted || png == null) return null;
    return await managedDialog<String>(
      context: context,
      builder: (context) => AvatarCropDialog(bytes: png.buffer.asUint8List()),
    );
  } finally {
    image?.dispose();
    buffer.dispose();
  }
}
