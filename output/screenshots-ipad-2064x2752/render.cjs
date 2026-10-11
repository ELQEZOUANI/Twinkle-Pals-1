// Compose real Flutter iPad captures inside a portrait iPad device frame.
const fs = require('fs');
const path = require('path');
const runtime = '/Users/Apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const { chromium } = require(path.join(runtime, 'playwright'));
const sharp = require(path.join(runtime, 'sharp'));
const root = __dirname;
const originals = path.join(root, '..', 'kids-avatar-app-store-screens');
const designs = JSON.parse(fs.readFileSync(path.join(originals, 'design.json'), 'utf8'));
const data = file => 'data:image/png;base64,' + fs.readFileSync(file).toString('base64');
const esc = value => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
const flower = '<svg viewBox="0 0 80 80" aria-hidden="true"><g fill="currentColor"><ellipse cx="40" cy="23" rx="11" ry="17"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(72 40 40)"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(144 40 40)"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(216 40 40)"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(288 40 40)"/></g><circle cx="40" cy="40" r="9" fill="#d9b975"/></svg>';
const background = data(path.join(originals, 'assets', 'candy-clouds-background.png'));
function composition(design) {
  const avatars = design.avatars.map((name, index) => `<div class="pal pal-${index}"><img src="${data(path.join(originals, 'assets', 'avatars', name + '.png'))}" alt=""></div>`).join('');
  const capture = data(path.join(root, 'assets', design.id + '.png'));
  return `<!doctype html><html><head><meta charset="utf-8"><style>
@font-face{font-family:Rounded;src:url('file:///System/Library/Fonts/Supplemental/Arial%20Rounded%20Bold.ttf')}
*{box-sizing:border-box}html,body{margin:0;width:2064px;height:2752px;overflow:hidden}
body{color:#503448;background:#fffaf3;font-family:'Avenir Next',Arial,sans-serif}
.poster{position:relative;width:2064px;height:2752px;overflow:hidden}
.art{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
.wash{position:absolute;inset:0;background:radial-gradient(ellipse at 50% 65%,${design.wash}c9,${design.wash}30 55%,transparent 85%)}
.app-brand{position:absolute;top:63px;left:100px;width:1864px;text-align:center;font-size:35px;font-weight:800;color:#68465c;letter-spacing:.4px}
.eyebrow{position:absolute;top:158px;left:100px;width:1864px;display:flex;align-items:center;justify-content:center;gap:24px;font-size:30px;font-weight:800;letter-spacing:2px;color:#7c567d}
.logo{width:48px;height:48px;color:${design.accent}}
h1{position:absolute;top:248px;left:100px;width:1864px;margin:0;text-align:center;font-family:Rounded,'Arial Rounded MT Bold',Arial,sans-serif;font-size:143px;line-height:1.14;letter-spacing:-3.8px;-webkit-text-stroke:13px #fffaf8;paint-order:stroke fill}
h1 em{font-style:normal;color:${design.accent}}
.subtitle{position:absolute;left:232px;top:605px;width:1600px;margin:0;text-align:center;font-size:44px;line-height:1.48;font-weight:500;color:#816577}
.halo{position:absolute;left:107px;top:735px;width:1850px;height:1920px;border:3px dashed #ffffffb0;border-radius:50%}
.tablet{position:absolute;left:332px;top:770px;width:1400px;padding:28px;background:linear-gradient(135deg,#fff,#f8f4f7 55%,#ddd5df);border-radius:62px;box-shadow:0 24px 0 -10px ${design.accent}28,0 35px 75px #74528d35,0 0 0 3px #d9d2db;z-index:3}
.camera{position:absolute;left:calc(50% - 5px);top:11px;width:10px;height:10px;border-radius:50%;background:#373039;box-shadow:inset 0 0 0 3px #5b515f}
.bezel{padding:12px;background:#171219;border-radius:48px}
.screen{width:1320px;height:1760px;overflow:hidden;border-radius:36px;background:#fff8f3}
.screen img{display:block;width:100%;height:100%;object-fit:contain}
.pal{position:absolute;z-index:2;pointer-events:none}.pal img{display:block;width:100%;height:auto;filter:drop-shadow(0 4px 0 #fff) drop-shadow(3px 0 0 #fff) drop-shadow(-3px 0 0 #fff) drop-shadow(0 -3px 0 #fff) drop-shadow(0 12px 10px #73527a18)}
.pal-0{left:46px;top:479px;width:264px;transform:rotate(-9deg)}
.pal-1{right:46px;top:489px;width:264px;transform:rotate(9deg)}
.pal-2{left:30px;top:1995px;width:292px;transform:rotate(-9deg)}
.pal-3{right:30px;top:2120px;width:292px;transform:rotate(9deg)}
.star{position:absolute;font:64px Georgia;color:#ecb733;opacity:.8}.star.a{left:117px;top:1060px}.star.b{right:84px;top:1530px;color:#b88ae2}.star.c{left:99px;top:2490px;color:#f392b4}
.footer{position:absolute;bottom:48px;left:100px;width:1864px;text-align:center;font-size:30px;font-weight:800;letter-spacing:2.2px;color:#735475}
</style></head><body><main class="poster"><img class="art" src="${background}" alt=""><div class="wash"></div><div class="app-brand">Twinkle Pals: Kids Dress Up</div><div class="eyebrow"><span class="logo">${flower}</span>${esc(design.label)}</div><h1>${esc(design.title[0])}<br><em>${esc(design.title[1])}</em></h1><p class="subtitle">${esc(design.subtitle)}</p><div class="halo"></div>${avatars}<span class="star a">✦</span><span class="star b">✧</span><span class="star c">✦</span><div class="tablet"><div class="camera"></div><div class="bezel"><div class="screen"><img src="${capture}" alt="Actual Twinkle Pals iPad app layout"></div></div></div><div class="footer">${esc(design.footer)}</div></main></body></html>`;
}

(async () => {
  const browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--allow-file-access-from-files'] });
  try {
    const page = await browser.newPage({ viewport: { width: 2064, height: 2752 }, deviceScaleFactor: 1 });
    const verification = [];
    const thumbnails = [];
    for (const design of designs) {
      const html = path.join(root, design.id + '.html');
      fs.writeFileSync(html, composition(design));
      await page.goto('file://' + html);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForFunction(() => [...document.images].every(image => image.complete && image.naturalWidth > 0));
      const bounds = await page.evaluate(() => ['.app-brand', '.eyebrow', 'h1', '.subtitle', '.tablet', '.footer'].map(selector => {
        const element = document.querySelector(selector);
        const box = element.getBoundingClientRect();
        return { selector, x: box.x, y: box.y, right: box.right, bottom: box.bottom, overflow: element.scrollWidth > element.clientWidth + 1 };
      }));
      if (bounds.some(box => box.x < 0 || box.y < 0 || box.right > 2064 || box.bottom > 2752 || box.overflow)) throw new Error(design.id + ': invalid layout ' + JSON.stringify(bounds));
      const png = path.join(root, design.id + '.png');
      await sharp(await page.screenshot({ omitBackground: false })).flatten({ background: '#fffaf3' }).toColourspace('srgb').png().toFile(png);
      const metadata = await sharp(png).metadata();
      if (metadata.width !== 2064 || metadata.height !== 2752 || metadata.hasAlpha) throw new Error('Invalid PNG: ' + design.id);
      verification.push({ file: design.id + '.png', width: metadata.width, height: metadata.height, alpha: metadata.hasAlpha, format: metadata.format, source: 'Actual Flutter iPad capture', bounds });
      thumbnails.push(await sharp(png).resize(516, 688).toBuffer());
      console.log('Rendered ' + design.id + ': iPad, 2064 × 2752');
    }
    await sharp({ create: { width: 1628, height: 2144, channels: 3, background: '#fff9f3' } })
      .composite(thumbnails.map((input, index) => ({ input, left: 20 + (index % 3) * 536, top: 20 + Math.floor(index / 3) * 708 })))
      .png().toFile(path.join(root, 'preview.png'));
    fs.writeFileSync(path.join(root, 'verification.json'), JSON.stringify(verification, null, 2));
    fs.writeFileSync(path.join(root, 'README.md'), '# Twinkle Pals: Kids Dress Up — iPad screenshots\n\nNine numbered RGB PNGs at exactly **2064 × 2752 pixels**, with portrait iPad device frames and real captures of the current Flutter iPad layouts. `preview.png` is a contact sheet for review.\n\nThe pastel backgrounds, original avatar stickers, headlines and subtitles match the previous collection. iPad captures use 1032 × 1376 logical pixels, exported at 2×, and are displayed at their original 3:4 aspect ratio inside the tablet frame. No phone screens are stretched into a tablet. Demo progress and saved pals are confined to the capture tool’s mocked storage; production app code is unchanged.\n\nTo reproduce captures: `flutter test output/screenshots-ipad-2064x2752/capture_ipad_test.dart`. Then run `render.cjs` using the bundled Node runtime. Editable HTML and dimension/layout verification are included.\n');
    console.log('Verified all nine iPad screenshots.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
