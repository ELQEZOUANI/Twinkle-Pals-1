# Twinkle Pals: Kids Dress Up — feature audit

The game now has 14 customization categories containing 74 options, plus hair, eye and outfit colors and skin tones. The latest theme uses rose, pearl and gold with soft gradients, rounded cards and playful gift details.

| Feature | Result |
| --- | --- |
| Characters | 12 original characters. Luna/Milo free; ten locked with individual permanent rewarded-ad unlocks. All unlocked characters use the shared wardrobe. Old saved artwork stays visible; editing a locked character asks for its unlock. |
| Theme | Rose controls, pearl-blush surfaces, gold accents and deep plum text. Character skin, hair and outfit color palettes stay available. |
| Hair | 8 distinct styles and 7 colors. Pixie has a distinct fringe. |
| Expressions | Happy, wink, excited and dreamy. Closing expressions can hide eye details. |
| Eyes | Added Round, Almond, Sparkle and Sleepy, with 7 independent colors. |
| Mouth | Added Natural, Big smile, Little smile and Surprised. Natural follows the expression. |
| Tops | 7 choices, with clearer hoodie, sweater and long-sleeve details. |
| Dresses | Party, Garden, Cozy and earned Stardust dresses, plus None. Stardust has layered tulle, gold stars and pearl details. Selecting a top or bottoms removes the dress. |
| Bottoms | 4 choices. Fixed identical trousers/leggings; now seams and tapered star-patterned leggings differ. |
| Shoes | 5 choices, including earned Explorer boots with laces and patterned soles. Sandals have visible toes/straps; regular boots have buckles. |
| Hats | None plus 7 hats; helmet and crown respect star unlocks. Pearl bow is earned in Cozy club. |
| Glasses | None, round, sunglasses and heart frames. |
| Earrings | None, studs, hoops and stars. |
| Bags | None, satchel, bunny bag, backpack, star-unlocked magic wand and three adventure gifts: Flower wings, Mermaid bag and Kitten purse. The original vector wings sit behind the character; bags have distinct artwork. |
| Scenes | 6 backgrounds included in exported pictures. |
| Poses and animation | 3 poses with continuous idle sway/breathing and blinking. Happy dance has stronger movement. Outfit changes bounce; tapping the studio character waves. Sleeves follow moving arms, and accessories follow the body. Animation pauses in the background and respects reduced motion. Exported PNGs remain still. |
| Random outfit | Uses available items and respects both star locks and earned-adventure gifts. |
| Challenges | 6 three-stage adventures: three outfit clues, themed mini-game and keepsake finale. Bloom hunt, Ocean pairs, Snack kitchen, Dance remix, Treasure trail and Kitten care each offer two friend-story routes. Choices change the objects, goal or trail direction. Garden gathering free; five individually unlocked through rewarded ads. Unlocks persist independently of stars. Replay does not award duplicate mission stars. |
| Friend stories | 12 routes pair the player with named characters: picnic flowers/berries, ocean treasures/sandcastle supplies, snacks/story nook, dance duet/stage show, treasure/bird rescue and kitten care/spa. Friends can appear in a story without unlocking their editable character preset. |
| Progression | Little steps, Growing explorer and Star adventurer unlock in order per adventure. Hunt targets grow from 5 to 9, matching pairs from 3 to 5, sequences gain steps, and trails grow from a 4×4 to a 6×6 board. Earlier levels remain replayable. Shuffled boards and sequences keep play varied, with no timer or lost progress for mistakes. |
| Surprise favors | Optional themed bonus tasks appear during play. Children can skip them and still finish the main adventure. Correct answers trigger a friendly reaction; incorrect answers offer another try. |
| Friendship and sparkles | Each route × level awards at most one friendship heart and one optional bonus sparkle. Six hearts are available per adventure and 36 bonus sparkles across all six adventures. Replays cannot farm duplicate awards, but a previously skipped bonus can be earned later. |
| Adventure stamps | Three keepsake choices per theme; the latest keepsake, play count, levels, route memories and bonus awards persist. Leaving before stamp collection earns no progress and causes no completion ad. Previous mini-game stamps migrate to a completed first level and the theme’s gift; old mission stars and saved pals remain intact. |
| Ads | AdMob rewarded callbacks unlock selected characters/adventures; interstitial placement follows completed mission celebrations, including replays. App-open ads have startup and safe Home-return placements, with fullscreen exclusion, cooldown and four-hour expiration. Progress is saved before mission ads. iOS development builds use Google test units. The project targets iPhone and iPad only. Production serving defaults off. |
| Splash | Original animated pals, pearl/rose/gold styling and a blooming flower loading trail. Native launch artwork includes the same characters and a still flower. Startup handles storage retry and skips slow/failed ads; reduced motion is respected. |
| Rewards | Helmet at 2 mission stars, crown at 4, wand at 6. Each completed adventure also earns its own permanent wardrobe gift: Flower wings, Mermaid bag, Pearl bow, Stardust dress, Explorer boots or Kitten purse. A gift box shows earned items and provides Wear controls. Bonus sparkles do not count toward mission-star unlocks. |
| Saved gallery | Save, rename while saving, edit, and confirmed deletion. Local storage survives reopening. Saving a new look rejects unearned adventure items. Progress-save failures roll back the attempted awards and prevent the completion ad. |
| Pictures | Added visible preview. The iOS share sheet offers save/share with an iPad popover anchor. PNG generation and preview are verified; physical-device sharing still needs testing. |
| Sound | Original synthesized pop/celebration effects and contextual bloom, sparkle, cheer and purr reactions, with a saved mute preference. |
| Help | Added in-game guide covering customization, challenges, rewards, saving and controls. |
| Settings | Dedicated page from the header gear. Saved sound and reduced-motion switches, collection counts and the game guide. Respects device motion preferences, rolls back failed preference saves and preserves the studio draft when returning. Scrollable on iPhone and iPad. |
| Device layouts | iPhone and iPad only, with bottom touch navigation in both orientations. iPhone Studio scrolls vertically; iPad Studio uses two panes when space allows. Orientation determines grid columns, narrow iPad windows get compact controls, and rotating preserves outfit edits. Safe areas protect controls from screen cutouts and the home indicator. |
| Share and rate | For grown-ups section in Settings. Share sends an invitation through the native iOS share sheet with a Copy message fallback. Rate opens the configured App Store listing. Both require a parent check, award no rewards and explain missing links in the preview. No app listing or public app link has been supplied yet. |
| Privacy and legal | Offline summary of local data, sharing, ads and deletion; preview usage notes and Flutter open-source licenses. Published policy/terms links are configurable and parent-gated. Final publisher identity/contact, documents and store disclosures remain release work. |
| Scrolling | One vertical studio scroll on phones, mouse/touch support. Categories start collapsed; Show categories opens the full list, and choosing a category folds it away. The selected category remains visible. |

Existing saved avatars retain their eye colors when loaded into the expanded face editor. New wardrobe items are appended, preserving all older item indexes. The test suite covers distinct artwork, story/level solvability, reward callbacks, replay deduplication, persistence, Settings/navigation, scrolling, parent checks and privacy links, plus startup timeout/retry, splash motion/layout, app-open fullscreen exclusion, expiration and late-load cleanup. Artwork generators output only iOS assets. SDK delivery, native sharing and final production ad configuration still require physical-device verification.

Face presets set a matching natural mouth, and choosing an eye style opens a dreamy expression. Eye and face thumbnails remove glasses so options remain visible. The eye editor offers a shortcut to remove sunglasses when they hide the chosen eyes.

Rooms, a longer story campaign, additional mini-games, cloud accounts, and localization are not included in this version. App Store signing and submission remain separate release work. Physical-device save/share and audio testing are still needed before release.
