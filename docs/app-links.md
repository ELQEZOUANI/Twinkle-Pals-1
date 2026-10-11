# Settings: share, rate, privacy and legal

Settings includes Share the app, Rate the app and Privacy & legal. The two
external actions require a fresh parent check each time. Reading the in-app
privacy summary and open-source licenses does not require that check; opening
a published policy or terms page does. The math check is an interaction gate,
not verification of identity, age or consent to data collection.

## Publisher configuration

The privacy button already points to the supplied Blogger page by default:

`https://twinklepals.blogspot.com/2026/10/blog-post.html?m=0`

The `m=0` parameter opens the published custom theme on iPhone and iPad.
Blogger's separate mobile view (`m=1`) currently shows an empty post because
the policy content is in the custom theme rather than the post body. The
custom theme itself adapts to small screens.

Share and Rate use this App Store listing by default:

`https://apps.apple.com/app/id6821077208`

Share includes that link in its invitation, and Rate opens that listing. You
can replace publisher links at build time:

```sh
flutter build ipa --release \
  --dart-define=APP_PUBLIC_URL=YOUR_PUBLIC_APP_HTTPS_URL \
  --dart-define=APP_STORE_URL_IOS=https://apps.apple.com/app/id6821077208 \
  --dart-define='PRIVACY_POLICY_URL=https://twinklepals.blogspot.com/2026/10/blog-post.html?m=0' \
  --dart-define=TERMS_URL=YOUR_TERMS_HTTPS_URL
```

This project targets iOS only. `APP_PUBLIC_URL` remains optional; when it is
empty, Share falls back to the configured App Store listing.

Share uses the public app link, falling back to the App Store
listing. Rate opens only the configured App Store listing.
Without a link, Share sends only an invitation description and tells the adult
that this is a preview with no install link. Rate explains that a listing is
not connected; it never pretends to submit a rating. Sharing/reviewing earns no
reward. HTTP, loopback/local and credential-bearing URLs are rejected, and the
development URLs are never automatically shared.

The adult presses a Share/Open button after the gate. Native iOS sharing
uses share_plus, including a nonempty iPad anchor. Copy message is an explicit fallback for unsupported sharing.
Cancellation does not display a false success message. Launch/copy/share
failures remain in the dialog and offer another try. Link launch uses
url_launcher and the external browser/store.

## Privacy and legal content

The offline page describes the data actually saved by GameStore, local deletion,
picture sharing and iOS AdMob behavior. It does not
claim that an ad-supported mobile version processes no data. The default
privacy text is labelled preview information; the terms are preview usage
notes. Replace/finalize these and supply the publisher's identity and privacy
contact before distribution. A published policy must reflect the actual SDK
versions, enabled providers, release configuration and hosting practices.

Open-source licenses use Flutter's built-in LicensePage and LicenseRegistry.
Do not treat the interaction gate or these preview notes as certification of
store or legal compliance.

References used to guide implementation:

- [Apple Kids Category and parental gates](https://developer.apple.com/app-store/review/guidelines/#kids-category)
- [Google Mobile Ads data disclosures](https://developers.google.com/admob/ios/privacy/data-disclosure)
- [Flutter URL launcher](https://pub.dev/packages/url_launcher)
- [Share Plus](https://pub.dev/packages/share_plus)
