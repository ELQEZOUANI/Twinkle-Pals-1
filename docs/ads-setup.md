# Twinkle Pals: Kids Dress Up — ads setup

## Gameplay

Garden gathering (challenge 0) is free. Beach besties, Cozy club, Superstar, Little explorer and Cat party (1–5) each unlock permanently after one rewarded ad. These challenge rewards use the same rewarded-ad service and ad unit as character rewards, with a callback for the selected challenge. Cancelling, closing without the reward, or no-fill leaves it locked. Once unlocked, it can be played repeatedly without another unlock ad. Challenge access persists separately from completed stars; older saved stars remain, but do not bypass the new challenge locks. Unlocking does not award a star or unlock a character. The store refuses to complete a locked challenge.

Luna (0) and Milo (1) are free. Cleo, Jasper, Poppy, Kai, Nova, Remy, Zara, Finn, Ivy and Sunny (2–11) each require one optional rewarded ad. A successful earned-reward callback persists that specific character's unlock immediately; closing the ad alone never unlocks it. Unlocks remain on this device until app data is cleared. There is no account or cross-device restoration.

A mission is complete only after its three outfit clues, selected friend-story route, themed mini-game and celebration keepsake have been finished. Each adventure has two routes and three progressively unlocked levels: Little steps, Growing explorer and Star adventurer. These routes and levels are included in the adventure’s permanent unlock; they do not require extra ads. Optional surprise favors can be skipped without blocking mission completion.

Leaving the story, mini-game or keepsake selection early awards nothing and has no ad placement. Every completed mission has an interstitial placement after its celebration, when the player chooses Keep styling, More challenges or Wear my gift. This includes replays without awarding duplicate mission stars. Leaving the celebration with Back/outside-tap cancels the transition. A missing/unready ad is skipped; the game never waits for an interstitial to load and then interrupts resumed styling. Failed/unmatched missions have no placement. Only one full-screen ad can be active.

Stars, keepsakes, replay counts, completed levels, route memories and earned wardrobe gifts are saved before the ad. Each route × level can award one friendship heart and one optional bonus sparkle, bounded to six hearts per adventure and 36 bonus sparkles across the game. Replays cannot duplicate these awards. If saving fails, the attempted progress is rolled back and the completion ad is not shown.

Flower wings, Mermaid bag, Pearl bow, Stardust dress, Explorer boots and Kitten purse are earned by completing their adventures. They are gameplay gifts, not additional rewarded-ad placements. A gift box lets children view and wear earned items; studio selection, random outfits and saving enforce their earned state. The existing helmet/crown/wand thresholds still use the six mission stars, not bonus sparkles. Previous mini-game stamps migrate to a completed first level and the corresponding gift.

Character ads govern choosing character presets and editing saved characters. A named friend can appear in a story without granting access to its editable preset. Existing saved artwork is retained even if its character is locked. The rose, pearl and gold theme does not change the ad preview labels or dismissal controls.

## iOS app-open placement and splash

The Flutter splash appears immediately while local progress opens. It shows three original animated characters and a blooming flower trail, with reduced motion respected. The iOS launch storyboard shows matching still artwork before Flutter draws its first frame. Ad preparation has a three-second startup limit; unavailable or late ads never block entry to the game.

App-open ads also have a placement when returning to Home after at least 30 seconds in the background. They do not interrupt Studio, adventures, Settings or other open routes. The fullscreen lock and a 30-second cooldown after fullscreen ads prevent overlapping ads and immediate ad-on-ad returns. App-open ads older than four hours are discarded and reloaded.

## iOS development

The project contains only the iOS platform target. `google_mobile_ads` 9.1.0 is pinned by `pubspec.lock`. Development builds use Google's iOS sample app ID and test ad units:

| Format | iOS test ad unit |
| --- | --- |
| Rewarded | `ca-app-pub-3940256099942544/1712485313` |
| Interstitial | `ca-app-pub-3940256099942544/4411468910` |
| App-open | `ca-app-pub-3940256099942544/5575463023` |

Run `flutter run` on an iPhone/iPad or iOS simulator. Native SDK serving still needs physical-device testing; test ads generate no real revenue. There is no browser ad simulation.

## iOS production configuration

Live serving defaults off. Replace the sample `GADApplicationIdentifier` in `ios/Runner/Info.plist` with your actual iOS AdMob app ID. Create separate rewarded, interstitial and app-open ad units for the iOS app. App IDs contain `~`; ad unit IDs contain `/`.

After configuring the publisher account, provider and creatives for the children's app, build with:

```sh
flutter build ipa --release \
  --dart-define=ENABLE_LIVE_ADS=true \
  --dart-define=ENABLE_KIDS_IOS_ADS=true \
  --dart-define=ADMOB_REWARDED_IOS=YOUR_IOS_REWARDED_AD_UNIT_ID \
  --dart-define=ADMOB_INTERSTITIAL_IOS=YOUR_IOS_INTERSTITIAL_AD_UNIT_ID \
  --dart-define=ADMOB_APP_OPEN_IOS=YOUR_IOS_APP_OPEN_AD_UNIT_ID
```

Both enable flags are required for live serving. The configured production rewarded, interstitial and app-open IDs are used by default; the `ADMOB_*_IOS` defines can override them for another AdMob setup. `ENABLE_KIDS_IOS_ADS` is a publisher-controlled release switch, not an Apple approval mechanism.

## Children's app configuration

Before initialization, the SDK receives `AgeRestrictedTreatment.child` and maximum content rating `G`. Requests set `nonPersonalizedAds: true`. Measurement initialization is delayed. ATT is available only in Settings under **For grown-ups**, after the parental gate and an explanation; it is never shown directly to a child or required for play. Release serving requests an under-age privacy update through UMP and checks `canRequestAds`; failures skip serving. Google documents that child age treatment disables personalized ads and prevents IDFA transmission, regardless of the ATT choice.

Apple's Kids Category generally excludes third-party advertising, with limited contextual-ad exceptions requiring documented practices and human review of creatives. The publisher must verify provider data practices and creative eligibility before enabling live ads. SDK content-rating flags alone do not establish the exception.

Finalize the policy, AdMob privacy configuration and App Store privacy/age declarations before distribution. Mission ads are requested after each completed mission, including replays; unavailable ads never block play or revoke saved progress.

## References

- [Google Mobile Ads Flutter setup](https://developers.google.com/admob/flutter/quick-start)
- [Rewarded callbacks and test units](https://developers.google.com/admob/flutter/rewarded)
- [Interstitial lifecycle and test units](https://developers.google.com/admob/flutter/interstitial)
- [App-open loading screen, callbacks and expiration](https://developers.google.com/admob/flutter/app-open)
- [Child-directed targeting](https://developers.google.com/admob/flutter/targeting)
- [iOS SDK data disclosures](https://developers.google.com/admob/ios/privacy/data-disclosure)
- [Apple App Review Guidelines §1.3](https://developer.apple.com/app-store/review/guidelines/#kids-category)
