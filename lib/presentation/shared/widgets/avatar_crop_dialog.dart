import 'package:rolechat/presentation/shared/widgets/app_dialog.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/presentation/theme/form_metrics.dart';
import 'package:rolechat/presentation/shared/widgets/common.dart';

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
  Widget build(BuildContext context) => AppDialog.content(
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
