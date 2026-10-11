import 'dart:typed_data';

import 'package:flutter/material.dart';

class PicturePreview extends StatefulWidget {
  final String name;
  final Uint8List bytes;
  final Future<void> Function(BuildContext) onSave;
  const PicturePreview({
    super.key,
    required this.name,
    required this.bytes,
    required this.onSave,
  });
  @override
  State<PicturePreview> createState() => _PicturePreviewState();
}

class _PicturePreviewState extends State<PicturePreview> {
  bool busy = false;
  Future<void> save() async {
    setState(() => busy = true);
    try {
      await widget.onSave(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your pal picture'),
    content: SizedBox(
      width: 300,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: (MediaQuery.sizeOf(context).height * .44).clamp(
                150.0,
                380.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  widget.bytes,
                  fit: BoxFit.contain,
                  semanticLabel: '${widget.name} picture',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save your picture or share it with your family.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Back to playing'),
      ),
      FilledButton.icon(
        onPressed: busy ? null : save,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.ios_share_rounded, size: 18),
        label: const Text('Save or share'),
      ),
    ],
  );
}
