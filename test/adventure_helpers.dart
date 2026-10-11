import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> completeGardenAdventure(WidgetTester tester) async {
  final begin = find.byKey(const ValueKey('begin-adventure'));
  if (begin.evaluate().isNotEmpty) {
    await tester.ensureVisible(begin);
    await tester.tap(begin);
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 5; i++) {
    final flower = find.text('Flower').at(i);
    await tester.ensureVisible(flower);
    await tester.tap(flower);
    await tester.pumpAndSettle();
  }
  final finale = find.byKey(const ValueKey('adventure-finale'));
  await tester.ensureVisible(finale);
  await tester.tap(finale);
  await tester.pumpAndSettle();
  final stamp = find.byKey(const ValueKey('collect-adventure-stamp'));
  await tester.ensureVisible(stamp);
  await tester.tap(stamp);
  await tester.pumpAndSettle();
}
