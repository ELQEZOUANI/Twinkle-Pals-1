import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> showParentGate(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGate(),
    ) ??
    false;

class _ParentGate extends StatefulWidget {
  const _ParentGate();
  @override
  State<_ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<_ParentGate> {
  final answer = TextEditingController();
  final left = 12 + Random.secure().nextInt(8);
  final right = 6 + Random.secure().nextInt(4);
  String? error;

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  void check() {
    if (int.tryParse(answer.text) == left * right) {
      Navigator.pop(context, true);
    } else {
      setState(() => error = 'Please ask a grown-up to try again.');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('For grown-ups'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please hand the device to a parent or guardian before sharing or opening an outside link.',
          ),
          const SizedBox(height: 18),
          Text(
            '$left × $right = ?',
            key: const ValueKey('parent-question'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('parent-answer'),
            controller: answer,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: 'Answer', errorText: error),
            onSubmitted: (_) => check(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Back'),
      ),
      FilledButton(
        key: const ValueKey('parent-continue'),
        onPressed: check,
        child: const Text('Continue'),
      ),
    ],
  );
}
