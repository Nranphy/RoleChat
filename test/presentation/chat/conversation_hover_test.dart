import '../../fixtures/test_store.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/role_chat_app.dart';

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
        final store = createTestStore(await SharedPreferences.getInstance());
        await store.setMode(mode);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: RoleChatApp(store: store),
          ),
        );
        await tester.pumpAndSettle();
        final row = find.byKey(
          const ValueKey('77777777-7777-4777-8777-777777777777'),
        );
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
        await mouse.moveTo(Offset.zero);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        final leaving = await pixel(sample);
        expect(leaving, isNot(colors.surface.toARGB32()));
        expect(leaving, isNot(colors.surfaceContainerHigh.toARGB32()));
        await tester.pumpAndSettle();
        expect(await pixel(sample), colors.surface.toARGB32());
        await mouse.moveTo(target);
        await tester.pumpAndSettle();
        await mouse.down(target);
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
        expect(store.selectedId, '77777777-7777-4777-8777-777777777777');
        expect(await pixel(sample), colors.secondaryContainer.toARGB32());
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(await pixel(sample), colors.secondaryContainer.toARGB32());
        await mouse.removePointer();
        await tester.pumpAndSettle();
        final navigation = find.byKey(const ValueKey(1));
        final navBounds = tester.getRect(navigation);
        final navSample = Offset(navBounds.left + 4, navBounds.center.dy);
        final navMouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await navMouse.addPointer(location: Offset.zero);
        await navMouse.moveTo(navBounds.center);
        await tester.pumpAndSettle();
        expect(await pixel(navSample), colors.surfaceContainerHigh.toARGB32());
        await navMouse.down(navBounds.center);
        await navMouse.up();
        await tester.pumpAndSettle();
        expect(store.destination, 1);
        expect(await pixel(navSample), colors.secondaryContainer.toARGB32());
        await navMouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(await pixel(navSample), colors.secondaryContainer.toARGB32());
        await navMouse.removePointer();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
