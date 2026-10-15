const {chromium}=require('/opt/node-tools/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage();
await p.goto('file://'+process.argv[2]);await p.waitForTimeout(1500);
await p.evaluate(()=>document.fonts.ready);
await p.pdf({path:process.argv[3],preferCSSPageSize:true,printBackground:true});
await b.close();})();
