# Twinkle Pals: Kids Dress Up

An original iOS Flutter avatar dress-up game inspired by the playful feeling of the provided reference. All characters are drawn locally with Flutter Canvas; the reference game's characters and logo are not used.

## Run on iOS

This project targets iPhone and iPad only. Open an iOS simulator or connect an iPhone, then run:

```sh
flutter pub get
flutter devices
flutter run -d YOUR_IOS_DEVICE_ID
```

Game progress is stored locally on the device. There is no account or cloud-save service.

## Included

- Twelve named character presets with different looks and personalities: Luna and Milo are free; the other ten unlock individually through an optional rewarded ad.
- A rose, pearl and gold theme with soft gradients, rounded controls and a gift-box wardrobe collection designed for children.
- Character unlocks persist locally. Closing an ad without earning its reward, no-fill, and load/show failures leave the character locked. Home, studio picker, gallery edits and saves enforce the same access rules. Old saved pictures are preserved.
- A preloaded interstitial placement after each successful mission celebration, including replays. Stars are saved first; mission interstitials are not shown for unfinished missions, at launch or while styling. Ad failures never revoke progress.
- Eight hairstyles, seven hair colors, six skin tones and four expressions.
- Four eye styles with seven independent eye colors, and four mouth styles.
- Fourteen customization categories with 74 options: seven tops, four dresses plus None, four bottoms, five shoe styles and seven outfit colors.
- Seven hats, three glasses, three earrings and seven bags/accessories; each accessory category also offers None.
- Six illustrated scenes and three poses.
- Animated characters with idle breathing/swaying, blinking, outfit-change bounces and a tap-to-wave action in the studio. Clothing and accessories move with the character. Animation pauses in the background and respects reduced motion; picture exports stay still.
- Random outfits that respect star and adventure-reward locks. Saving also checks that new adventure accessories have been earned.
- Six three-stage adventures: style with three outfit clues, play a themed activity, then choose a celebration keepsake. Activities include Bloom hunt, Ocean pairs, Snack kitchen, Dance remix, Treasure trail and Kitten care.
- Two story choices per adventure, each helping a named friend with a different task. Choose flowers or strawberries, ocean treasures or sandcastle supplies, snacks or a reading nook, a dance duet or a stage show, treasure or a bird rescue, and kitten care or a kitten spa.
- Three progressively unlocked levels: Little steps, Growing explorer and Star adventurer. Later levels add more objects, matching pairs, sequence steps or stepping stones. Shuffled boards and sequences vary on replay. Friendly hints, no timer and no progress penalty for wrong choices.
- Animated reactions and optional surprise favors during play. Each route and level can earn one friendship heart and one bonus sparkle: up to six hearts per adventure and 36 bonus sparkles across the game. Replaying the same route and level cannot duplicate these awards; skipped bonus favors do not block the adventure.
- A local adventure stamp book saves the latest keepsake, completed-play count, levels, story-route memories and bonus awards. Stars are awarded only after finishing the activity and collecting the stamp. Existing mini-game stamps migrate to the first completed level and its wardrobe gift; older stars and saved pals are preserved.
- Garden gathering is free; the other five adventures each unlock permanently through one optional rewarded ad. Unlocking a challenge does not award a star.
- Persistent stars: each challenge awards one star and can be replayed for fun.
- Space helmet unlocked at two stars, royal crown at four, magic wand at six.
- Six wardrobe gifts earned through play: Flower wings, Mermaid bag, Pearl bow, Stardust dress, Explorer boots and Kitten purse. A gift box shows the collection and lets children wear earned items in the studio. Bonus sparkles are separate from the six mission stars and do not replace these unlock rules.
- Named saved-avatar gallery, editing existing looks and confirmed deletion.
- Picture preview and 900 × 1200 PNG export: the native iOS save/share sheet, with an iPad popover anchor.
- Original synthesized pop and celebration effects, contextual bloom/sparkle/cheer/purr reactions and a saved mute setting.
- Two layouts designed for iPhone and iPad. Both use touch navigation along the bottom. iPhones keep a vertically scrolling studio in either orientation; iPads use a two-pane studio when there is space, with compact controls in narrow multitasking windows. Grids follow phone/tablet orientation, safe areas protect controls, and rotating keeps the current outfit. The category selector starts collapsed and folds away after a selection.
- Original app icons. No login, purchases or backend. Ads are disabled in iOS development builds.
- A Twinkle Pals splash with three original animated characters and a blooming flower loading trail. Matching native launch artwork appears before Flutter starts. Optional AdMob app-open placements run at startup and safe returns to Home; offline/no-fill never blocks play.
- A Settings page, opened from the header gear, with saved sound and reduced-motion controls, a collection summary and the How to play guide. Returning keeps the studio draft intact; device motion preferences are also respected.
- Settings also includes Share the app (native share/copy fallback), Rate the app (platform store links), and a parent-gated Privacy & legal button that opens the published Twinkle Pals Blogger policy. Open-source licenses remain available in-app; configure the remaining publisher links using [Settings app links](docs/app-links.md).

## Source structure

```text
lib/main.dart                 Theme, navigation, home, studio, challenges and gallery
lib/models/avatar.dart        Avatar data, character presets, items and style rules
lib/models/adventure.dart     Friend stories, levels, randomized rounds and bonus favors
lib/widgets/adventure_play.dart  Story choices, activity boards, reactions and gift finales
lib/widgets/avatar_art.dart   Original layered vector character and scene renderer
lib/services/game_store.dart  Local persistence and progress
lib/services/ads/             Rewarded/interstitial/app-open service, native iOS SDK
lib/widgets/game_startup.dart  Local-storage startup and bounded app-open preparation
lib/widgets/splash_screen.dart  Original character splash and animated flower trail
lib/widgets/ios_layout.dart    iPhone/iPad orientation, grids and studio layout
lib/services/avatar_export.dart  Fixed 900 × 1200 PNG export
lib/widgets/picture_preview.dart  Picture preview and save/share controls
lib/widgets/settings_page.dart  Saved play preferences, collection summary and help
lib/widgets/privacy_legal_page.dart  Offline privacy notes, legal information and licenses
lib/services/app_actions.dart  Publisher links, app sharing, copying and external URLs
assets/sounds/                Original synthesized interaction and adventure effects
tool/create_icons_test.dart   Reproducible Flutter Canvas icon generator
tool/create_splash_test.dart  Reproducible native launch artwork and splash preview
test/game_test.dart           Data and gameplay tests
test/ads_test.dart            Character access, earned/cancelled rewards and mission ad tests
test/app_open_ads_test.dart   SDK callbacks, fullscreen lock, expiration and late-load cleanup
test/startup_test.dart        Splash layout/motion, startup timeout, retry and ad failures
test/adventure_test.dart      Randomized solvability, phone gameplay and keepsake persistence
test/reward_art_test.dart     Earned outfit locks, randomization and saved item compatibility
test/settings_test.dart       Preference persistence, failure rollback, navigation and motion
test/ios_layout_test.dart     iPhone/iPad safe areas, rotation, studio and collection
test/app_actions_test.dart    Parent gates, App Store links, share failures and legal navigation
ios/                         iPhone/iPad Flutter platform project
```

All avatar items share a 240 × 320 coordinate system. `AvatarPainter` draws back hair, body, clothing, face, front hair, hats, glasses, earrings and bags in order. To add an item, extend its category in `avatar.dart` and add its rendering branch in `avatar_art.dart`.

## Verify and build

```sh
flutter analyze
flutter test
flutter build ios --simulator --debug
flutter build ipa --release
```

Resolved dependencies are pinned in `pubspec.lock`. Mobile builds require the appropriate platform SDK. Regenerate all icons with `flutter test tool/create_icons_test.dart`.

Flutter analysis is clean, all 77 game tests pass, and the iOS simulator debug build succeeds. Validation covers iPhone and iPad layouts, rotation with outfit preservation, safe areas, gameplay, rewarded callbacks, saved progress, Settings, parent checks, policy navigation, startup timeout/retry, native ad fullscreen exclusion and expiration, and reduced-motion splash layouts. The icon and launch-artwork generators output iOS assets only. Simulator builds and widget tests do not prove ad delivery on a physical device; test the native SDK, sharing, export and audio before release.

## Release work still needed

This is a playable first version. App-store release still needs physical-device testing (including offline/no-fill, ad dismissal, export and audio), developer-account signing, store screenshots/descriptions, final age-group and child-directed store declarations, and store submissions. Live ads require both release enable flags and provider review for the Kids Category. Rooms, additional adventures, cloud saves and localization are future features.

## Implementation references

- [Flutter persistence cookbook](https://docs.flutter.dev/cookbook/persistence/key-value)
- [share_plus for iOS sharing](https://pub.dev/packages/share_plus)
- [audioplayers](https://pub.dev/packages/audioplayers)
