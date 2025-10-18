const QRCode = require('qrcode');
const fs = require('fs');

async function generate(payload, outPath) {
  try {
    await QRCode.toFile(outPath, payload, {
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      },
      margin: 2,
      width: 512
    });
    console.log('Wrote QR to', outPath);
  } catch (err) {
    console.error('Failed to generate QR', err);
    process.exit(1);
  }
}

const payload = process.argv[2] || 'solana:DevSolTestWallet11111111111111111111111111111?amount=0.05';
const out = process.argv[3] || 'tools/sol_qr.png';

generate(payload, out);
