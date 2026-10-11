const fs=require('fs'),path=require('path');
const old=path.join(__dirname,'..','app-store-screenshots');
const designs=JSON.parse(fs.readFileSync(path.join(old,'design.json')));
const updates=[
 [['Dress up.','Dream big!'],'A little world of outfits, friends & fun.','LET’S MAKE A LITTLE MAGIC!','STYLE • PLAY • SMILE',['poppy','luna','zara-pink','cleo-wings'],'#bf3f7c','#fbddeb'],
 [['Say hello to','your new pals!'],'Meet 12 original friends with their own sparkle.','MEET YOUR NEW BESTIES','12 ORIGINAL PALS',['cleo-wings','zara-pink','luna-party','milo'],'#9760c8','#e9ddfb'],
 [['Your style.','Your sparkle!'],'Pick the hair, clothes & colors you love.','MADE FOR YOUR IMAGINATION','MIX, MATCH & CREATE',['ivy-cool','luna-party','cleo-wings','poppy'],'#9c65cf','#e6d9fa'],
 [['Little pals.','Big adventures!'],'Style, play & collect happy memories.','READY FOR A LITTLE ADVENTURE?','6 STORY ADVENTURES',['kai','nova','sunny','finn'],'#b88022','#ffebbc'],
 [['Let’s dress','for adventure!'],'A flower crown. A bunny bag. Picnic time!','YOUR STORY STARTS WITH STYLE','STYLE YOUR PAL',['ivy-picnic','poppy','cleo-wings','luna'],'#4c927f','#d7f1df'],
 [['Find flowers.','Grow smiles!'],'Help Poppy make a lovely picnic bouquet.','LET’S GO ON A BLOOM HUNT','PLAY & DISCOVER',['ivy-picnic','poppy','sunny','cleo-wings'],'#469784','#d8f0df'],
 [['Hooray for','happy friends!'],'Pick a keepsake for your adventure book.','TIME TO CELEBRATE TOGETHER','MAKE A HAPPY MEMORY',['luna-party','ivy-picnic','poppy','zara-pink'],'#c94c81','#fbdce7'],
 [['You did it!','Time to sparkle!'],'Earn stars & discover lovely outfit gifts.','LITTLE WINS, BIG SMILES','STARS & OUTFIT GIFTS',['cleo-wings','luna-party','nova','ivy-picnic'],'#bb8225','#ffedc9'],
 [['Your pals.','All together!'],'Save your favorite looks & style them again.','YOUR LITTLE CIRCLE OF FRIENDS','SAVE THE LOOKS YOU LOVE',['ivy-cool','zara-pink','luna','milo'],'#bd559e','#ecdff8']
];
for(let i=0;i<designs.length;i++){const [title,subtitle,label,footer,avatars,accent,wash]=updates[i];Object.assign(designs[i],{title,subtitle,label,footer,avatars,accent,wash});}
fs.writeFileSync(path.join(__dirname,'design.json'),JSON.stringify(designs,null,2));
let render=fs.readFileSync(path.join(old,'render.cjs'),'utf8');
render=render.replace("'pearl-garden-background.png'","'candy-clouds-background.png'");
render=render.replace("sc=852/cw", "sc=800/cw");
render=render.replace("function html(d,img,meta,bg){",`function html(d,img,meta,bg){
 const avatarImages=d.avatars.map(n=>dataURI(path.join(root,'assets','avatars',n+'.png')));
 const stickerHTML=avatarImages.map((src,i)=>'<div class="pal pal-'+i+'"><img src="'+src+'"></div>').join('');`);
render=render.replace('@font-face{font-family:Athelas;', '@font-face{font-family:Athelas;');
render=render.replace('<style>\n',`<style>
 @font-face{font-family:Rounded;src:url('file:///System/Library/Fonts/Supplemental/Arial%20Rounded%20Bold.ttf')}
`);
render=render.replace('.art{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.86}', '.art{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:1}');
render=render.replace('.grain{position:', '.grain{display:none;position:');
render=render.replace('.eyebrow{position:absolute;top:101px;', '.eyebrow{position:absolute;top:91px;');
render=render.replace('font-size:26px;font-weight:600;letter-spacing:5.4px','font-size:25px;font-weight:800;letter-spacing:2.6px');
render=render.replace('color:#84654d','color:#7c567d');
render=render.replace("font-family:Athelas,Georgia,serif;font-size:121px;font-weight:500;line-height:1.045;letter-spacing:-3.9px", "font-family:Rounded,'Arial Rounded MT Bold',Arial,sans-serif;font-size:110px;font-weight:700;line-height:1.16;letter-spacing:-3.8px;-webkit-text-stroke:12px #fffaf8;paint-order:stroke fill;filter:drop-shadow(0px 7px 0px #6742670c)");
render=render.replace('font-style:italic;color:', 'font-style:normal;color:');
render=render.replace('top:494px;left:136px;width:1048px','top:504px;left:256px;width:808px');
render=render.replace('font-size:36px;line-height:1.5;font-weight:400','font-size:35px;line-height:1.48;font-weight:500');
render=render.replace('top:626px','top:663px');
render=render.replace('color:#c5a36a;font-size:25px','color:${d.accent};font-size:41px');
render=render.replace('top:1020px;left:76px;width:1168px;height:1450px;border:1.5px solid #d1b07f55','top:910px;left:117px;width:1086px;height:1590px;border:3px dashed #ffffffb0');
render=render.replace('inset:25px;border:1px solid #d1b07f25','inset:25px;border:1px solid #ffffff80');
render=render.replace('top:744px;left:206px;width:908px;padding:18px;background:linear-gradient(110deg,#a28773,#fff3db 24%,#c3ab98 48%,#fcebd2 65%,#846954);border-radius:166px;box-shadow:0 39px 68px #79607629,0 9px 14px #51392b20;z-index:2', 'top:847px;left:232px;width:856px;padding:18px;background:linear-gradient(135deg,#ffffff,#ffffff 50%,${d.wash});border-radius:154px;box-shadow:0 35px 0 -15px ${d.accent}20,0 42px 68px #74528d2c,0 0 0 3px #ffffff;z-index:3');
render=render.replace('border-radius:148px','border-radius:136px').replace('width:852px','width:800px').replace('border-radius:138px','border-radius:126px');
render=render.replace('color:#8a6d61;font-size:22px;letter-spacing:4px;font-weight:500', 'color:#735475;font-size:27px;letter-spacing:2px;font-weight:800');
render=render.replace('.star.a{left:128px;top:805px}.star.b{right:107px;top:1750px;font-size:40px}.star.c{left:107px;top:2305px;font-size:31px}', '.star.a{left:107px;top:956px;color:#ecb733;font-size:65px}.star.b{right:75px;top:1900px;color:#b88ae2;font-size:58px}.star.c{left:90px;top:2245px;color:#f392b4;font-size:47px}');
render=render.replace(' </style>',` .pal{position:absolute;z-index:2;pointer-events:none}.pal img{width:100%;height:auto;filter:drop-shadow(0 4px 0 #fff) drop-shadow(3px 0 0 #fff) drop-shadow(-3px 0 0 #fff) drop-shadow(0 -3px 0 #fff) drop-shadow(0 12px 10px #73527a18)}
 .pal-0{left:1px;top:460px;width:258px;transform:rotate(-9deg)}
 .pal-1{right:1px;top:470px;width:258px;transform:rotate(9deg)}
 .pal-2{left:-17px;top:1510px;width:265px;transform:rotate(-12deg)}
 .pal-3{right:-17px;top:2120px;width:265px;transform:rotate(12deg)}
 </style>`);
render=render.replace('<div class="halo"></div>', '<div class="halo"></div>${stickerHTML}');
render=render.replace('transform:scale(.9409090909,.9372384937)', 'transform:scale(.9372384937);margin-left:2.4px');
render=render.replace('A little world of wonder.', 'Little pals. Big imagination.').replace('Pearl, pastels & a little magic','Original app avatars, candy colors & happy little adventures');
render=render.replace('height:3600','height:3300');
fs.writeFileSync(path.join(__dirname,'render.cjs'),render);
fs.copyFileSync(path.join(old,'verify.cjs'),path.join(__dirname,'verify.cjs'));
