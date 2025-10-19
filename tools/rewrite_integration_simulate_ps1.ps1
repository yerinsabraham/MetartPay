# Overwrite the integration-simulate.yml using a PowerShell here-string and write UTF8 without BOM.
# Usage: powershell.exe -ExecutionPolicy Bypass -File .\tools\rewrite_integration_simulate_ps1.ps1

$target = 'c:\Users\PC\metartpay\.github\workflows\integration-simulate.yml'
$content = @'
name: Integration - simulate-confirm

on:
  push:
    branches:
      - main
    paths:
      - 'backend/**'
      - '.github/workflows/integration-simulate.yml'
  workflow_dispatch: {}

# Clean, editor-friendly integration workflow. Keep heavy run gated by a shell guard.

jobs:
  run-emulator-and-tests:
    runs-on: ubuntu-latest
    steps:
      - name: checkout
        uses: actions/checkout@v4

      - name: guard-manual-or-main
        shell: bash
        run: |
          echo "Event: $GITHUB_EVENT_NAME  Ref: $GITHUB_REF"
          if [ "$GITHUB_EVENT_NAME" != "workflow_dispatch" ] && [ "$GITHUB_REF" != "refs/heads/main" ]; then
            echo "Skip heavy emulator job (not manual or main)"
            exit 0
          fi

      - name: setup-node
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: cache-npm-global
        uses: actions/cache@v4
        with:
          path: ~/.npm
          key: npm-global-cache-v1

      - name: install-firebase-tools
        run: |
          npm install -g firebase-tools@11.30.0

      - name: setup-java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '11'

      - name: patch-backend-engines
        working-directory: .
        run: |
          node -e "const fs=require('fs');const p='backend/package.json';if(!fs.existsSync(p)){process.exit(0);}const j=JSON.parse(fs.readFileSync(p));j.engines=j.engines||{};j.engines.node='18';fs.writeFileSync(p,JSON.stringify(j,null,2));"

      - name: cache-backend-node-modules
        uses: actions/cache@v4
        with:
          path: backend/node_modules
          key: backend-node-modules-v1

      - name: install-backend-deps
        working-directory: backend
        run: |
          npm ci

      - name: build-backend
        working-directory: backend
        run: |
          npm run build

      - name: run-integration-simulate
        working-directory: backend
        env:
          FIRESTORE_EMULATOR_HOST: 127.0.0.1:8081
          FUNCTIONS_EMULATOR_HOST: 127.0.0.1:8082
          HOSTING_EMULATOR_HOST: 127.0.0.1:8083
          STORAGE_EMULATOR_HOST: 127.0.0.1:8084
          NODE_ENV: development
        run: |
          node tools/verify_manifest.js || (echo "manifest verification failed" && exit 2)
          cat > ../firebase.emulation.override.json <<'JSON'
          {
            "emulators": {
              "functions": { "port": 8082 },
              "firestore": { "port": 8081 },
              "hosting": { "port": 8083 },
              "storage": { "port": 8084 }
            }
          }
          JSON
          firebase emulators:exec --project=metartpay-bac2f --debug "node tools/integration_simulate_test.js" --config ../firebase.emulation.override.json
'@

# Write UTF8 without BOM
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($target, $content, $enc)
Write-Host "Wrote $target (UTF8 without BOM)."

# Print first 30 lines to show the file was written
Get-Content $target -TotalCount 30 | ForEach-Object { Write-Host $_ }
