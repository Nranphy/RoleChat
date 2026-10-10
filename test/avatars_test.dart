import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/widgets/avatar_field.dart';
import 'package:rolechat/widgets/common.dart';

void main() {
  testWidgets('avatar hover reveals an edit strip inside the avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarField(name: '林间', imageData: null, onChanged: (_) {}),
        ),
      ),
    );
    expect(find.text('上传头像'), findsNothing);
    final strip = find.byType(AnimatedPositioned);
    expect(tester.widget<AnimatedPositioned>(strip).bottom, -32);
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(300, 200));
    await mouse.moveTo(tester.getCenter(find.byType(RoleAvatar)));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedPositioned>(strip).bottom, 0);
    final avatarBounds = tester.getRect(find.byType(RoleAvatar));
    expect(
      tester.getRect(find.text('编辑')).bottom,
      lessThanOrEqualTo(avatarBounds.bottom),
    );
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedPositioned>(strip).bottom, -32);
  });
  Future<String> image(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 320, 160),
          ui.Paint()..color = Colors.blue,
        );
        canvas.drawRect(
          const Rect.fromLTWH(160, 0, 160, 160),
          ui.Paint()..color = Colors.red,
        );
        final picture = recorder.endRecording();
        final bitmap = await picture.toImage(320, 160);
        final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final result = base64Encode(data!.buffer.asUint8List());
        bitmap.dispose();
        picture.dispose();
        return result;
      }))!;

  testWidgets('crop produces a square avatar and cancel does not save', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = PreviewStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(RoleChatApp(store: store));
    final original = await image(tester);
    final context = tester.element(find.byType(Scaffold));
    final bytes = base64Decode(original);
    await tester.runAsync(() => precacheImage(MemoryImage(bytes), context));
    String? cropped;
    managedDialog<String>(
      context: context,
      builder: (_) => AvatarCropDialog(bytes: bytes),
    ).then((value) => cropped = value);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('使用头像'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(cropped, isNotNull);
    final dimensions = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(base64Decode(cropped!));
      final bitmap = (await codec.getNextFrame()).image;
      final size = Size(bitmap.width.toDouble(), bitmap.height.toDouble());
      bitmap.dispose();
      codec.dispose();
      return size;
    });
    expect(dimensions, const Size(256, 256));
    String? cancelled = 'unchanged';
    managedDialog<String>(
      context: context,
      builder: (_) => AvatarCropDialog(bytes: bytes),
    ).then((value) => cancelled = value);
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(cancelled, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'role and group avatars restore with their ownership after restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = PreviewStore(preferences);
      final avatar = await image(tester);
      store.addRole(
        RoleProfile(
          id: 'uploaded',
          name: '测试角色',
          color: Colors.blue,
          avatar: avatar,
        ),
      );
      store.addGroup('测试群聊', ['uploaded'], avatar: avatar);
      expect(await store.saveProfiles(), isTrue);
      final restored = PreviewStore(preferences);
      expect(restored.role('uploaded').avatar, avatar);
      expect(
        restored.avatarFor(
          restored.conversations.firstWhere((c) => c.id == 'private-uploaded'),
        ),
        avatar,
      );
      expect(
        restored.conversations.firstWhere((c) => c.name == '测试群聊').avatar,
        avatar,
      );
      expect(
        restored.conversations
            .firstWhere((c) => c.id == 'private-uploaded')
            .messages,
        isEmpty,
      );
      restored.role('uploaded').avatar = null;
      restored.changed();
      await restored.saveProfiles();
      expect(PreviewStore(preferences).role('uploaded').avatar, isNull);
    },
  );
  testWidgets('create menu opens below its button with consistent rounding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      RoleChatApp(store: PreviewStore(await SharedPreferences.getInstance())),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('create-menu'));
    final buttonBounds = tester.getRect(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('新建角色')).top,
      greaterThanOrEqualTo(buttonBounds.bottom),
    );
    final menu = tester.widget<PopupMenuButton<String>>(
      find.byWidgetPredicate(
        (w) =>
            w is PopupMenuButton<String> &&
            w.key == const ValueKey('create-menu'),
      ),
    );
    expect(menu.position, PopupMenuPosition.under);
    expect(
      (menu.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(16),
    );
  });
}
