const fs = require('fs');
const p = 'c:/Users/PC/metartpay/.github/workflows/integration-simulate.yml';
const s = fs.readFileSync(p);
console.log('Bytes length:', s.length);
const lines = s.toString('utf8').split(/\r?\n/);
for (let i = 0; i < Math.min(lines.length, 120); i++) {
  const line = lines[i];
  // show index, raw characters with escapes for non-printables
  const escaped = line.replace(/\t/g, '\\t').replace(/\r/g, '\\r').replace(/\n/g, '\\n');
  const visible = escaped.replace(/ /g, '·');
  // also show char codes for first 40 chars to detect stray bytes
  const codes = Array.from(Buffer.from(line)).slice(0, 40).map(b => b.toString(16).padStart(2,'0')).join(' ');
  console.log(`${String(i+1).padStart(3,' ')} | ${visible}`);
  console.log(`     chars: ${codes}`);
}
