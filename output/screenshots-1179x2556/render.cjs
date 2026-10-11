// Render the original editable portrait compositions at the requested size.
const fs = require('fs');
const path = require('path');
const runtime = '/Users/Apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const { chromium } = require(path.join(runtime, 'playwright'));
const sharp = require(path.join(runtime, 'sharp'));
const root = __dirname;
const source = path.join(root, '..', 'kids-avatar-app-store-screens');
const designs = JSON.parse(fs.readFileSync(path.join(source, 'design.json'), 'utf8'));
const scale = 2556 / 2868;
const margin = (1179 - 1320 * scale) / 2;
const css = `
html,body{width:1179px;height:2556px;overflow:hidden;background:#fffaf3}
.poster{transform-origin:top left;transform:scale(${scale});margin-left:${margin}px}
.app-brand{position:absolute;z-index:1;left:60px;top:43px;width:1200px;text-align:center;font-size:28px;font-weight:800;color:#68465c;letter-spacing:.4px}
.eyebrow{top:122px}
h1{top:220px}
.subtitle{top:520px}
`;

(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
    args: ['--allow-file-access-from-files'],
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1179, height: 2556 }, deviceScaleFactor: 1 });
    const checks = [];
    const thumbs = [];
    for (const design of designs) {
      const original = fs.readFileSync(path.join(source, design.id + '.html'), 'utf8');
      const html = original.replace('</head>', `<style>${css}</style></head>`)
        .replace('<main class="poster">', '<main class="poster"><div class="app-brand">Twinkle Pals: Kids Dress Up</div>');
      const file = path.join(root, design.id + '.html');
      fs.writeFileSync(file, html);
      await page.goto('file://' + file);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForFunction(() => [...document.images].every(image => image.complete && image.naturalWidth > 0));
      const bounds = await page.evaluate(() => ['.app-brand', '.eyebrow', 'h1', '.subtitle', '.footer', '.phone'].map(selector => {
        const element = document.querySelector(selector);
        const rect = element.getBoundingClientRect();
        return { selector, x: rect.x, y: rect.y, right: rect.right, bottom: rect.bottom, overflow: element.scrollWidth > element.clientWidth + 1 };
      }));
      if (bounds.some(box => box.x < 0 || box.y < 0 || box.right > 1179 || box.bottom > 2556 || box.overflow)) throw new Error(design.id + ': invalid layout ' + JSON.stringify(bounds));
      const png = path.join(root, design.id + '.png');
      await sharp(await page.screenshot({ omitBackground: false })).flatten({ background: '#fffaf3' }).toColourspace('srgb').png().toFile(png);
      const meta = await sharp(png).metadata();
      if (meta.width !== 1179 || meta.height !== 2556 || meta.hasAlpha || meta.format !== 'png') throw new Error('Invalid PNG: ' + design.id);
      checks.push({ file: design.id + '.png', width: meta.width, height: meta.height, format: meta.format, alpha: meta.hasAlpha, bounds });
      thumbs.push(await sharp(png).resize(393, 852).toBuffer());
      console.log('Rendered ' + design.id + ': 1179 × 2556');
    }
    await sharp({ create: { width: 1259, height: 2636, channels: 3, background: '#fff9f3' } })
      .composite(thumbs.map((input, index) => ({ input, left: 20 + (index % 3) * 413, top: 20 + Math.floor(index / 3) * 872 })))
      .png().toFile(path.join(root, 'preview.png'));
    fs.writeFileSync(path.join(root, 'verification.json'), JSON.stringify(checks, null, 2));
    fs.writeFileSync(path.join(root, 'README.md'), '# Twinkle Pals: Kids Dress Up — portrait screenshots\n\nNine individual RGB PNG screenshots, each exactly **1179 × 2556 pixels**. Upload files are numbered 01 through 09; `preview.png` is a review contact sheet.\n\nRendered from the original editable portrait HTML compositions using uniform scaling, preserving app captures and character proportions. Includes the current app name. Original exports remain in their existing folders. `verification.json` records dimensions, opacity and layout bounds.\n');
    console.log('Verified all nine portrait screenshots.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
