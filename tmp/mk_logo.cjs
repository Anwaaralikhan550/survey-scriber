const sharp=require('E:/survey-scriber/backend/node_modules/sharp');
(async()=>{
  const src='E:/survey-scriber/assets/icons/app_icon_1024.png';
  const L=258,T=214,S=442; // the logo circle inside the 1024 canvas
  const mask=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}"><circle cx="${S/2}" cy="${S/2}" r="${S/2}"/></svg>`);
  const base=await sharp(src).extract({left:L,top:T,width:S,height:S}).composite([{input:mask,blend:'dest-in'}]).png().toBuffer();
  for (const [out,size] of [['tool/desktop_editor/public/logo.png',192],['tool/phrase_portal/public/logo.png',192],['tool/desktop_editor/public/favicon.png',64],['tool/phrase_portal/public/favicon.png',64]])
    await sharp(base).resize(size,size).png({compressionLevel:9}).toFile('E:/survey-scriber/'+out);
  console.log('ok');
})();
