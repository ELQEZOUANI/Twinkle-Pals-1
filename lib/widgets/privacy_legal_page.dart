import 'package:flutter/material.dart';

import '../app_brand.dart';
import '../models/avatar.dart';
import '../services/app_actions.dart';
import 'app_action_dialog.dart';
import 'lovely_theme.dart';
import 'parent_gate.dart';

class PrivacyLegalPage extends StatelessWidget {
  final AppActions actions;
  const PrivacyLegalPage({super.key, required this.actions});

  Future<void> openPublished(
    BuildContext context,
    String title,
    Uri uri,
  ) async {
    if (!await showParentGate(context) || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AppActionDialog(
        actions: actions,
        title: title,
        description: 'This opens the publisher’s document in your browser.',
        destinations: {title: uri},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privacy = AppLinks.publishedUrl(actions.links.privacyUrl);
    final terms = AppLinks.publishedUrl(actions.links.termsUrl);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & legal'),
        backgroundColor: cream,
      ),
      body: LovelyBackdrop(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('privacy-legal-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, color: purple, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'A little care for your family',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _card('Privacy policy', [
                      if (privacy == null)
                        _paragraph(
                          'About this preview',
                          'This is a summary of the current game’s data practices. The publisher’s final privacy policy and contact details have not been provided yet.',
                        ),
                      _paragraph(
                        'What the game saves',
                        'Saved pal names and outfits, stars, unlocks, story keepsakes, friendship hearts, bonus sparkles, sound and motion settings are stored on this device. $appName has no account or cloud-save service.',
                      ),
                      _paragraph(
                        'Personal information',
                        'The game does not ask for a real name, email, date of birth, location, camera access or microphone access. Please use a nickname for your saved pals.',
                      ),
                      _paragraph(
                        'Advertisements',
                        'Ads are disabled in development builds. Live ads are enabled only in configured release builds. When ads run, Google’s SDK may process network information, device information, ad interactions and diagnostics. Ad requests use child-directed settings and request non-personalized ads.',
                      ),
                      _paragraph(
                        'Sharing and outside links',
                        'Sharing the app sends only the invitation text and any configured app link to the destination you choose. Pal pictures are shared separately from the picture screen. Stores, ad providers and other services handle data under their own policies.',
                      ),
                      _paragraph(
                        'Managing your data',
                        'You can delete individual pals in My pals. Removing the app’s local data removes game progress and settings; the game has no account-based restore. Copies of pictures you saved or shared elsewhere are managed separately.',
                      ),
                      if (privacy == null)
                        _paragraph(
                          'Questions about privacy',
                          'The publisher’s contact and final policy must be supplied before public release.',
                        ),
                      if (privacy != null)
                        _link(
                          context,
                          'Read published privacy policy',
                          'Privacy policy',
                          privacy,
                        ),
                    ]),
                    const SizedBox(height: 18),
                    _card('Terms & legal', [
                      _paragraph(
                        'Playing $appName',
                        'Create outfits, help friends and save your looks. Rewards and progress belong to this local save and do not have a cash value. No account or in-app purchases are included in this version.',
                      ),
                      _paragraph(
                        'Optional sharing and reviews',
                        'A grown-up chooses whether to share an invitation or open a store to write an honest review. Neither action is required to play or earn rewards.',
                      ),
                      _paragraph(
                        'App and artwork',
                        '$appName uses original character artwork and sounds, plus third-party Flutter packages. Open-source notices are available below.',
                      ),
                      if (terms == null)
                        _paragraph(
                          'Release documents',
                          'These are preview usage notes, not a finalized publisher agreement. Publisher details and any applicable terms of use must be supplied before public release.',
                        ),
                      if (terms != null)
                        _link(
                          context,
                          'Read published terms',
                          'Terms of use',
                          terms,
                        ),
                      ListTile(
                        key: const ValueKey('open-source-licenses'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.code_rounded, color: purple),
                        title: const Text('Open-source licenses'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: appName,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String label, String title, Uri uri) =>
      OutlinedButton.icon(
        onPressed: () => openPublished(context, title, uri),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: Text(label),
      );

  Widget _card(String title, List<Widget> children) => Material(
    color: pearl,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: roseLine),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: purple,
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    ),
  );

  Widget _paragraph(String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 13, height: 1.55)),
      ],
    ),
  );
}
