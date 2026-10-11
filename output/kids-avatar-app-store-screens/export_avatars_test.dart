import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pals/models/avatar.dart';
import 'package:pocket_pals/widgets/avatar_art.dart';

void main() {
  test('Export exact original avatars for App Store artwork', () async {
    final avatars = <String, Avatar>{
      for (var i = 0; i < names.length; i++) names[i].toLowerCase(): characterPreset(i),
      'ivy-picnic': characterPreset(10).copyWith(items: {...characterPreset(10).items, 'Hair': 1, 'Hats': 4, 'Tops': 3, 'Bottoms': 0, 'Shoes': 2, 'Bags': 2, 'Pose': 1}, color: 3, eyeColor: 3),
      'luna-party': characterPreset(0).select('Dresses', 1).select('Hats', 7).select('Pose', 1).copyWith(color: 1),
      'cleo-wings': characterPreset(2).select('Bags', 5).select('Tops', 2).select('Pose', 1).copyWith(color: 2),
      'ivy-cool': characterPreset(10).select('Hair', 4).select('Glasses', 2).select('Tops', 2).copyWith(color: 2),
      'zara-pink': characterPreset(8).select('Tops', 1).select('Bottoms', 0).select('Shoes', 0).copyWith(color: 1),
    };
    for(final entry in avatars.entries) {
      final recorder = ui.PictureRecorder();
      AvatarPainter(entry.value, false).paint(Canvas(recorder), const Size(720, 960));
      final picture = recorder.endRecording();
      final image = await picture.toImage(720, 960);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('output/kids-avatar-app-store-screens/assets/avatars/${entry.key}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose(); picture.dispose();
    }
  });
}
