// Reflow the existing editable screenshot designs for a landscape canvas.
const fs = require('fs');
const path = require('path');
const runtime = '/Users/Apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const { chromium } = require(path.join(runtime, 'playwright'));
const sharp = require(path.join(runtime, 'sharp'));
const root = __dirname;
const source = path.join(root, '..', 'kids-avatar-app-store-screens');
const designs = JSON.parse(fs.readFileSync(path.join(source, 'design.json'), 'utf8'));
const esc = value => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
const css = `
html,body,.poster{width:2556px;height:1179px;overflow:hidden}
.app-brand{position:absolute;z-index:1;left:150px;top:95px;color:#68465c;font-size:34px;font-weight:800;letter-spacing:.4px}
.eyebrow{left:150px;top:215px;width:1190px;justify-content:flex-start;gap:16px;font-size:26px;letter-spacing:1.4px}
.eyebrow .logo{width:42px;height:42px}
h1{left:140px;top:305px;width:1200px;text-align:left;font-size:126px;line-height:1.18;letter-spacing:-3px}
.subtitle{left:150px;top:646px;width:1080px;text-align:left;font-size:39px;line-height:1.5}
.divider{left:150px;top:795px;width:1080px;justify-content:flex-start}
.divider:before{width:100px}.divider:after{width:240px}
.footer{left:150px;bottom:185px;width:1180px;text-align:left;font-size:28px;letter-spacing:2px}
.halo{left:1430px;top:63px;width:1030px;height:1060px}
.phone{left:1710px;top:99px;transform:scale(.53);transform-origin:top left}
.pal-0{left:1400px;top:125px;width:260px;transform:rotate(-9deg)}
.pal-1{right:64px;top:120px;width:265px;transform:rotate(9deg)}
.pal-2{left:1390px;top:696px;width:278px;transform:rotate(-9deg)}
.pal-3{right:53px;top:721px;width:280px;transform:rotate(9deg)}
.star.a{left:1355px;top:539px}.star.b{right:92px;top:576px}.star.c{left:160px;top:1035px}
.wash{background:radial-gradient(ellipse at 75% 50%,#ffffff80 0%,#ffffff20 40%,transparent 70%)}
`;

(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
    args: ['--allow-file-access-from-files'],
  });
  try {
    const page = await browser.newPage({ viewport: { width: 2556, height: 1179 }, deviceScaleFactor: 1 });
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
      const bounds = await page.evaluate(() => {
        const selectors = ['.app-brand', '.eyebrow', 'h1', '.subtitle', '.footer', '.phone'];
        return selectors.map(selector => {
          const element = document.querySelector(selector);
          const rect = element.getBoundingClientRect();
          return { selector, x: rect.x, y: rect.y, right: rect.right, bottom: rect.bottom, overflow: element.scrollWidth > element.clientWidth + 1 };
        });
      });
      if (bounds.some(box => box.x < 0 || box.y < 0 || box.right > 2556 || box.bottom > 1179 || box.overflow)) {
        throw new Error(design.id + ': invalid layout ' + JSON.stringify(bounds));
      }
      const png = path.join(root, design.id + '.png');
      const rendered = await page.screenshot({ omitBackground: false });
      await sharp(rendered).flatten({ background: '#fffaf3' }).toColourspace('srgb').png().toFile(png);
      const meta = await sharp(png).metadata();
      if (meta.width !== 2556 || meta.height !== 1179 || meta.hasAlpha || meta.format !== 'png') throw new Error('Invalid PNG: ' + design.id);
      checks.push({ file: design.id + '.png', width: meta.width, height: meta.height, format: meta.format, alpha: meta.hasAlpha, bounds });
      thumbs.push({ id: design.id, buffer: await sharp(png).resize(852, 393).toBuffer() });
      console.log('Rendered ' + design.id + ': 2556 × 1179');
    }
    const tiles = thumbs.map((thumb, index) => ({ input: thumb.buffer, left: 30 + (index % 3) * 882, top: 30 + Math.floor(index / 3) * 423 }));
    await sharp({ create: { width: 2676, height: 1299, channels: 3, background: '#fff9f3' } }).composite(tiles).png().toFile(path.join(root, 'preview.png'));
    fs.writeFileSync(path.join(root, 'verification.json'), JSON.stringify(checks, null, 2));
    fs.writeFileSync(path.join(root, 'README.md'), '# Twinkle Pals: Kids Dress Up — landscape screenshots\n\nNine individual RGB PNG screenshots, each exactly **2556 × 1179 pixels**. Upload files are numbered 01 through 09; `preview.png` is a review contact sheet.\n\nThe existing playful HTML screenshot designs were reflowed for landscape. App captures, artwork and character proportions are preserved. Editable HTML files and `render.cjs` are included here; original portrait exports remain in their existing folders. `verification.json` records dimensions, opacity and layout bounds.\n');
    console.log('Verified all nine screenshots.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
