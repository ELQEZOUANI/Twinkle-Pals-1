import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/avatar.dart';

/// Original vector artwork: every accessory uses the same 240 × 320 canvas.
/// No downloaded illustrations or network assets are needed.
class AvatarArt extends StatefulWidget {
  final Avatar avatar;
  final bool scene;
  final bool animate;
  final bool interactive;
  const AvatarArt({
    super.key,
    required this.avatar,
    this.scene = true,
    this.animate = true,
    this.interactive = false,
  });

  @override
  State<AvatarArt> createState() => _AvatarArtState();
}

class _AvatarArtState extends State<AvatarArt>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  );
  late final reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );
  late final motion = Listenable.merge([idle, reaction]);
  bool motionAllowed = false;
  bool waving = false;
  bool foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void syncMotion() {
    motionAllowed =
        widget.animate &&
        foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (motionAllowed) {
      if (!idle.isAnimating) idle.repeat();
    } else {
      idle.stop();
      reaction.stop();
      reaction.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(covariant AvatarArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
    if (oldWidget.avatar != widget.avatar && motionAllowed) {
      waving = false;
      reaction.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (mounted) setState(syncMotion);
  }

  void wave() {
    if (!motionAllowed) return;
    waving = true;
    reaction.forward(from: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    idle.dispose();
    reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${widget.avatar.name}, customized character${widget.interactive && motionAllowed ? ', tap to wave' : ''}',
    image: true,
    child: GestureDetector(
      onTap: widget.interactive && motionAllowed ? wave : null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, _) => CustomPaint(
            painter: AvatarPainter(
              widget.avatar,
              widget.scene,
              motion: motionAllowed
                  ? AvatarMotion(
                      time: idle.value * 6.2 + widget.avatar.character * .31,
                      reaction: reaction.value,
                      wave: waving,
                      enabled: true,
                    )
                  : const AvatarMotion(),
            ),
            size: const Size(240, 320),
          ),
        ),
      ),
    ),
  );
}

/// Animation never changes the saved outfit or still picture export.
class AvatarMotion {
  final double time, reaction;
  final bool wave, enabled;
  const AvatarMotion({
    this.time = 0,
    this.reaction = 1,
    this.wave = false,
    this.enabled = false,
  });

  double get cycle => time * math.pi * 2 / 3.1;
  double get energy => enabled ? math.sin(reaction * math.pi) : 0;
  double get jump => energy * math.sin(reaction * math.pi * 3).abs() * 12;
  double get blink =>
      enabled ? (1 - ((time % 4.7) - 4.52).abs() / .11).clamp(0.0, 1.0) : 0;
}

class AvatarPainter extends CustomPainter {
  final Avatar a;
  final bool scene;
  final AvatarMotion motion;
  AvatarPainter(this.a, this.scene, {this.motion = const AvatarMotion()});
  late Canvas c;
  final outline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  void oval(
    double x,
    double y,
    double w,
    double h,
    Color color, [
    bool border = true,
  ]) {
    final r = Rect.fromLTWH(x, y, w, h);
    c.drawOval(r, Paint()..color = color);
    if (border) c.drawOval(r, outline);
  }

  void box(
    double x,
    double y,
    double w,
    double h,
    Color color, [
    double radius = 8,
  ]) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      Radius.circular(radius),
    );
    c.drawRRect(r, Paint()..color = color);
    c.drawRRect(r, outline);
  }

  void path(List<Offset> points, Color color) {
    final p = Path()..addPolygon(points, true);
    c.drawPath(p, Paint()..color = color);
    c.drawPath(p, outline);
  }

  void line(
    double x1,
    double y1,
    double x2,
    double y2, [
    Color? color,
    double width = 2.8,
  ]) {
    c.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = color ?? ink
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void star(
    double x,
    double y,
    double size,
    Color color, [
    bool border = false,
  ]) {
    final p = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? size : size * .45;
      final point = Offset(
        x + math.cos(angle) * radius,
        y + math.sin(angle) * radius,
      );
      if (i == 0) {
        p.moveTo(point.dx, point.dy);
      } else {
        p.lineTo(point.dx, point.dy);
      }
    }
    p.close();
    c.drawPath(p, Paint()..color = color);
    if (border) c.drawPath(p, outline);
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    c.save();
    c.scale(size.width / 240, size.height / 320);
    if (scene) drawScene();
    oval(70, 291, 102, 13, ink.withValues(alpha: .10), false);
    c.save();
    if (motion.enabled) {
      final dance = a.item('Pose') == 2;
      c.translate(120, 293);
      c.translate(
        0,
        -math.sin(motion.cycle).abs() * (dance ? 5 : 2) - motion.jump,
      );
      c.rotate(math.sin(motion.cycle) * (dance ? .045 : .014));
      // Breathing is anchored at the feet; the background stays still.
      c.scale(1, 1 + math.sin(motion.cycle) * .008);
      c.translate(-120, -293);
    }
    if (a.item('Pose') == 2) {
      c.translate(120, 175);
      c.rotate(-.085);
      c.translate(-120, -175);
    }
    drawCharacter();
    c.restore();
    c.restore();
  }

  void drawScene() {
    const colors = [
      Color(0xFFFCE5DA),
      Color(0xFFE9E1FA),
      Color(0xFFDEF0D7),
      Color(0xFFFFEDBC),
      Color(0xFF353757),
      Color(0xFFF9DFEE),
    ];
    final sceneIndex = a.item('Scene');
    c.drawRect(
      const Rect.fromLTWH(0, 0, 240, 320),
      Paint()..color = colors[sceneIndex],
    );
    if (sceneIndex == 4) {
      for (int i = 0; i < 23; i++) {
        star(
          (i * 61 % 230).toDouble(),
          (i * 43 % 280).toDouble(),
          i % 3 + 2,
          Colors.white70,
        );
      }
      oval(177, 35, 32, 32, const Color(0xFFFCEAA3), false);
    } else {
      oval(-35, 210, 310, 180, Colors.white.withValues(alpha: .28), false);
      for (final p in [
        const Offset(36, 73),
        const Offset(202, 148),
        const Offset(37, 219),
      ]) {
        star(p.dx, p.dy, 8, Colors.white.withValues(alpha: .8));
      }
      if (sceneIndex == 2) {
        for (final x in [23.0, 212.0]) {
          line(x, 286, x, 260, const Color(0xFF72A576));
          for (int i = 0; i < 5; i++) {
            oval(
              x - 5 + math.cos(i * 1.25) * 7,
              252 + math.sin(i * 1.25) * 7,
              10,
              10,
              const Color(0xFFF1A7BC),
              false,
            );
          }
          oval(x - 3, 256, 7, 7, const Color(0xFFFFD975), false);
        }
      }
      if (sceneIndex == 3) {
        oval(182, 22, 34, 34, const Color(0xFFFFD569), false);
        c.drawRect(
          const Rect.fromLTWH(0, 237, 240, 35),
          Paint()..color = const Color(0xFF9DDAD7),
        );
        for (int i = 0; i < 5; i++) {
          line(i * 50, 250, i * 50 + 24, 250, Colors.white60, 2);
        }
      }
      if (sceneIndex == 5) {
        for (final p in [const Offset(27, 45), const Offset(197, 205)]) {
          oval(p.dx - 12, p.dy, 36, 15, Colors.white70, false);
          oval(p.dx, p.dy - 9, 21, 23, Colors.white70, false);
        }
      }
    }
  }

  void drawCharacter() {
    final skin = skinColors[a.skin];
    final hair = hairColors[a.hairColor];
    final color = palette[a.color];
    final hairstyle = a.item('Hair');
    final dress = a.item('Dresses');
    final top = dress > 0 ? 0 : a.item('Tops');
    final bottom = dress > 0 ? 0 : a.item('Bottoms');
    if (a.item('Bags') == 5) drawFlowerWings();
    if ([0, 1, 6].contains(hairstyle)) {
      box(57, 65, 125, hairstyle == 1 ? 156 : 122, hair, 47);
    }
    if (hairstyle == 2 || hairstyle == 4) {
      oval(37, 63, 54, 54, hair);
      oval(151, 63, 54, 54, hair);
      if (hairstyle == 2) {
        for (int i = 0; i < 7; i++) {
          oval(
            42 + math.cos(i * .9) * 10,
            71 + math.sin(i * .9) * 12,
            29,
            29,
            hair,
          );
          oval(
            160 + math.cos(i * .9) * 10,
            71 + math.sin(i * .9) * 12,
            29,
            29,
            hair,
          );
        }
      }
    }
    if (hairstyle == 6) {
      oval(163, 101, 31, 94, hair);
      box(164, 110, 28, 8, color, 4);
    }
    box(91, 243, 20, 43, skin, 9);
    box(128, 243, 20, 43, skin, 9);
    final shoe = a.item('Shoes');
    for (final x in [84.0, 124.0]) {
      if (shoe == 4) {
        const leather = Color(0xFFD0A77E);
        const gold = Color(0xFFC19B51);
        box(x + 3, 262, 27, 27, leather, 6);
        box(x, 280, 35, 16, leather, 6);
        line(x + 3, 294, x + 32, 294, const Color(0xFF76574A), 4);
        line(x + 5, 264, x + 28, 264, const Color(0xFFFFF1D9), 5);
        for (final y in [270.0, 275.0, 280.0]) {
          line(x + 10, y, x + 23, y + 3, const Color(0xFFFFFAEE), 2);
          line(x + 10, y + 3, x + 23, y, const Color(0xFFFFFAEE), 2);
        }
        star(x + 29, 271, 4, gold, true);
        for (final dx in [7.0, 16.0, 25.0]) {
          line(x + dx, 295, x + dx, 298, const Color(0xFF76574A), 2);
        }
        continue;
      }
      if (shoe == 2) {
        oval(x + 3, 277, 28, 17, skin);
        line(x + 2, 293, x + 31, 293, color, 5);
        line(x + 6, 284, x + 17, 290, color, 4);
        line(x + 28, 284, x + 17, 290, color, 4);
        continue;
      }
      if (shoe == 1 || shoe == 3) {
        box(x + 3, 266, 27, 23, shoe == 1 ? const Color(0xFF85665A) : color, 5);
      }
      box(x, 279, 34, 16, shoe == 2 ? const Color(0xFFF2BA62) : color, 7);
      line(x + 3, 292, x + 30, 292, const Color(0xFFFFF8EE), 4);
      if (shoe == 0 || shoe == 3) {
        line(x + 10, 282, x + 21, 282, Colors.white, 2);
        line(x + 10, 286, x + 21, 286, Colors.white, 2);
      }
      if (shoe == 1) box(x + 8, 268, 14, 5, const Color(0xFFFFD577), 2);
    }
    drawArms(skin);
    final dark = Color.lerp(color, ink, .30)!;
    if (bottom == 2) {
      path([
        const Offset(91, 228),
        const Offset(148, 228),
        const Offset(164, 257),
        const Offset(76, 257),
      ], dark);
      for (final x in [95.0, 113.0, 134.0]) {
        line(x, 235, x - 3, 253, color, 2);
      }
    } else if (bottom != 3) {
      box(88, 225, 28, bottom == 0 ? 31 : 49, dark, 5);
      box(123, 225, 28, bottom == 0 ? 31 : 49, dark, 5);
    }
    if (bottom == 1) {
      line(95, 240, 95, 270, color, 2);
      line(144, 240, 144, 270, color, 2);
      line(90, 270, 113, 270, ink, 2);
      line(125, 270, 148, 270, ink, 2);
    }
    if (bottom == 3) {
      path([
        const Offset(88, 230),
        const Offset(116, 230),
        const Offset(111, 277),
        const Offset(93, 277),
      ], dark);
      path([
        const Offset(123, 230),
        const Offset(151, 230),
        const Offset(146, 277),
        const Offset(128, 277),
      ], dark);
      for (final x in [103.0, 138.0]) {
        star(x, 251, 4, color);
        star(x, 264, 3, Colors.white70);
      }
    }
    box(108, 177, 24, 25, skin, 8);
    path([
      const Offset(101, 190),
      const Offset(83, 195),
      const Offset(75, 214),
      const Offset(89, 221),
      const Offset(91, 239),
      const Offset(149, 239),
      const Offset(151, 221),
      const Offset(164, 214),
      const Offset(155, 195),
      const Offset(139, 190),
    ], color);
    final collar = Path()
      ..moveTo(105, 192)
      ..quadraticBezierTo(120, 211, 135, 192);
    c.drawPath(collar, outline);
    if (top == 1) {
      box(98, 207, 43, 34, const Color(0xFF759DBD), 4);
      line(101, 195, 102, 218, const Color(0xFF759DBD), 7);
      line(138, 195, 138, 218, const Color(0xFF759DBD), 7);
      box(109, 219, 20, 12, const Color(0xFFAAC7DD), 3);
      oval(98, 207, 5, 5, const Color(0xFFFFD577), false);
      oval(136, 207, 5, 5, const Color(0xFFFFD577), false);
    }
    if (top == 2) {
      final hood = Path()
        ..moveTo(96, 196)
        ..quadraticBezierTo(120, 219, 145, 196);
      c.drawPath(
        hood,
        Paint()
          ..color = Color.lerp(color, ink, .2)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      line(111, 205, 110, 218, Colors.white70, 2);
      line(130, 205, 131, 218, Colors.white70, 2);
      final pocket = Path()
        ..moveTo(105, 227)
        ..quadraticBezierTo(120, 220, 135, 227)
        ..lineTo(135, 235)
        ..lineTo(105, 235)
        ..close();
      c.drawPath(pocket, outline);
    }
    if (top == 3) {
      for (final y in [213.0, 224.0, 234.0]) {
        line(94, y, 146, y, const Color(0xFFFFF7EE), 4);
      }
    }
    if (top == 4) {
      path([
        const Offset(108, 195),
        const Offset(120, 207),
        const Offset(109, 225),
        const Offset(102, 198),
      ], Colors.white70);
      path([
        const Offset(133, 195),
        const Offset(120, 207),
        const Offset(130, 225),
        const Offset(139, 198),
      ], Colors.white70);
      line(120, 207, 120, 238);
    }
    if (top == 5) star(120, 220, 12, const Color(0xFFFFE296), true);
    if (top == 6) {
      line(93, 234, 146, 234, dark, 3);
      line(90, 206, 97, 202, dark);
      line(145, 202, 151, 206, dark);
      for (final x in [101.0, 113.0, 126.0, 138.0]) {
        line(x, 211, x, 229, dark.withValues(alpha: .4), 1.5);
      }
    }
    if ([2, 4, 6].contains(top) || dress == 3) drawArms(color, sleeves: true);
    if (dress > 0) {
      final hem = dress == 3 || dress == 4 ? 268.0 : 262.0;
      path([
        const Offset(101, 191),
        const Offset(84, 198),
        const Offset(76, 213),
        const Offset(91, 220),
        const Offset(96, 231),
        Offset(dress == 3 ? 87 : 71, hem),
        Offset(dress == 3 ? 153 : 169, hem),
        const Offset(144, 231),
        const Offset(149, 220),
        const Offset(164, 213),
        const Offset(155, 198),
        const Offset(139, 191),
      ], dress == 4 ? Color.lerp(color, const Color(0xFFFFF0E9), .45)! : color);
      c.drawPath(
        Path()
          ..moveTo(104, 193)
          ..quadraticBezierTo(120, 210, 136, 193),
        outline,
      );
      line(97, 230, 143, 230, const Color(0xFFFFF8EE), 5);
      if (dress == 1) {
        path([
          const Offset(119, 230),
          const Offset(107, 223),
          const Offset(107, 239),
        ], const Color(0xFFFFE296));
        path([
          const Offset(121, 230),
          const Offset(133, 223),
          const Offset(133, 239),
        ], const Color(0xFFFFE296));
        for (final x in [91.0, 120.0, 149.0]) {
          star(x, 250, 5, const Color(0xFFFFE296));
        }
      } else if (dress == 2) {
        for (final p in [
          const Offset(105, 218),
          const Offset(104, 248),
          const Offset(136, 247),
        ]) {
          for (int i = 0; i < 5; i++) {
            oval(
              p.dx - 2 + math.cos(i * 1.26) * 4,
              p.dy - 2 + math.sin(i * 1.26) * 4,
              5,
              5,
              Colors.white,
              false,
            );
          }
          oval(p.dx - 2, p.dy - 2, 4, 4, const Color(0xFFF1B84B), false);
        }
      } else if (dress == 4) {
        const gold = Color(0xFFC7A464);
        // Overlapping tulle scallops and a pearl collar make this an earned
        // costume, distinct from the existing party dress in every color.
        final tulle = Path()
          ..moveTo(88, 245)
          ..quadraticBezierTo(103, 258, 119, 248)
          ..quadraticBezierTo(137, 258, 153, 245)
          ..lineTo(167, 266)
          ..lineTo(73, 266)
          ..close();
        c.drawPath(
          tulle,
          Paint()..color = const Color(0xFFFFFAF0).withValues(alpha: .52),
        );
        c.drawPath(
          Path()
            ..moveTo(76, 263)
            ..quadraticBezierTo(120, 275, 164, 263),
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        for (final p in [
          const Offset(103, 241),
          const Offset(136, 241),
          const Offset(91, 257),
          const Offset(121, 260),
          const Offset(149, 257),
        ]) {
          star(p.dx, p.dy, 4, gold);
        }
        for (int i = 0; i < 7; i++) {
          final x = 104 + i * 5.3;
          oval(
            x - 2,
            197 + math.sin(i * math.pi / 6) * 6,
            4,
            4,
            const Color(0xFFFFFBED),
            false,
          );
        }
        star(120, 218, 9, gold, true);
        star(120, 218, 4, const Color(0xFFFFF8DD));
        box(114, 226, 12, 7, gold, 3);
      } else {
        for (final y in [215.0, 242.0, 253.0]) {
          oval(118, y, 4, 4, Colors.white, false);
        }
        line(92, 263, 148, 263, dark, 3);
      }
    }
    oval(55, 128, 20, 27, skin);
    oval(165, 128, 20, 27, skin);
    oval(65, 68, 110, 119, skin);
    var fringe = Path()
      ..moveTo(65, 116)
      ..cubicTo(51, 67, 80, 47, 120, 51)
      ..cubicTo(158, 46, 185, 78, 174, 121)
      ..quadraticBezierTo(158, 108, 146, 82)
      ..quadraticBezierTo(131, 113, 108, 109)
      ..quadraticBezierTo(118, 92, 112, 80)
      ..quadraticBezierTo(84, 116, 65, 116)
      ..close();
    if (hairstyle == 3) {
      fringe = Path()
        ..moveTo(65, 107)
        ..cubicTo(57, 62, 89, 48, 123, 51)
        ..cubicTo(161, 48, 182, 79, 174, 113)
        ..lineTo(159, 93)
        ..lineTo(149, 108)
        ..lineTo(136, 88)
        ..lineTo(113, 103)
        ..lineTo(119, 80)
        ..quadraticBezierTo(88, 104, 65, 107)
        ..close();
    }
    c.drawPath(fringe, Paint()..color = hair);
    c.drawPath(fringe, outline);
    if (hairstyle == 3) {
      line(72, 99, 99, 70, Color.lerp(hair, Colors.white, .25), 4);
    }
    if (hairstyle == 5) {
      for (int i = 0; i < 7; i++) {
        oval(62 + i * 13, 56 + (i.isEven ? 0 : -5), 29, 32, hair);
      }
    }
    if (hairstyle == 7) {
      path([
        const Offset(73, 80),
        const Offset(71, 46),
        const Offset(101, 58),
        const Offset(114, 30),
        const Offset(134, 56),
        const Offset(158, 39),
        const Offset(168, 80),
      ], hair);
    }
    if (hairstyle == 1) {
      final p = Path()
        ..moveTo(71, 109)
        ..quadraticBezierTo(51, 146, 73, 173)
        ..quadraticBezierTo(61, 190, 79, 199)
        ..lineTo(85, 172)
        ..quadraticBezierTo(73, 147, 82, 114);
      c.drawPath(p, Paint()..color = hair);
      c.drawPath(p, outline);
      final q = Path()
        ..moveTo(165, 111)
        ..quadraticBezierTo(187, 139, 167, 165)
        ..quadraticBezierTo(189, 186, 163, 204)
        ..lineTo(157, 174)
        ..quadraticBezierTo(169, 142, 155, 111);
      c.drawPath(q, Paint()..color = hair);
      c.drawPath(q, outline);
    }
    final face = a.item('Face');
    final eyes = a.item('Eyes');
    final eyeColor = palette[a.eyeColor];
    for (final x in [84.0, 134.0]) {
      c.save();
      if ((face == 1 && x > 100) ||
          face == 3 ||
          eyes == 3 ||
          motion.blink > .85) {
        final p = Path()
          ..moveTo(x, 139)
          ..quadraticBezierTo(
            x + 12,
            face == 3 || eyes == 3 ? 151 : 127,
            x + 24,
            139,
          );
        c.drawPath(p, outline);
      } else {
        c.translate(x + 12, 137);
        c.scale(1, 1 - motion.blink * .95);
        c.translate(-x - 12, -137);
        final almond = eyes == 1;
        oval(x, almond ? 128 : 121, 24, almond ? 23 : 32, Colors.white);
        oval(
          x + 5,
          almond ? 130 : 125,
          17,
          almond ? 18 : 26,
          Color.lerp(eyeColor, ink, .18)!,
          false,
        );
        oval(x + 9, almond ? 132 : 130, 9, almond ? 14 : 17, ink, false);
        if (eyes == 2) {
          star(x + 12, 135, 7, const Color(0xFFFFF5C9));
          oval(x + 18, 146, 3, 4, Colors.white, false);
        } else {
          oval(x + 8, almond ? 131 : 128, 6, 8, Colors.white, false);
          oval(x + 16, 141, 3, 4, Colors.white, false);
        }
        line(x - 1, almond ? 129 : 122, x + 3, almond ? 133 : 126, ink, 2);
      }
      c.restore();
    }
    oval(77, 151, 18, 9, const Color(0xFFEE8E9E).withValues(alpha: .65), false);
    oval(
      148,
      151,
      18,
      9,
      const Color(0xFFEE8E9E).withValues(alpha: .65),
      false,
    );
    final mouthStyle = a.item('Mouth');
    if ((mouthStyle == 0 && face == 2) || mouthStyle == 3) {
      oval(113, 157, 14, 15, ink, false);
      oval(116, 164, 8, 5, const Color(0xFFF58CA8), false);
    } else if (mouthStyle == 1) {
      final smile = Path()
        ..moveTo(109, 158)
        ..lineTo(131, 158)
        ..quadraticBezierTo(120, 179, 109, 158)
        ..close();
      c.drawPath(smile, Paint()..color = ink);
      line(112, 160, 128, 160, Colors.white, 3);
      oval(116, 166, 9, 4, const Color(0xFFF58CA8), false);
    } else {
      final mouth = Path()
        ..moveTo(mouthStyle == 2 ? 117 : 113, 161)
        ..quadraticBezierTo(
          120,
          mouthStyle == 2 ? 164 : 170,
          mouthStyle == 2 ? 123 : 127,
          161,
        );
      c.drawPath(mouth, outline);
    }
    final earring = a.item('Earrings');
    for (final x in [64.0, 177.0]) {
      if (earring == 1) oval(x - 3, 153, 6, 6, const Color(0xFFFFD577));
      if (earring == 2) {
        c.drawOval(
          Rect.fromLTWH(x - 5, 151, 10, 14),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xFFE9AE4B),
        );
      }
      if (earring == 3) star(x, 159, 7, const Color(0xFFFFD577), true);
    }
    drawGlasses();
    drawHat(color);
    drawBag(color);
  }

  void drawArms(Color color, {bool sleeves = false}) {
    final pose = a.item('Pose');
    for (final left in [true, false]) {
      final shoulder = Offset(left ? 87 : 152, pose == 1 ? 204 : 206);
      var angle = motion.enabled ? math.sin(motion.cycle) * .035 : 0.0;
      if (motion.enabled && left && motion.wave && motion.reaction < 1) {
        final raise = (math.sin(motion.reaction * math.pi) * 3).clamp(0.0, 1.0);
        angle +=
            raise *
            ((pose == 1 ? 0 : 2.15) +
                math.sin(motion.reaction * math.pi * 6) * .25);
      } else if (motion.enabled) {
        angle += motion.energy * (left ? .18 : -.18);
      }
      c.save();
      c.translate(shoulder.dx, shoulder.dy);
      c.rotate(left ? angle : -angle);
      c.translate(-shoulder.dx, -shoulder.dy);
      if (sleeves) {
        if (pose == 1) {
          line(left ? 86 : 152, 205, left ? 70 : 170, 184, color, 15);
        } else {
          line(
            left ? 84 : 155,
            207,
            left ? 75 : 164,
            left ? 234 : (pose == 2 ? 217 : 236),
            color,
            15,
          );
        }
      } else if (pose == 1) {
        line(left ? 87 : 151, 204, left ? 63 : 177, 178, color, 15);
        oval(left ? 53 : 170, 168, 18, 18, color);
      } else {
        line(
          left ? 86 : 152,
          206,
          left ? 73 : 167,
          left ? 243 : (pose == 2 ? 219 : 244),
          color,
          15,
        );
        oval(
          left ? 64 : 158,
          left ? 235 : (pose == 2 ? 211 : 237),
          19,
          19,
          color,
        );
      }
      c.restore();
    }
  }

  void drawFlowerWings() {
    const gold = Color(0xFFC6A266);
    for (final left in [true, false]) {
      c.save();
      if (!left) {
        c.translate(240, 0);
        c.scale(-1, 1);
      }
      final flutter = motion.enabled ? math.sin(motion.cycle * 2) * .045 : 0.0;
      c.translate(94, 216);
      c.rotate(flutter);
      c.translate(-94, -216);
      final upper = Path()
        ..moveTo(102, 213)
        ..cubicTo(71, 168, 43, 138, 30, 160)
        ..cubicTo(20, 180, 40, 207, 102, 224)
        ..close();
      c.drawPath(
        upper,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF5DE), Color(0xFFF0BDCF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(27, 150, 75, 76)),
      );
      c.drawPath(upper, outline);
      final lower = Path()
        ..moveTo(98, 216)
        ..cubicTo(48, 190, 33, 213, 49, 236)
        ..cubicTo(65, 257, 84, 240, 103, 222)
        ..close();
      c.drawPath(lower, Paint()..color = const Color(0xFFE9DDEF));
      c.drawPath(lower, outline);
      for (final p in [
        const Offset(37, 165),
        const Offset(54, 174),
        const Offset(54, 222),
      ]) {
        final vein = Path()
          ..moveTo(97, 218)
          ..quadraticBezierTo(64, 203, p.dx, p.dy);
        c.drawPath(
          vein,
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      oval(40, 169, 5, 5, const Color(0xFFFFFEF0), false);
      oval(53, 179, 4, 4, const Color(0xFFFFFEF0), false);
      star(64, 231, 5, const Color(0xFFFFF8DA));
      c.restore();
    }
  }

  void drawGlasses() {
    final g = a.item('Glasses');
    if (g == 0) return;
    line(112, 135, 128, 135, ink, 3);
    line(69, 132, 79, 134);
    line(161, 134, 173, 132);
    if (g == 3) {
      for (final x in [94.0, 145.0]) {
        final p = Path()
          ..moveTo(x, 151)
          ..cubicTo(x - 28, 133, x - 10, 116, x, 129)
          ..cubicTo(x + 10, 116, x + 28, 133, x, 151)
          ..close();
        c.drawPath(
          p,
          Paint()..color = const Color(0xFFF58CA8).withValues(alpha: .22),
        );
        c.drawPath(
          p,
          Paint()
            ..color = const Color(0xFFD46091)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    } else {
      for (final x in [78.0, 128.0]) {
        oval(
          x,
          119,
          34,
          34,
          g == 2
              ? const Color(0xFF49465E)
              : Colors.white.withValues(alpha: .13),
        );
        if (g == 2) line(x + 8, 128, x + 18, 124, Colors.white54, 3);
      }
    }
  }

  void drawHat(Color color) {
    final hat = a.item('Hats');
    if (hat == 1) {
      final p = Path()
        ..moveTo(60, 86)
        ..cubicTo(57, 19, 183, 19, 180, 86)
        ..close();
      c.drawPath(p, Paint()..color = color);
      c.drawPath(p, outline);
      box(58, 76, 123, 20, color, 7);
      oval(109, 26, 22, 22, Colors.white);
      for (final x in [75.0, 94.0, 113.0, 132.0, 151.0, 166.0]) {
        line(x, 80, x, 91, Colors.white38, 2);
      }
    }
    if (hat == 2) {
      path([
        const Offset(67, 69),
        const Offset(59, 29),
        const Offset(94, 52),
      ], color);
      path([
        const Offset(145, 51),
        const Offset(182, 29),
        const Offset(175, 71),
      ], color);
      path([
        const Offset(70, 56),
        const Offset(68, 41),
        const Offset(83, 52),
      ], const Color(0xFFFAB8C5));
      path([
        const Offset(158, 52),
        const Offset(172, 41),
        const Offset(170, 57),
      ], const Color(0xFFFAB8C5));
    }
    if (hat == 3) {
      final p = Path()
        ..moveTo(62, 82)
        ..cubicTo(62, 23, 176, 23, 176, 82)
        ..close();
      c.drawPath(p, Paint()..color = color);
      c.drawPath(p, outline);
      oval(102, 71, 90, 18, color);
      box(108, 48, 23, 20, Colors.white, 5);
      star(120, 58, 6, color);
    }
    if (hat == 4) {
      final p = Path()
        ..moveTo(63, 79)
        ..quadraticBezierTo(120, 43, 177, 79);
      c.drawPath(
        p,
        Paint()
          ..color = const Color(0xFF74BCAD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
      for (final x in [77.0, 103.0, 130.0, 156.0]) {
        final y = (x == 77 || x == 156) ? 69.0 : 59.0;
        for (int i = 0; i < 5; i++) {
          oval(
            x - 5 + math.cos(i * 1.26) * 6,
            y - 5 + math.sin(i * 1.26) * 6,
            10,
            10,
            i.isEven ? Colors.white : const Color(0xFFF58CA8),
            false,
          );
        }
        oval(x - 3, y - 3, 6, 6, const Color(0xFFFFD577), false);
      }
    }
    if (hat == 5) {
      oval(43, 37, 154, 161, const Color(0xFFCFEEF8).withValues(alpha: .18));
      box(39, 120, 18, 34, const Color(0xFFFFBD69));
      box(185, 120, 18, 34, const Color(0xFFFFBD69));
      box(89, 185, 64, 12, Colors.white, 5);
      final shine = Path()
        ..moveTo(63, 91)
        ..quadraticBezierTo(68, 61, 91, 57);
      c.drawPath(
        shine,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
    if (hat == 6) {
      path([
        const Offset(83, 66),
        const Offset(76, 33),
        const Offset(102, 45),
        const Offset(120, 20),
        const Offset(140, 45),
        const Offset(165, 33),
        const Offset(157, 66),
      ], const Color(0xFFFFD577));
      oval(114, 45, 12, 13, const Color(0xFFF58CA8));
    }
    if (hat == 7) {
      const pearl = Color(0xFFFFF4E6);
      const rose = Color(0xFFC77997);
      const gold = Color(0xFFC7A464);
      // A satin bow sits over a delicate pearl headband.
      for (int i = 0; i < 11; i++) {
        final angle = math.pi + .25 + i * (math.pi - .5) / 10;
        oval(
          120 + math.cos(angle) * 56 - 3,
          84 + math.sin(angle) * 27 - 3,
          6,
          6,
          pearl,
        );
      }
      final left = Path()
        ..moveTo(119, 49)
        ..cubicTo(82, 16, 71, 36, 81, 60)
        ..quadraticBezierTo(96, 62, 119, 49)
        ..close();
      final right = Path()
        ..moveTo(122, 49)
        ..cubicTo(159, 16, 170, 36, 160, 60)
        ..quadraticBezierTo(145, 62, 122, 49)
        ..close();
      for (final loop in [left, right]) {
        c.drawPath(loop, Paint()..color = pearl);
        c.drawPath(loop, outline);
      }
      path([
        const Offset(116, 50),
        const Offset(111, 75),
        const Offset(103, 69),
        const Offset(96, 73),
        const Offset(109, 47),
      ], rose);
      path([
        const Offset(124, 50),
        const Offset(129, 75),
        const Offset(137, 69),
        const Offset(144, 73),
        const Offset(131, 47),
      ], rose);
      line(89, 42, 110, 49, gold, 1.5);
      line(152, 42, 130, 49, gold, 1.5);
      box(113, 40, 15, 16, rose, 5);
      oval(117, 45, 7, 7, pearl, false);
    }
  }

  void drawBag(Color color) {
    final bag = a.item('Bags');
    if (bag == 1) {
      line(145, 199, 85, 245, const Color(0xFFB67A58), 5);
      box(75, 232, 32, 26, const Color(0xFFEBAE79), 6);
      line(79, 239, 103, 239);
      oval(89, 240, 5, 5, const Color(0xFFFFD577), false);
    }
    if (bag == 2) {
      line(143, 198, 93, 245, Colors.white, 4);
      oval(77, 226, 9, 22, const Color(0xFFFFF8EE));
      oval(94, 226, 9, 22, const Color(0xFFFFF8EE));
      box(75, 240, 31, 28, const Color(0xFFFFF8EE), 12);
      oval(83, 249, 4, 4, ink, false);
      oval(96, 249, 4, 4, ink, false);
      oval(89, 254, 4, 3, const Color(0xFFF58CA8), false);
    }
    if (bag == 3) {
      line(95, 197, 101, 228, const Color(0xFFF1B84B), 5);
      line(142, 197, 138, 228, const Color(0xFFF1B84B), 5);
      box(159, 214, 24, 37, const Color(0xFFF1B84B), 8);
      box(162, 234, 18, 12, color, 4);
    }
    if (bag == 4) {
      line(169, 241, 188, 199, const Color(0xFFF1B84B), 5);
      star(190, 190, 16, const Color(0xFFFFD577), true);
      star(211, 181, 5, Colors.white);
    }
    if (bag == 6) {
      const gold = Color(0xFFB89757);
      line(146, 198, 89, 245, gold, 3);
      for (int i = 0; i < 9; i++) {
        oval(
          142 - i * 5.9,
          199 + i * 4.9,
          4,
          4,
          const Color(0xFFFFFAE6),
          false,
        );
      }
      final shell = Path()
        ..moveTo(80, 265)
        ..cubicTo(62, 251, 66, 235, 79, 239)
        ..cubicTo(76, 224, 93, 222, 98, 234)
        ..cubicTo(105, 221, 121, 230, 115, 242)
        ..cubicTo(131, 240, 130, 255, 111, 268)
        ..quadraticBezierTo(95, 276, 80, 265)
        ..close();
      c.drawPath(
        shell,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFDCEFE5), Color(0xFF94C8B9), Color(0xFFD4B7DF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(68, 226, 56, 49)),
      );
      c.drawPath(shell, outline);
      for (final p in [
        const Offset(78, 243),
        const Offset(88, 236),
        const Offset(104, 236),
        const Offset(117, 246),
      ]) {
        c.drawPath(
          Path()
            ..moveTo(97, 267)
            ..quadraticBezierTo(p.dx, 252, p.dx, p.dy),
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      oval(92, 261, 10, 9, const Color(0xFFFFF8E7));
      star(122, 233, 5, const Color(0xFFFFE4A6));
    }
    if (bag == 7) {
      const rose = Color(0xFFEAB5C5);
      const pearl = Color(0xFFFFF3DF);
      line(143, 197, 89, 245, const Color(0xFFB89757), 3);
      final tail = Path()
        ..moveTo(108, 259)
        ..cubicTo(128, 260, 125, 242, 117, 249);
      c.drawPath(
        tail,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      c.drawPath(
        tail,
        Paint()
          ..color = rose
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
      path([
        const Offset(75, 244),
        const Offset(73, 229),
        const Offset(89, 238),
      ], rose);
      path([
        const Offset(95, 238),
        const Offset(111, 229),
        const Offset(109, 246),
      ], rose);
      box(74, 238, 36, 31, rose, 13);
      oval(81, 249, 4, 5, ink, false);
      oval(99, 249, 4, 5, ink, false);
      path([
        const Offset(89, 254),
        const Offset(95, 254),
        const Offset(92, 258),
      ], pearl);
      line(80, 257, 73, 255, ink, 1.3);
      line(80, 260, 73, 261, ink, 1.3);
      line(103, 257, 111, 255, ink, 1.3);
      line(103, 260, 111, 261, ink, 1.3);
      star(106, 240, 5, pearl, true);
    }
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) =>
      oldDelegate.a != a ||
      oldDelegate.scene != scene ||
      oldDelegate.motion != motion;
}
