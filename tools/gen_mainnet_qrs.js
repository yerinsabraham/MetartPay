const QRCode = require('qrcode');
const fs = require('fs');
const crypto = require('crypto');

// Minimal base58 encoder (Bitcoin alphabet)
const ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
function base58Encode(buffer) {
  let carry;
  const digits = [0];
  for (let i = 0; i < buffer.length; ++i) {
    carry = buffer[i];
    for (let j = 0; j < digits.length; ++j) {
      carry += digits[j] << 8; // *256
      digits[j] = carry % 58;
      carry = (carry / 58) | 0;
    }
    while (carry) {
      digits.push(carry % 58);
      carry = (carry / 58) | 0;
    }
  }
  // convert digits to a string
  let string = '';
  // leading zeros
  for (let k = 0; k < buffer.length && buffer[k] === 0; ++k) {
    string += ALPHABET[0];
  }
  for (let q = digits.length - 1; q >= 0; --q) {
    string += ALPHABET[digits[q]];
  }
  return string;
}

async function writeQr(payload, outPath) {
  await QRCode.toFile(outPath, payload, {
    color: { dark: '#000000', light: '#FFFFFF' },
    margin: 2,
    width: 512,
  });
  console.log('Wrote QR to', outPath);
}

async function main() {
  if (process.env.ALLOW_MAINNET_QR !== 'true') {
    console.error('Refusing to generate mainnet QR images. Set ALLOW_MAINNET_QR=true to allow this (safety flag).');
    process.exit(2);
  }

  // Test address (use the same address used in devnet generator for parity)
  const address = '8eRX87wHexC68X2zg5xkURop1dtC3XcAVHYZJLnPKH7P';

  // Read mainnet mints from backend config
  let mainnetUsdc = null;
  let mainnetUsdt = null;
  try {
    const m = require('../backend/config/cluster_mints.json');
    if (m && m.mainnet) {
      mainnetUsdc = m.mainnet.USDC || null;
      mainnetUsdt = m.mainnet.USDT || null;
    }
  } catch (e) {
    // ignore
  }

  if (!mainnetUsdc && !mainnetUsdt) {
    console.error('No mainnet mints found in backend/config/cluster_mints.json');
    process.exit(3);
  }

  // Generate a fresh 32-byte reference
  const refBytes = crypto.randomBytes(32);
  const reference = base58Encode(refBytes);

  const addrOnly = `solana:${address}`;

  if (mainnetUsdc) {
    const usdcPrefill = `solana:${address}?spl-token=${mainnetUsdc}&amount=1.5&reference=${reference}`;
    await writeQr(usdcPrefill, 'tools/sol_mainnet_token_prefill_usdc.png');
    console.log('Mainnet USDC token-prefill payload:', usdcPrefill);
  }

  if (mainnetUsdt) {
    const usdtPrefill = `solana:${address}?spl-token=${mainnetUsdt}&amount=1.5&reference=${reference}`;
    await writeQr(usdtPrefill, 'tools/sol_mainnet_token_prefill_usdt.png');
    console.log('Mainnet USDT token-prefill payload:', usdtPrefill);
  }

  // Compatibility variant: include both spl-token and legacy token param (USDC used if present)
  const compatMint = mainnetUsdc || mainnetUsdt;
  if (compatMint) {
    const compatPrefill = `solana:${address}?spl-token=${compatMint}&token=${compatMint}&amount=1.5&reference=${reference}`;
    await writeQr(compatPrefill, 'tools/sol_mainnet_token_prefill_compat.png');
    console.log('Mainnet compatibility payload (spl-token + token):', compatPrefill);
  }

  // Always write address-only last
  await writeQr(addrOnly, 'tools/sol_mainnet_address_only.png');
  console.log('Mainnet address-only payload:', addrOnly);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
