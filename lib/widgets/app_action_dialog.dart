import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app_brand.dart';
import '../services/app_actions.dart';

/// A grown-up opens the iOS share sheet or an external link after the gate.
class AppActionDialog extends StatefulWidget {
  final AppActions actions;
  final bool sharing;
  final String? title;
  final String? description;
  final Map<String, Uri>? destinations;
  const AppActionDialog({
    super.key,
    required this.actions,
    this.sharing = false,
    this.title,
    this.description,
    this.destinations,
  });
  @override
  State<AppActionDialog> createState() => _AppActionDialogState();
}

class _AppActionDialogState extends State<AppActionDialog> {
  bool busy = false;
  String? message;
  AppActions get actions => widget.actions;
  String get shareText => actions.links.shareMessage();

  Future<void> run(Future<String?> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await action();
      if (mounted) setState(() => message = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not complete this action. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> share(BuildContext buttonContext) => run(() async {
    final box = buttonContext.findRenderObject()! as RenderBox;
    final result = await actions.share(
      shareText,
      box.localToGlobal(Offset.zero) & box.size,
    );
    return result.status == ShareResultStatus.unavailable
        ? 'Sharing is unavailable here. You can copy the message instead.'
        : null; // Closing the native sheet is not a successful share.
  });

  @override
  Widget build(BuildContext context) {
    final destinations = widget.destinations ?? actions.links.stores();
    final noShareLink = actions.links.shareUrl() == null;
    return AlertDialog(
      title: Text(
        widget.sharing ? 'Share $appName' : widget.title ?? 'Rate $appName',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sharing) ...[
              const Text(
                'Send a little invitation to family and friends. You choose where to share it.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                shareText,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              if (noShareLink) ...[
                const SizedBox(height: 12),
                const Text(
                  'This preview has no published app link yet. Only the invitation text will be shared.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ] else if (destinations.isEmpty)
              const Text(
                '$appName is not linked to an app-store listing yet. Ratings will be available when the app is published.',
              )
            else ...[
              Text(
                widget.description ?? 'Open the store to leave your own honest review. Reviews are optional and do not unlock rewards.',
              ),
              const SizedBox(height: 16),
              for (final entry in destinations.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => run(
                            () async => await actions.open(entry.value)
                                ? null
                                : 'Could not open the link. Please try again.',
                          ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text('Open ${entry.key}'),
                  ),
                ),
            ],
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(
                message!,
                key: const ValueKey('app-action-message'),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        if (widget.sharing) ...[
          TextButton.icon(
            key: const ValueKey('copy-app-message'),
            onPressed: busy
                ? null
                : () => run(() async {
                    await actions.copy(shareText);
                    return 'Invitation copied.';
                  }),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy message'),
          ),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              key: const ValueKey('share-app-message'),
              onPressed: busy ? null : () => share(buttonContext),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share'),
            ),
          ),
        ],
      ],
    );
  }
}
