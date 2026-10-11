import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/avatar.dart';

const blush = Color(0xFFF7E3E9);
const softGold = Color(0xFFC29A55);
const pearl = Color(0xFFFFFDFB);
const roseLine = Color(0xFFEBD3DB);

ThemeData lovelyTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: cream,
  colorScheme: ColorScheme.fromSeed(seedColor: purple, surface: pearl).copyWith(
    primary: purple,
    onPrimary: Colors.white,
    secondary: const Color(0xFF92703A),
    surface: pearl,
    onSurface: ink,
    outline: const Color(0xFFAC8293),
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: ink,
    displayColor: ink,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: purple,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 50),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      backgroundColor: pearl,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: roseLine),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: pearl,
    selectedColor: blush,
    side: const BorderSide(color: roseLine),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    labelStyle: const TextStyle(color: ink),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: pearl,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: const BorderSide(color: roseLine),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: pearl,
    indicatorColor: blush,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        color: states.contains(WidgetState.selected) ? purple : ink,
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w800
            : FontWeight.w500,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cream,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

/// Quiet pearl, petal and gold details stay behind readable, opaque controls.
class LovelyBackdrop extends StatelessWidget {
  final Widget child;
  const LovelyBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF6F8), cream, Color(0xFFFBF4E8)],
      ),
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: PearlSprinkles())),
        ),
        child,
      ],
    ),
  );
}

class PearlSprinkles extends CustomPainter {
  const PearlSprinkles();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7C9D5).withValues(alpha: .34);
    for (var i = 0; i < 14; i++) {
      final x = ((i * 137 + 29) % 997) / 997 * size.width;
      final y = ((i * 191 + 61) % 811) / 811 * size.height;
      final center = Offset(x, y);
      if (i % 3 == 0) {
        final star = Path();
        for (var j = 0; j < 8; j++) {
          final radius = j.isEven ? 7.0 : 2.2;
          final angle = j * math.pi / 4;
          final point =
              center + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (j == 0) {
            star.moveTo(point.dx, point.dy);
          } else {
            star.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(
          star..close(),
          paint..color = softGold.withValues(alpha: .22),
        );
      } else {
        canvas.drawCircle(
          center,
          3,
          paint..color = const Color(0xFFE7C9D5).withValues(alpha: .4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PearlSprinkles oldDelegate) => false;
}

class LovelyEmblem extends StatelessWidget {
  final double size;
  const LovelyEmblem({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: pearl,
      shape: BoxShape.circle,
      border: Border.all(color: softGold.withValues(alpha: .65)),
      boxShadow: [
        BoxShadow(
          color: purple.withValues(alpha: .08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(Icons.local_florist_rounded, color: purple, size: size * .62),
  );
}
