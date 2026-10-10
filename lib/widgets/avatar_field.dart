import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../design/form_metrics.dart';
import 'common.dart';

class AvatarField extends StatelessWidget {
  const AvatarField({
    super.key,
    required this.imageData,
    required this.onChanged,
    this.group = false,
    this.name = '',
    this.color,
    this.trailing,
  });
  final String? imageData;
  final ValueChanged<String?> onChanged;
  final bool group;
  final String name;
  final Color? color;
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
    child: Tooltip(
      message: '编辑头像',
      child: Semantics(
        button: true,
        label: '编辑头像',
        child: Material(
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(48),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
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
                    color: widget.field.color,
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
    ),
  );
}

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

class AvatarCropDialog extends StatefulWidget {
  const AvatarCropDialog({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  final controller = CropController(
    aspectRatio: 1,
    defaultCrop: const Rect.fromLTWH(.1, .1, .8, .8),
  );
  bool saving = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('裁剪头像'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('拖动裁剪区域或边角，选择需要保留的部分。', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: math.min(
              440.0,
              math.max(
                120.0,
                math.min(
                  MediaQuery.sizeOf(context).width - 144,
                  MediaQuery.sizeOf(context).height - 270,
                ),
              ),
            ),
            height: math.min(
              440.0,
              math.max(
                120.0,
                math.min(
                  MediaQuery.sizeOf(context).width - 144,
                  MediaQuery.sizeOf(context).height - 270,
                ),
              ),
            ),
            child: CropImage(
              controller: controller,
              image: Image.memory(widget.bytes),
              paddingSize: 12,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        style: FormMetrics.dialogActionStyle,
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        style: FormMetrics.dialogActionStyle,
        onPressed: saving ? null : save,
        child: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('使用头像'),
      ),
    ],
  );
  Future<void> save() async {
    setState(() => saving = true);
    try {
      final cropped = await controller.croppedBitmap();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        cropped,
        Rect.fromLTWH(
          0,
          0,
          cropped.width.toDouble(),
          cropped.height.toDouble(),
        ),
        const Rect.fromLTWH(0, 0, 256, 256),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final scaled = await picture.toImage(256, 256);
      final data = await scaled.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      scaled.dispose();
      picture.dispose();
      if (!mounted) return;
      if (data == null) throw StateError('Image encoding failed');
      Navigator.pop(context, base64Encode(data.buffer.asUint8List()));
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        toast(context, '裁剪失败，请重新选择图片');
      }
    }
  }
}
