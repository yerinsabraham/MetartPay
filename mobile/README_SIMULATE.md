# Running MetartPay Demo (simulate payment)

This guide shows how to run the Flutter demo that simulates a payment and opens the PaymentStatusScreen.

Requirements
- Flutter SDK
- Backend emulator running (Functions + Firestore) or a dev backend reachable at METARTPAY_BASE_URL
- Optional: Firebase project config if you want FCM/Firestore in production

Steps
1) Start backend emulators (from repo root):

```powershell
# Example: start emulators (adjust ports if necessary)
# You can use your existing emulator scripts or start functions+firestore
firebase emulators:start --only functions,firestore
```

2) Run demo app

```powershell
cd mobile
flutter pub get
flutter run -t lib/main_demo.dart -d <device>
```

3) Use the demo UI
- Toggle "Dev simulate" on and press "Simulate & Open Status".
- The app will call `/payments/simulate-confirm` at the configured `METARTPAY_BASE_URL` (defaults to local functions emulator URL) and open the PaymentStatusScreen.
- PaymentStatusScreen subscribes to Firestore `transactions/:id` doc for realtime updates. If Firestore emulator is running, backend writes appear immediately.

Notes
- Set `--dart-define=METARTPAY_BASE_URL="http://127.0.0.1:5001/metartpay-bac2f/us-central1/api"` if your functions emulator uses a different host/port.
- If your app lacks Firebase config, PaymentStatusScreen will fallback to polling the backend for transaction updates.

Troubleshooting
- If simulate fails with 403, ensure `DEV_SIMULATE_KEY` in the backend workflow or `x-dev-simulate-key` on the request matches (default `dev-local-key`).
- If Firestore listener does not show updates, ensure the emulator is running and `FIRESTORE_EMULATOR_HOST` is set for the backend and the app is using the emulator settings (see Firebase docs).
