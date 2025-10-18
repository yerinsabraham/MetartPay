Mobile README & QA

Purpose
- Quick instructions to run the mobile app locally and validate the Create Payment -> Solana immediate QR flow.

Run (PowerShell)

```powershell
cd c:\Users\PC\metartpay\mobile
flutter pub get
flutter clean
# Run on a connected device or emulator. Replace <device-id> or omit to select.
flutter run -d <device-id>
```

Dev mock path (fast local QA without backend)
```powershell
cd c:\Users\PC\metartpay\mobile
flutter run -d <device-id> --dart-define=METARTPAY_DEV_MOCK_CREATE=true
```

What to test
- Open "Create Payment" in the app.
- Stage 1 should show token/network choices including:
  - Solana (SOL)
  - USDC – Solana
  - USDT – Solana
  - USDT – BSC, USDC – ETH, etc.
- Tap any Solana option (SOL / USDC – Solana / USDT – Solana)
  - The app should immediately navigate to the QR view.
  - The QR payload shown in the app should be address-only: `solana:<address>` (no `?spl-token=` or other query params).
- Scan that QR using Phantom (or another Solana wallet).
  - Expected: the wallet opens a send flow with the recipient address filled; user enters amount and completes send.
  - If the wallet rejects the QR, copy the payload string shown in the app and save the wallet error message.

If in-app QR differs from PC-generated PNG
- In the workspace `tools/` we have sample PNGs used for QA: e.g. `tools/sol_mainnet_address_only_simple.png`.
- Open that PNG on your PC, scan it with Phantom — this was validated to work previously. If the in-app QR differs, capture the app payload string and paste it in a message.

Logs & debugging
- If Phantom rejects the QR after scanning, capture Android logs while reproducing the scan:
```powershell
# Make sure adb is installed and device is connected
adb logcat -v time | Select-String -Pattern "Phantom","SendFungibleFlow","Solana"
```
- Paste the 20-100 lines around the wallet error here and I'll analyze.

Notes
- The mobile client now deliberately avoids generating Solana SPL token-prefill URIs locally; the backend is authoritative for token-prefill (returned as `qrPayloads.tokenPrefill`) and the mobile UI prefers address-only.
- If you want token-prefill enabled on mainnet, the backend flag `ALLOW_MAINNET_TOKEN_PREFILL` must be set and used with caution.
