# Elegant kids App Store screenshot collection

Nine coordinated screenshots built from the nine supplied app captures. The visual theme combines pearl ivory, blush, lavender, garden green and champagne gold with an elegant storybook serif, floral details and large phone previews.

## Upload files

- `iphone-6.9`: nine portrait PNGs, 1320 × 2868 pixels.
- `iphone-6.5`: the same nine designs, 1242 × 2688 pixels.
- Upload in numerical filename order. Use the corresponding size folder for the App Store Connect display slot.
- `preview.png` and `preview.html` show the complete collection and are review files, not upload screenshots.

Dimensions were checked against Apple's screenshot specifications on October 9, 2026: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

## Artwork and sources

The decorative background was generated with the built-in ImageGen tool. The original app screenshots are inserted directly into deterministic HTML/CSS layouts; interface text, characters and app states come from the supplied captures. Their existing branding, status bars and modal dimming are retained. No app code was changed.

`design.json` contains the exact headlines, supporting text, colors, screenshot mapping and display crop coordinates. `render.cjs` renders the editable HTML compositions using the locally bundled Node.js runtime and Playwright. Source captures and background artwork are in `assets/`. `background-prompt.txt` records the final image generation prompt.

## Order

1. Welcome — A little world of wonder.
2. Meet your pals — Big style. Little besties.
3. Dress-up studio — Dream it. Dress it.
4. Story adventures — Little looks. Big adventures.
5. Style your adventure — Dress for a lovely adventure.
6. Bloom hunt — A little play. A lot of joy.
7. Celebrate friendship — Every friendship is a celebration.
8. Rewards and gifts — Little wins. Lovely surprises.
9. My pals — Your pals. Your happy place.
