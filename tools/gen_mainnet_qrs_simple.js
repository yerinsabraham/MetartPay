const QRCode = require('qrcode');
const path = require('path');

async function writeQr(payload, outPath) {
  await QRCode.toFile(outPath, payload, { width: 512, margin: 2 });
  console.log('Wrote QR to', outPath);
}

async function main() {
  if (process.env.ALLOW_MAINNET_QR !== 'true') {
    console.error('Refusing to generate mainnet QR images. Set ALLOW_MAINNET_QR=true to allow this (safety flag).');
    process.exit(2);
  }

  const cfg = require('../backend/config/cluster_mints.json');
  const address = '8eRX87wHexC68X2zg5xkURop1dtC3XcAVHYZJLnPKH7P';

  const addrOnly = `solana:${address}`;
  await writeQr(addrOnly, path.join('tools', 'sol_mainnet_address_only_simple.png'));
  require('fs').writeFileSync(path.join('tools', 'sol_mainnet_address_only_simple.txt'), addrOnly);
  console.log('Address-only payload:', addrOnly);

  if (cfg && cfg.mainnet && cfg.mainnet.USDC) {
    const usdc = `solana:${address}?spl-token=${cfg.mainnet.USDC}&amount=1.5`;
  await writeQr(usdc, path.join('tools', 'sol_mainnet_token_prefill_usdc_simple.png'));
  require('fs').writeFileSync(path.join('tools', 'sol_mainnet_token_prefill_usdc_simple.txt'), usdc);
  console.log('USDC minimal payload:', usdc);
  }

  if (cfg && cfg.mainnet && cfg.mainnet.USDT) {
    const usdt = `solana:${address}?spl-token=${cfg.mainnet.USDT}&amount=1.5`;
  await writeQr(usdt, path.join('tools', 'sol_mainnet_token_prefill_usdt_simple.png'));
  require('fs').writeFileSync(path.join('tools', 'sol_mainnet_token_prefill_usdt_simple.txt'), usdt);
  console.log('USDT minimal payload:', usdt);
  }
}

main().catch(err => { console.error(err); process.exit(1); });
