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
  // Replace the address with the one you used for testing
  const address = '8eRX87wHexC68X2zg5xkURop1dtC3XcAVHYZJLnPKH7P';
  // Placeholder devnet token mint - replace if you have a real devnet mint
  // Try to read the devnet mint from backend/config/cluster_mints.json if present
  let devnetMint = 'DevnetUSDC11111111111111111111111111111';
  try {
    const m = require('../backend/config/cluster_mints.json');
    if (m && m.devnet && m.devnet.USDC) {
      devnetMint = m.devnet.USDC;
    }
  } catch (e) {
    // ignore and use placeholder
  }

  // Generate 32 random bytes and base58-encode them
  const refBytes = crypto.randomBytes(32);
  const reference = base58Encode(refBytes);

  const addrOnly = `solana:${address}`;
  const tokenPrefill = `solana:${address}?spl-token=${devnetMint}&amount=1.5&reference=${reference}`;

  // Build USDT variant if available
  let usdtPrefill = null;
  try {
    const m = require('../backend/config/cluster_mints.json');
    if (m && m.devnet && m.devnet.USDT) usdtPrefill = `solana:${address}?spl-token=${m.devnet.USDT}&amount=1.5&reference=${reference}`;
  } catch (e) { /* ignore */ }

  // Compatibility variant: include both spl-token and legacy token param
  const compatPrefill = `solana:${address}?spl-token=${devnetMint}&token=${devnetMint}&amount=1.5&reference=${reference}`;

  await writeQr(addrOnly, 'tools/sol_devnet_address_only.png');
  console.log('Address-only payload:', addrOnly);

  await writeQr(tokenPrefill, 'tools/sol_devnet_token_prefill.png');
  console.log('Token-prefill payload (USDC):', tokenPrefill);

  if (usdtPrefill) {
    await writeQr(usdtPrefill, 'tools/sol_devnet_token_prefill_usdt.png');
    console.log('Token-prefill payload (USDT):', usdtPrefill);
  }

  await writeQr(compatPrefill, 'tools/sol_devnet_token_prefill_compat.png');
  console.log('Compatibility payload (spl-token + token):', compatPrefill);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
