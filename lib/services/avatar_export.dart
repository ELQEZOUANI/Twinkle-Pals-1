import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/avatar.dart';
import '../widgets/avatar_art.dart';

/// Export at a fixed resolution, independent of phone size or animation state.
Future<Uint8List> renderAvatarPng(Avatar avatar) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  AvatarPainter(avatar, true).paint(canvas, const ui.Size(900, 1200));
  final picture = recorder.endRecording();
  final image = await picture.toImage(900, 1200);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Could not render avatar image');
    return bytes.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}
