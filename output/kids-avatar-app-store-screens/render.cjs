const fs=require('fs');
const path=require('path');
const {chromium}=require('/Users/Apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const sharp=require('/Users/Apple/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=__dirname;
const designs=JSON.parse(fs.readFileSync(path.join(root,'design.json'),'utf8'));
const dataURI=p=>'data:image/png;base64,'+fs.readFileSync(p).toString('base64');
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const flower=`<svg viewBox="0 0 80 80" aria-hidden="true"><g fill="currentColor"><ellipse cx="40" cy="23" rx="11" ry="17"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(72 40 40)"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(144 40 40)"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(216 40 40)"/><ellipse cx="40" cy="23" rx="11" ry="17" transform="rotate(288 40 40)"/></g><circle cx="40" cy="40" r="9" fill="#d9b975"/></svg>`;
function html(d,img,meta,bg){
 const avatarImages=d.avatars.map(n=>dataURI(path.join(root,'assets','avatars',n+'.png')));
 const stickerHTML=avatarImages.map((src,i)=>'<div class="pal pal-'+i+'"><img src="'+src+'"></div>').join('');
 const [cx,cy,cw,ch]=d.crop, sc=800/cw, ih=ch*sc;
 return `<!doctype html><html><head><meta charset="utf-8"><style>
 @font-face{font-family:Rounded;src:url('file:///System/Library/Fonts/Supplemental/Arial%20Rounded%20Bold.ttf')}
 @font-face{font-family:Athelas;src:url('file:///System/Library/Fonts/Supplemental/Athelas.ttc')}
 *{box-sizing:border-box}html,body{margin:0;width:1320px;height:2868px}body{color:#503448;background:#fff9f1;font-family:'Avenir Next',Arial,sans-serif}
 .poster{position:relative;width:1320px;height:2868px;overflow:hidden;background:#fffaf3}
 .art{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:1}
 .wash{position:absolute;inset:0;background:radial-gradient(ellipse at 50% 66%,${d.wash}c9 0%,${d.wash}40 34%,transparent 65%)}
 .grain{display:none;position:absolute;inset:0;opacity:.11;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='180' height='180'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.6' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' opacity='.3' filter='url(%23n)'/%3E%3C/svg%3E")}
 .eyebrow{position:absolute;top:91px;left:0;width:100%;display:flex;align-items:center;justify-content:center;gap:24px;color:#7c567d;font-size:25px;font-weight:800;letter-spacing:2.6px}
 .eyebrow .logo{width:48px;height:48px;color:${d.accent}}
 h1{position:absolute;margin:0;top:207px;left:50px;width:1220px;text-align:center;font-family:Rounded,'Arial Rounded MT Bold',Arial,sans-serif;font-size:110px;font-weight:700;line-height:1.16;letter-spacing:-3.8px;-webkit-text-stroke:12px #fffaf8;paint-order:stroke fill;filter:drop-shadow(0px 7px 0px #6742670c)}
 h1 em{font-style:normal;color:${d.accent}}
 .subtitle{position:absolute;top:504px;left:256px;width:808px;margin:0;text-align:center;font-size:35px;line-height:1.48;font-weight:500;color:#816577;letter-spacing:.15px}
 .divider{position:absolute;top:663px;left:0;width:100%;display:flex;align-items:center;justify-content:center;gap:20px;color:${d.accent};font-size:41px}
 .divider:before,.divider:after{content:'';height:1px;width:95px;background:linear-gradient(to right,transparent,#d4ba89)}.divider:after{transform:rotate(180deg)}
 .halo{position:absolute;top:910px;left:117px;width:1086px;height:1590px;border:3px dashed #ffffffb0;border-radius:50%}
 .halo:after{content:'';position:absolute;inset:25px;border:1px solid #ffffff80;border-radius:50%}
 .phone{position:absolute;top:847px;left:232px;width:856px;padding:18px;background:linear-gradient(135deg,#ffffff,#ffffff 50%,${d.wash});border-radius:154px;box-shadow:0 35px 0 -15px ${d.accent}20,0 42px 68px #74528d2c,0 0 0 3px #ffffff;z-index:3}
 .bezel{padding:10px;background:#151216;border-radius:136px}
 .screen{position:relative;width:800px;height:${ih}px;overflow:hidden;border-radius:126px;background:#fff8f3}
 .screen img{position:absolute;width:${meta.width*sc}px;height:${meta.height*sc}px;max-width:none;left:${-cx*sc}px;top:${-cy*sc}px}
 .footer{position:absolute;bottom:73px;left:0;width:100%;text-align:center;color:#735475;font-size:27px;letter-spacing:2px;font-weight:800}
 .star{position:absolute;color:#c7a26a;font:54px Georgia;opacity:.7;z-index:1}
 .star.a{left:107px;top:956px;color:#ecb733;font-size:65px}.star.b{right:75px;top:1900px;color:#b88ae2;font-size:58px}.star.c{left:90px;top:2245px;color:#f392b4;font-size:47px}
 .pal{position:absolute;z-index:2;pointer-events:none}.pal img{width:100%;height:auto;filter:drop-shadow(0 4px 0 #fff) drop-shadow(3px 0 0 #fff) drop-shadow(-3px 0 0 #fff) drop-shadow(0 -3px 0 #fff) drop-shadow(0 12px 10px #73527a18)}
 .pal-0{left:1px;top:460px;width:258px;transform:rotate(-9deg)}
 .pal-1{right:1px;top:470px;width:258px;transform:rotate(9deg)}
 .pal-2{left:-17px;top:1510px;width:265px;transform:rotate(-12deg)}
 .pal-3{right:-17px;top:2120px;width:265px;transform:rotate(12deg)}
 </style></head><body><main class="poster"><img class="art" src="${bg}"><div class="wash"></div><div class="grain"></div><div class="eyebrow"><span class="logo">${flower}</span>${esc(d.label)}</div><h1>${esc(d.title[0])}<br><em>${esc(d.title[1])}</em></h1><p class="subtitle">${esc(d.subtitle)}</p><div class="divider">✦</div><div class="halo"></div>${stickerHTML}<span class="star a">✦</span><span class="star b">✧</span><span class="star c">✦</span><div class="phone"><div class="bezel"><div class="screen"><img src="${img}"></div></div></div><div class="footer">${esc(d.footer)}</div></main></body></html>`;
}
(async()=>{
 const bgFile=path.join(root,'assets','candy-clouds-background.png');
 const bg=fs.existsSync(bgFile)?dataURI(bgFile):'data:image/svg+xml,'+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="1320" height="2868"><rect width="1320" height="2868" fill="#fffaf3"/></svg>');
 const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,args:['--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1320,height:2868},deviceScaleFactor:1});
 const overview=[];
 for(const d of designs){
  const src=path.join(root,'assets',d.id+'-source.png');
  if(!fs.existsSync(src))fs.copyFileSync('/Users/Apple/Desktop/Screenshot 2026-10-09 at '+d.time+' PM.png',src);
  const meta=await sharp(src).metadata();
  const doc=html(d,dataURI(src),meta,bg); const htmlPath=path.join(root,d.id+'.html');fs.writeFileSync(htmlPath,doc);
  await page.goto('file://'+htmlPath);await page.evaluate(()=>document.fonts.ready);await page.waitForFunction(()=>[...document.images].every(i=>i.complete));
  const overflow=await page.locator('h1').evaluate(e=>({width:e.scrollWidth,box:e.clientWidth}));if(overflow.width>overflow.box)throw new Error(d.id+' heading overflow');
  const out=path.join(root,'iphone-6.9',d.id+'.png');await page.screenshot({path:out,omitBackground:false});
  // A second code-native render uses the same layout, scaled to Apple's 6.5-inch size.
  await page.setViewportSize({width:1242,height:2688});await page.addStyleTag({content:'html,body{width:1242px;height:2688px;overflow:hidden}.poster{transform-origin:0 0;transform:scale(.9372384937);margin-left:2.4px}'});
  await page.screenshot({path:path.join(root,'iphone-6.5',d.id+'.png'),omitBackground:false});await page.setViewportSize({width:1320,height:2868});
  console.log('Rendered '+d.id);
  overview.push({d,src:out});
 }
 const cards=overview.map(({d,src})=>`<figure><img src="${dataURI(src)}"><figcaption>${d.id.replaceAll('-',' ')}</figcaption></figure>`).join('');
 const gallery=`<!doctype html><meta charset="utf-8"><style>body{background:#fff9f2;margin:0;padding:70px;color:#503448;font-family:'Avenir Next',Arial}h1{font-family:Athelas,Georgia;font-size:58px;margin:0 0 10px;font-weight:500}p{font-size:23px;color:#8b687b;margin:0 0 46px}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:40px 36px}figure{margin:0}img{display:block;width:100%;border-radius:18px;box-shadow:0 10px 28px #6f45621a}figcaption{font-size:18px;color:#8c6978;padding:16px 4px;text-transform:capitalize}</style><h1>Little pals. Big imagination.</h1><p>App Store screenshot collection · Original app avatars, candy colors & happy little adventures</p><div class="grid">${cards}</div>`;
 fs.writeFileSync(path.join(root,'preview.html'),gallery);await page.setViewportSize({width:1500,height:3300});await page.goto('file://'+path.join(root,'preview.html'));await page.evaluate(()=>document.fonts.ready);await page.screenshot({path:path.join(root,'preview.png'),fullPage:true});
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
