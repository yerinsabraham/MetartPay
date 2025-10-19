const fs = require('fs');
const yaml = require('js-yaml');
const p = 'c:/Users/PC/metartpay/.github/workflows/integration-simulate.yml';
const s = fs.readFileSync(p,'utf8').split(/\r?\n/);
try {
  yaml.load(s.join('\n'));
  console.log('OK');
} catch (e) {
  console.error('ERROR:', e.message);
  if (e.mark) {
    console.error('mark:', e.mark);
    const L = e.mark.line;
    const start = Math.max(0, L-4);
    const end = Math.min(s.length-1, L+4);
    for (let i=start;i<=end;i++){
      console.error((i+1).toString().padStart(3,' ')+': '+s[i]);
      console.error('   hex:', Buffer.from(s[i]||'','utf8').slice(0,80).toString('hex').match(/.{1,2}/g).join(' '));
    }
  }
  process.exit(1);
}
