# Playful kids App Store screenshots — avatar edition

Nine separate App Store screenshot designs with the app's own original avatars, colorful clouds, stars, pastel rainbows, rounded headlines and white phone frames.

## Individual upload files

- `iphone-6.9/`: nine PNGs at 1320 × 2868.
- `iphone-6.5/`: nine PNGs at 1242 × 2688.
- Use the matching display-size folder and upload in numerical order.
- `preview.png` shows all nine for review; the upload files are individual images.

The dimensions follow Apple's screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

## Design details

Avatars are exported directly from the app's original `AvatarPainter` and `characterPreset` code. The transparent assets use the exact drawing system, clothing, facial features and colors used in the game. Poses and outfits are selected from real in-app options. No generated imitation characters are used.

The candy-cloud background is generated with the built-in ImageGen tool; its final prompt is saved in `background-prompt.txt`. The supplied app screens are directly embedded in deterministic HTML/CSS layouts. UI content, status bars, in-app names and modal dimming are retained from those source captures. The phone, characters and text are kept separate within the editable layouts so they can be adjusted later.

`design.json` records every headline, subtitle, color, avatar choice and source mapping. `render.cjs` produces all screenshots and the collection preview. `export_avatars_test.dart` regenerates the original character assets with Flutter. `verification.json` records the size, format and opacity checks for all 18 PNGs. Production app code was not changed.

## Original screen mapping

1. Welcome / splash
2. Home / meet your pals
3. Dress-up studio
4. Story adventures
5. Style your adventure
6. Bloom hunt
7. Celebrate friendship
8. Rewards and gifts
9. My pals
