# Android Signing Certificates for MetartPay

## Debug Certificate (Development)
**Purpose:** Used for development and testing
**SHA-1:** `D7:A3:84:45:18:D5:7E:37:39:7B:4A:C4:F8:3D:8F:98:B1:64:89:EB`
**SHA-256:** `AD:83:B0:EA:6F:40:AF:A2:86:85:AD:2F:24:79:5D:D9:4F:CB:1D:8B:91:5D:11:E0:48:C7:90:3F:B6:A3:69:1F`
**Location:** `C:\Users\PC\.android\debug.keystore`
**Alias:** `androiddebugkey`
**Password:** `android` (default)

## Production Certificate (Release)
**Purpose:** Used for production releases to Google Play Store
**SHA-1:** `A6:C4:C7:C5:F1:9A:4C:C7:68:29:20:89:AC:94:1F:02:65:A7:98:8A`
**SHA-256:** `CA:7B:7C:FB:84:DC:FB:4B:45:C2:3E:21:FA:98:CE:66:10:85:3F:01:CA:4B:D3:8F:DA:C8:EA:1B:83:55:B2:64`
**Location:** `mobile/android/app/upload-keystore.jks`
**Alias:** `upload`
**Owner:** CN=Yerins Abraham, OU=Metart Africa, O=Metart Africa, L=Lagos, ST=Lagos, C=NG
**Valid Until:** February 18, 2053

## Firebase Android App Setup

### Step 1: Add Android App to Firebase
1. Go to: https://console.firebase.google.com/u/2/project/metartpay-bac2f/
2. Click "Add app" → Android
3. **Package Name:** `com.metartpay.mobile`
4. **App Nickname:** `MetartPay Mobile`
5. **Debug SHA-1:** `D7:A3:84:45:18:D5:7E:37:39:7B:4A:C4:F8:3D:8F:98:B1:64:89:EB`

### Step 2: Download google-services.json
1. Download the `google-services.json` file
2. Place it in: `mobile/android/app/google-services.json`

### Step 3: Add Production SHA-1 (Later)
When ready for production, also add:
**Production SHA-1:** `A6:C4:C7:C5:F1:9A:4C:C7:68:29:20:89:AC:94:1F:02:65:A7:98:8A`

## Security Notes

### Production Keystore Security
- **NEVER commit the keystore file to Git**
- **Store keystore password securely** (use password manager)
- **Backup keystore file** in secure location
- **If lost, you cannot update the app on Play Store**

### Key Storage Best Practices
1. Copy `mobile/android/key.properties.example` to `mobile/android/key.properties`
2. Fill in your actual keystore password
3. Add `key.properties` to `.gitignore` (already done)
4. Store backup of keystore and password in secure cloud storage

## Building Signed APK

### Debug Build (Development)
```bash
cd mobile
flutter build apk --debug
```

### Release Build (Production)
```bash
cd mobile
flutter build apk --release
# or
flutter build appbundle --release  # For Google Play Store
```

## Verification Commands

### Check Debug Certificate
```bash
keytool -list -v -keystore C:\Users\PC\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Check Production Certificate
```bash
keytool -list -v -keystore mobile/android/app/upload-keystore.jks -alias upload
```

## Firebase Services to Enable

After adding the Android app:
1. **Authentication** → Enable Email/Password and Google Sign-In
2. **Firestore Database** → Create database in production mode
3. **Cloud Storage** → Enable for KYC document uploads
4. **Cloud Functions** → Already enabled
5. **Hosting** → For web payment pages