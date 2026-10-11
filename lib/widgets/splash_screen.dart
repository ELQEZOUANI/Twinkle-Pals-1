import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_brand.dart';
import '../models/avatar.dart';
import 'avatar_art.dart';
import 'lovely_theme.dart';

/// Original characters and a petal trail, with no network artwork to load.
class SplashScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const SplashScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LovelyBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LovelyEmblem(size: 54),
                        const SizedBox(height: 16),
                        const Text(
                          appBrand,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 38,
                            letterSpacing: -1.4,
                            fontWeight: FontWeight.w900,
                            color: purple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          appSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: ink),
                        ),
                        const SizedBox(height: 28),
                        AspectRatio(
                          aspectRatio: 1.25,
                          child: LayoutBuilder(
                            builder: (context, stage) => Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [pearl, blush],
                                      ),
                                      borderRadius: BorderRadius.circular(160),
                                      border: Border.all(
                                        color: softGold.withValues(alpha: .4),
                                      ),
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  top: 17,
                                  left: 25,
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: softGold,
                                    size: 27,
                                  ),
                                ),
                                const Positioned(
                                  top: 35,
                                  right: 21,
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: purple,
                                    size: 18,
                                  ),
                                ),
                                for (final (index, character) in [
                                  (0, 4),
                                  (1, 0),
                                  (2, 8),
                                ])
                                  Positioned(
                                    left: stage.maxWidth * (index * .27 - .02),
                                    bottom: index == 1 ? 2 : 12,
                                    width:
                                        stage.maxWidth *
                                        (index == 1 ? .5 : .47),
                                    height:
                                        stage.maxHeight *
                                        (index == 1 ? 1 : .87),
                                    child: FittedBox(
                                      child: SizedBox(
                                        width: 240,
                                        height: 320,
                                        child: AvatarArt(
                                          avatar: characterPreset(character),
                                          scene: false,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (onRetry == null) ...[
                          const FlowerLoadingBar(),
                          const SizedBox(height: 18),
                          const Text(
                            'Growing a little magic…',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'We couldn’t open your saved pals. Let’s try again.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: onRetry,
                            child: const Text('Try again'),
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Text(
                          'Dream it. Dress it. Make it yours.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// An indeterminate loading trail: no invented percentage or ad countdown.
class FlowerLoadingBar extends StatefulWidget {
  const FlowerLoadingBar({super.key});
  @override
  State<FlowerLoadingBar> createState() => _FlowerLoadingBarState();
}

class _FlowerLoadingBarState extends State<FlowerLoadingBar>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      controller.stop();
      controller.value = .5;
    } else {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading your pals',
    child: SizedBox(
      width: 230,
      height: 48,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            CustomPaint(painter: _FlowerTrail(controller.value)),
      ),
    ),
  );
}

class _FlowerTrail extends CustomPainter {
  final double phase;
  const _FlowerTrail(this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final y = size.height / 2;
    final track = Rect.fromLTWH(16, y - 4, size.width - 32, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(8)),
      paint..color = roseLine,
    );
    for (var i = 0; i < 7; i++) {
      final x = 18 + (size.width - 36) * i / 6;
      final bloom = (.5 + .5 * math.cos((phase - i / 6) * math.pi * 2));
      final radius = 5 + bloom * 5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * math.pi * 2 + i * .2);
      for (var petal = 0; petal < 6; petal++) {
        final angle = petal * math.pi / 3;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(math.cos(angle), math.sin(angle)) * radius * .67,
            width: radius,
            height: radius,
          ),
          paint..color = Color.lerp(blush, purple, bloom * .75)!,
        );
      }
      canvas.drawCircle(Offset.zero, radius * .43, paint..color = softGold);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FlowerTrail oldDelegate) => phase != oldDelegate.phase;
}
