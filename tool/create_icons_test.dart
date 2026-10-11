// Reproducible original app icon. Run: flutter test tool/create_icons_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate original Pocket Pals platform icons', () async {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final stroke = Paint()
      ..color = const Color(0xFF302741)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void oval(Rect rect, Color color, {bool border = true}) {
      c.drawOval(rect, Paint()..color = color);
      if (border) {
        c.drawOval(rect, stroke);
      }
    }

    void shape(Path path, Color color) {
      c.drawPath(path, Paint()..color = color);
      c.drawPath(path, stroke);
    }

    c.drawRect(
      const Rect.fromLTWH(0, 0, 1024, 1024),
      Paint()..color = const Color(0xFF7653D5),
    );
    oval(
      const Rect.fromLTWH(130, 142, 764, 764),
      const Color(0xFF9572E1),
      border: false,
    );
    shape(
      Path()
        ..moveTo(233, 422)
        ..lineTo(197, 176)
        ..lineTo(397, 313)
        ..close(),
      const Color(0xFF74BCAD),
    );
    shape(
      Path()
        ..moveTo(627, 313)
        ..lineTo(827, 176)
        ..lineTo(791, 422)
        ..close(),
      const Color(0xFF74BCAD),
    );
    shape(
      Path()
        ..moveTo(255, 335)
        ..lineTo(242, 243)
        ..lineTo(322, 306)
        ..close(),
      const Color(0xFFF58CA8),
    );
    shape(
      Path()
        ..moveTo(702, 306)
        ..lineTo(782, 243)
        ..lineTo(769, 335)
        ..close(),
      const Color(0xFFF58CA8),
    );
    oval(const Rect.fromLTWH(205, 305, 614, 563), const Color(0xFFFBE0CB));
    final fringe = Path()
      ..moveTo(208, 486)
      ..cubicTo(180, 230, 791, 196, 815, 486)
      ..quadraticBezierTo(716, 442, 674, 338)
      ..quadraticBezierTo(586, 491, 433, 448)
      ..quadraticBezierTo(474, 396, 450, 343)
      ..quadraticBezierTo(320, 492, 208, 486)
      ..close();
    shape(fringe, const Color(0xFF9770E8));
    for (final x in [310.0, 590.0]) {
      oval(Rect.fromLTWH(x, 487, 125, 169), Colors.white);
      oval(
        Rect.fromLTWH(x + 29, 516, 83, 125),
        const Color(0xFF302741),
        border: false,
      );
      oval(Rect.fromLTWH(x + 35, 523, 32, 43), Colors.white, border: false);
      oval(Rect.fromLTWH(x + 82, 601, 14, 18), Colors.white, border: false);
    }
    oval(
      const Rect.fromLTWH(267, 660, 98, 46),
      const Color(0xFFF58CA8),
      border: false,
    );
    oval(
      const Rect.fromLTWH(659, 660, 98, 46),
      const Color(0xFFF58CA8),
      border: false,
    );
    c.drawPath(
      Path()
        ..moveTo(462, 718)
        ..quadraticBezierTo(512, 774, 562, 718),
      stroke,
    );
    final picture = recorder.endRecording();
    final outputs = <String, int>{'assets/branding/icon.png': 1024};
    final dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents =
        jsonDecode(File('$dir/Contents.json').readAsStringSync()) as Map;
    for (final spec in contents['images'] as List) {
      outputs['$dir/${spec['filename']}'] =
          (double.parse((spec['size'] as String).split('x').first) *
                  double.parse((spec['scale'] as String).replaceAll('x', '')))
              .round();
    }
    for (final output in outputs.entries) {
      final scaledRecorder = ui.PictureRecorder();
      Canvas(scaledRecorder)
        ..scale(output.value / 1024)
        ..drawPicture(picture);
      final scaled = scaledRecorder.endRecording();
      final image = await scaled.toImage(output.value, output.value);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(output.key)..parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      scaled.dispose();
    }
    picture.dispose();
  });
}
