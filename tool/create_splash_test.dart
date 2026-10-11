// Reproduce native launch artwork and the Flutter splash preview:
// flutter test tool/create_splash_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/widgets/avatar_art.dart';
import 'package:pocket_pals/widgets/lovely_theme.dart';
import 'package:pocket_pals/widgets/splash_screen.dart';

void main() {
  test('Generate original native launch characters and flower', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawOval(
      const Rect.fromLTWH(15, 10, 230, 250),
      Paint()..color = blush,
    );
    for (final (character, x, y, scale) in [
      (4, -4.0, 50.0, .45),
      (8, 151.0, 50.0, .45),
      (0, 60.0, 30.0, .58),
    ]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      AvatarPainter(
        characterPreset(character),
        false,
      ).paint(canvas, const Size(240, 320));
      canvas.restore();
    }
    final paint = Paint()..color = purple;
    for (var petal = 0; petal < 6; petal++) {
      final angle = petal * math.pi / 3;
      canvas.drawCircle(
        Offset(130 + math.cos(angle) * 11, 248 + math.sin(angle) * 11),
        9,
        paint,
      );
    }
    canvas.drawCircle(const Offset(130, 248), 7, paint..color = softGold);
    final picture = recorder.endRecording();
    final outputs = <String, double>{
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': 1,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png': 2,
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': 3,
    };
    for (final entry in outputs.entries) {
      final scaled = ui.PictureRecorder();
      Canvas(scaled)
        ..scale(entry.value)
        ..drawPicture(picture);
      final render = scaled.endRecording();
      final image = await render.toImage(
        (260 * entry.value).round(),
        (280 * entry.value).round(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(entry.key)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      render.dispose();
    }
    picture.dispose();
  });

  testWidgets('Render the splash design at phone size', (tester) async {
    // Widget tests otherwise substitute Ahem for text and omit icon fonts.
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    await tester.runAsync(() async {
      for (final (family, files) in [
        ('Roboto', ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']),
        ('MaterialIcons', ['MaterialIcons-Regular.otf']),
      ]) {
        final loader = FontLoader(family);
        for (final file in files) {
          loader.addFont(
            Future.value(
              ByteData.sublistView(File('$fonts/$file').readAsBytesSync()),
            ),
          );
        }
        await loader.load();
      }
    });
    tester.view.physicalSize = const Size(368, 774);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    const key = ValueKey('splash-art');
    await tester.pumpWidget(
      MaterialApp(
        theme: lovelyTheme(),
        home: const RepaintBoundary(key: key, child: SplashScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('docs/splash-screen.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}
