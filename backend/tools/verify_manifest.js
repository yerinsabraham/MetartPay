#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const manifestPath = path.resolve(__dirname, '..', 'functions_manifest.normalized.json');
function fail(msg) { console.error('MANIFEST-VERIFY ERROR:', msg); process.exit(2); }

if (!fs.existsSync(manifestPath)) {
  fail(`manifest file not found at ${manifestPath}`);
}

let raw = fs.readFileSync(manifestPath, 'utf8');
let j;
try { j = JSON.parse(raw); } catch (e) { fail('invalid JSON: ' + e.message); }

if (!j.specVersion) fail('specVersion missing');
if (!j.endpoints || typeof j.endpoints !== 'object') fail('endpoints missing or not object');
if (!j.endpoints.api) fail('api endpoint missing');
const api = j.endpoints.api;
if (!api.entryPoint) fail('api.entryPoint missing');
if (!api.platform) fail('api.platform missing');
if (!api.region || !Array.isArray(api.region) || api.region.length === 0) fail('api.region missing or invalid');

console.log('Manifest verification OK:', manifestPath);
process.exit(0);
