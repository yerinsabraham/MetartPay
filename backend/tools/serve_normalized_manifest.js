#!/usr/bin/env node
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const repoRoot = path.resolve(__dirname, '..');
const normalizedPath = path.join(repoRoot, 'functions_manifest.normalized.json');
const port = process.env.PORT ? Number(process.env.PORT) : 8977;

app.get('/__/functions.yaml', (req, res) => {
  if (!fs.existsSync(normalizedPath)) {
    res.status(500).send('normalized manifest not found');
    return;
  }
  try {
    const s = fs.readFileSync(normalizedPath, 'utf8');
    const j = JSON.parse(s);
    res.setHeader('content-type', 'text/yaml');
    // Serve JSON stringify; emulator expects YAML-like, but previous code served JSON stringified
    res.send(JSON.stringify(j));
  } catch (e) {
    res.status(500).send('failed to read/parse normalized manifest');
  }
});

app.get('/__/quitquitquit', (req, res) => {
  res.send('ok');
  process.exit(0);
});

app.listen(port, () => console.log('Manifest proxy serving at port', port));
