#!/usr/bin/env node
/*
 normalize_manifest.js
 Read backend/functions_manifest.json, transform fields that the emulator may reject
 and write a normalized manifest to backend/functions_manifest.normalized.json

 Transformations applied:
 - Remove any non-JSON-serializable values
 - Convert numeric-like strings or BigInt-like values to strings
 - Ensure endpoints object exists and specVersion is present
 - Strip unknown top-level fields that emulators don't expect

 This is a conservative transformer — it preserves as much as possible while
 ensuring the shape is plain JSON compatible.
*/
const fs = require('fs');
const path = require('path');

function sanitizeValue(v) {
  if (v === undefined) return null;
  if (v === null) return null;
  if (typeof v === 'bigint') return v.toString();
  if (typeof v === 'number') {
    if (!Number.isFinite(v)) return String(v);
    return v;
  }
  if (typeof v === 'string') return v;
  if (Array.isArray(v)) return v.map(sanitizeValue);
  if (typeof v === 'object') return sanitizeObject(v);
  if (typeof v === 'boolean') return v;
  return String(v);
}

function sanitizeObject(obj) {
  const out = {};
  for (const [k, vv] of Object.entries(obj || {})) {
    try {
      out[k] = sanitizeValue(vv);
    } catch (e) {
      out[k] = String(vv);
    }
  }
  return out;
}

function normalize(manifest) {
  const out = {};
  // Keep specVersion if present, otherwise set to v1alpha1 which emulator expects
  out.specVersion = manifest.specVersion || 'v1alpha1';
  // endpoints should be an object keyed by name
  out.endpoints = {};
  if (manifest.endpoints && typeof manifest.endpoints === 'object') {
    for (const [name, endpoint] of Object.entries(manifest.endpoints)) {
      out.endpoints[name] = sanitizeObject(endpoint);
    }
  }
  // Keep top-level metadata that is safe
  if (manifest.projectId) out.projectId = String(manifest.projectId);
  if (manifest.buildSystem) out.buildSystem = String(manifest.buildSystem);
  return out;
}

function main() {
  const repoRoot = path.resolve(__dirname, '..');
  const manifestPath = path.join(repoRoot, 'functions_manifest.json');
  const outPath = path.join(repoRoot, 'functions_manifest.normalized.json');
  if (!fs.existsSync(manifestPath)) {
    console.error('manifest not found at', manifestPath);
    process.exit(2);
  }
  let raw = fs.readFileSync(manifestPath, 'utf8');
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (e) {
    console.error('Failed to parse manifest JSON:', e && e.stack || e);
    process.exit(2);
  }
  const normalized = normalize(parsed);
  fs.writeFileSync(outPath, JSON.stringify(normalized, null, 2));
  console.log('Wrote normalized manifest to', outPath);
}

if (require.main === module) main();
