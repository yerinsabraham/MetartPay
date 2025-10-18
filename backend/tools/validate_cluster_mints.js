#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const bs58 = require('bs58');
const fetch = global.fetch || require('node-fetch');

// Usage: node tools/validate_cluster_mints.js [--rpc <solanaRpcUrl>]

const args = process.argv.slice(2);
let rpcUrl = null;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--rpc' && args[i+1]) {
    rpcUrl = args[i+1];
    i++;
  }
}

const cfgPath = path.resolve(__dirname, '..', 'config', 'cluster_mints.json');
if (!fs.existsSync(cfgPath)) {
  console.error('cluster_mints.json not found at', cfgPath);
  process.exit(2);
}

const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));

async function checkMint(cluster, token, mint) {
  const result = { cluster, token, mint, ok: true, errors: [] };

  if (!mint || typeof mint !== 'string' || mint.trim() === '') {
    result.ok = false;
    result.errors.push('empty value');
    return result;
  }

  // Placeholder detection
  if (mint.includes('<') || mint.includes('replace') || mint.includes('REPLACE')) {
    result.ok = false;
    result.errors.push('placeholder or not replaced');
    return result;
  }

  // Test base58 decode
  try {
    const decoded = bs58.decode(mint);
    if (decoded.length !== 32) {
      result.ok = false;
      result.errors.push(`decoded length ${decoded.length} != 32`);
    }
  } catch (e) {
    result.ok = false;
    result.errors.push('not valid base58: ' + (e && e.message));
    return result;
  }

  // Optionally check RPC existence (Solana getAccountInfo)
  if (rpcUrl) {
    try {
      const body = { jsonrpc: '2.0', id: 1, method: 'getAccountInfo', params: [mint, { encoding: 'base64' }] };
      const resp = await fetch(rpcUrl, { method: 'POST', body: JSON.stringify(body), headers: { 'Content-Type': 'application/json' }, timeout: 8000 });
      const j = await resp.json();
      if (!j || !j.result) {
        result.ok = false;
        result.errors.push('RPC returned no result');
      } else if (j.result.value === null) {
        result.errors.push('RPC: account does not exist (value=null)');
      }
    } catch (e) {
      result.errors.push('RPC check failed: ' + (e && e.message));
    }
  }

  return result;
}

async function main() {
  const results = [];
  for (const cluster of Object.keys(cfg)) {
    const tokens = cfg[cluster] || {};
    for (const token of Object.keys(tokens)) {
      const mint = tokens[token];
      // run checks
      // eslint-disable-next-line no-await-in-loop
      const r = await checkMint(cluster, token, mint);
      results.push(r);
    }
  }

  const okCount = results.filter(r => r.ok).length;
  console.log(`Checked ${results.length} mappings, ${okCount} OK, ${results.length - okCount} issues`);
  for (const r of results) {
    if (!r.ok || (r.errors && r.errors.length)) {
      console.log(`- ${r.cluster}/${r.token}: ${r.mint} => ${r.ok ? 'OK' : 'INVALID'} ${r.errors.length ? ' - ' + r.errors.join('; ') : ''}`);
    }
  }

  if (results.some(r => !r.ok)) process.exitCode = 3;
}

main().catch(err => { console.error(err); process.exit(1); });
