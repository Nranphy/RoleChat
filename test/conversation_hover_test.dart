import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/main.dart';

void main() {
  testWidgets(
    'selected conversation keeps its painted color while the mouse remains on it',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const boundaryKey = ValueKey('paint-root');
      Future<int> pixel(Offset point) async => (await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        final local = boundary.globalToLocal(point);
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final index = (local.dy.toInt() * image.width + local.dx.toInt()) * 4;
        final color = Color.fromARGB(
          bytes!.getUint8(index + 3),
          bytes.getUint8(index),
          bytes.getUint8(index + 1),
          bytes.getUint8(index + 2),
        ).toARGB32();
        image.dispose();
        return color;
      }))!;
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        SharedPreferences.setMockInitialValues({});
        final store = PreviewStore(await SharedPreferences.getInstance());
        await store.setMode(mode);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: RoleChatApp(store: store),
          ),
        );
        await tester.pumpAndSettle();
        final row = find.byKey(const ValueKey('moon-chat'));
        final bounds = tester.getRect(row);
        final sample = Offset(bounds.center.dx, bounds.bottom - 8);
        final colors = Theme.of(tester.element(row)).colorScheme;
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        final target = tester.getCenter(find.text('月白').first);
        await mouse.moveTo(target);
        await tester.pumpAndSettle();
        expect(await pixel(sample), colors.surfaceContainerHigh.toARGB32());
        await mouse.down(target);
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
        expect(store.selectedId, 'moon-chat');
        expect(await pixel(sample), colors.secondaryContainer.toARGB32());
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(await pixel(sample), colors.secondaryContainer.toARGB32());
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
