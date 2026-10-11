import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pocket_pals/services/app_actions.dart';
import 'package:pocket_pals/services/game_store.dart';
import 'package:pocket_pals/widgets/lovely_theme.dart';
import 'package:pocket_pals/widgets/settings_page.dart';
import 'package:pocket_pals/widgets/privacy_legal_page.dart';

const configured = AppLinks(
  publicUrl: 'https://example.com/pocket-pals',
  iosStoreUrl: 'https://apps.apple.com/app/id123456789',
  privacyUrl: 'https://example.com/privacy',
  termsUrl: 'https://example.com/terms',
);

class FakeAppActions extends AppActions {
  final shared = <String>[];
  final copied = <String>[];
  final opened = <Uri>[];
  bool openResult = true;
  bool failShare = false;
  Rect? shareOrigin;
  FakeAppActions({super.links = configured});
  @override
  Future<ShareResult> share(String text, Rect origin) async {
    if (failShare) throw StateError('Unavailable');
    shared.add(text);
    shareOrigin = origin;
    return const ShareResult('', ShareResultStatus.unavailable);
  }

  @override
  Future<void> copy(String text) async {
    copied.add(text);
  }

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return openResult;
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> passParentGate(WidgetTester tester) async {
  final question = tester
      .widget<Text>(find.byKey(const ValueKey('parent-question')))
      .data!;
  final values = RegExp(r'\d+')
      .allMatches(question)
      .map((m) => int.parse(m.group(0)!))
      .toList();
  await tester.enterText(
    find.byKey(const ValueKey('parent-answer')),
    '${values[0] * values[1]}',
  );
  await tap(tester, find.byKey(const ValueKey('parent-continue')));
}

Future<GameStore> pumpSettings(
  WidgetTester tester,
  FakeAppActions actions,
) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final store = GameStore(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    MaterialApp(
      theme: lovelyTheme(),
      home: SettingsPage(store: store, actions: actions, onShowGuide: () {}),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  test('Only App Store links are offered and local links are never shared', () {
    const defaults = AppLinks();
    expect(defaults.iosStoreUrl, appStoreUrl);
    expect(defaults.stores(), {'App Store': Uri.parse(appStoreUrl)});
    expect(defaults.shareUrl(), Uri.parse(appStoreUrl));
    expect(defaults.shareMessage(), contains(appStoreUrl));
    expect(configured.stores().keys, ['App Store']);
    expect(configured.shareMessage(), contains(configured.publicUrl));
    const noPublic = AppLinks(
      iosStoreUrl: 'https://apps.apple.com/app/id123456789',
    );
    expect(noPublic.shareUrl().toString(), noPublic.iosStoreUrl);
    for (final url in [
      'http://127.0.0.1:8080',
      'https://localhost',
      'https://127.0.0.1',
      'https://demo.local',
      'javascript:alert(1)',
      'https://user:secret@example.com',
      'bad url',
    ]) {
      final links = AppLinks(publicUrl: url, iosStoreUrl: '');
      expect(links.shareUrl(), isNull);
      expect(links.shareMessage(), isNot(contains(url)));
    }
  });

  testWidgets(
    'Cancelling or failing the parent check never shares or opens a store',
    (tester) async {
      final actions = FakeAppActions();
      await pumpSettings(tester, actions);
      await tap(tester, find.byKey(const ValueKey('settings-share')));
      await tester.enterText(find.byKey(const ValueKey('parent-answer')), '0');
      await tap(tester, find.byKey(const ValueKey('parent-continue')));
      expect(find.text('Please ask a grown-up to try again.'), findsOneWidget);
      expect(find.text('Share Twinkle Pals: Kids Dress Up'), findsNothing);
      await tap(tester, find.text('Back'));
      expect(actions.shared, isEmpty);
      expect(actions.opened, isEmpty);
      await tap(tester, find.byKey(const ValueKey('settings-rate')));
      await tap(tester, find.text('Back'));
      expect(actions.opened, isEmpty);
      expect(find.text('Rate Twinkle Pals: Kids Dress Up'), findsNothing);
    },
  );

  testWidgets(
    'Parent-approved sharing offers an honest unavailable fallback and copy',
    (tester) async {
      final actions = FakeAppActions();
      final store = await pumpSettings(tester, actions);
      await tap(tester, find.byKey(const ValueKey('settings-share')));
      await passParentGate(tester);
      await tap(tester, find.byKey(const ValueKey('share-app-message')));
      expect(actions.shared.single, contains(configured.publicUrl));
      expect(actions.shareOrigin!.width, greaterThan(0));
      expect(
        find.text(
          'Sharing is unavailable here. You can copy the message instead.',
        ),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('copy-app-message')));
      expect(actions.copied.single, actions.shared.single);
      expect(find.text('Invitation copied.'), findsOneWidget);
      expect(store.stars, 0);
      expect(store.unlockedCharacters, {0, 1});
    },
  );

  testWidgets('Sharing failures remain recoverable without claiming success', (
    tester,
  ) async {
    final actions = FakeAppActions()..failShare = true;
    await pumpSettings(tester, actions);
    await tap(tester, find.byKey(const ValueKey('settings-share')));
    await passParentGate(tester);
    await tap(tester, find.byKey(const ValueKey('share-app-message')));
    expect(
      find.text('Could not complete this action. Please try again.'),
      findsOneWidget,
    );
    await tap(tester, find.byKey(const ValueKey('copy-app-message')));
    expect(actions.copied.length, 1);
  });

  testWidgets(
    'Rate opens the correct mobile listing and reports launch failures',
    (tester) async {
      final actions = FakeAppActions()..openResult = false;
      final store = await pumpSettings(tester, actions);
      await tap(tester, find.byKey(const ValueKey('settings-rate')));
      await passParentGate(tester);
      expect(find.text('Open App Store'), findsOneWidget);
      expect(find.text('Open Google Play'), findsNothing);
      await tap(tester, find.text('Open App Store'));
      expect(actions.opened.single.toString(), configured.iosStoreUrl);
      expect(
        find.text('Could not open the link. Please try again.'),
        findsOneWidget,
      );
      expect(store.stars, 0);
      expect(store.unlockedCharacters, {0, 1});
    },
  );

  testWidgets(
    'Unpublished preview shares text only and gives a clear rating message',
    (tester) async {
      final actions = FakeAppActions(
        links: const AppLinks(
          publicUrl: 'http://127.0.0.1:8080',
          iosStoreUrl: '',
        ),
      );
      await pumpSettings(tester, actions);
      await tap(tester, find.byKey(const ValueKey('settings-share')));
      await passParentGate(tester);
      expect(
        find.text(
          'This preview has no published app link yet. Only the invitation text will be shared.',
        ),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('copy-app-message')));
      expect(actions.copied.single, isNot(contains('127.0.0.1')));
      await tap(tester, find.text('Back'));
      await tap(tester, find.byKey(const ValueKey('settings-rate')));
      await passParentGate(tester);
      expect(
        find.text(
          'Twinkle Pals: Kids Dress Up is not linked to an app-store listing yet. Ratings will be available when the app is published.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Privacy button opens the full Blogger policy theme after the parent check and can retry a failed launch',
    (tester) async {
      const links = AppLinks();
      expect(
        links.privacyUrl,
        'https://twinklepals.blogspot.com/2026/10/blog-post.html?m=0',
      );
      final actions = FakeAppActions(links: links)..openResult = false;
      await pumpSettings(tester, actions);
      await tap(tester, find.byKey(const ValueKey('settings-privacy')));
      expect(find.text('For grown-ups'), findsWidgets);
      expect(actions.opened, isEmpty);
      await passParentGate(tester);
      await tap(tester, find.text('Open Privacy & legal'));
      expect(actions.opened.single.toString(), links.privacyUrl);
      expect(
        find.text('Could not open the link. Please try again.'),
        findsOneWidget,
      );
      actions.openResult = true;
      await tap(tester, find.text('Open Privacy & legal'));
      expect(actions.opened.length, 2);
      expect(actions.opened.last.toString(), links.privacyUrl);
      expect(
        find.text('Could not open the link. Please try again.'),
        findsNothing,
      );
      await tap(tester, find.text('Back'));
      expect(find.byKey(const ValueKey('settings-licenses')), findsNothing);
      expect(find.text('Open-source licenses'), findsNothing);
    },
  );

  testWidgets(
    'Cancelling the policy parent check keeps Settings open without launching Blogger',
    (tester) async {
      final actions = FakeAppActions(links: const AppLinks());
      await pumpSettings(tester, actions);
      await tap(tester, find.byKey(const ValueKey('settings-privacy')));
      await tap(tester, find.text('Back'));
      expect(actions.opened, isEmpty);
      expect(find.byKey(const ValueKey('settings-privacy')), findsOneWidget);
    },
  );

  testWidgets(
    'Privacy and legal notes scroll offline, with licenses and guarded published links',
    (tester) async {
      final actions = FakeAppActions();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: lovelyTheme(),
          home: PrivacyLegalPage(actions: actions),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('What the game saves'), findsOneWidget);
      await tap(tester, find.text('Read published privacy policy'));
      expect(find.text('For grown-ups'), findsOneWidget);
      expect(actions.opened, isEmpty);
      await passParentGate(tester);
      await tap(tester, find.text('Open Privacy policy'));
      expect(actions.opened.single.toString(), configured.privacyUrl);
      await tap(tester, find.text('Back'));
      await tap(tester, find.text('Read published terms'));
      await passParentGate(tester);
      await tap(tester, find.text('Open Terms of use'));
      expect(actions.opened.last.toString(), configured.termsUrl);
      await tap(tester, find.text('Back'));
      await tap(tester, find.byKey(const ValueKey('open-source-licenses')));
      expect(find.byType(LicensePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
