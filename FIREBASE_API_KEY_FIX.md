# 🔥 FIREBASE API KEY FIX REQUIRED

## 🚨 Root Cause Identified
```
E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signUpPassword)
with exception - An internal error has occurred. [ API key not valid. Please pass a valid API key. ]
```

## ✅ Solution Steps

### Step 1: Regenerate Firebase Configuration Files

**You need to:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `metartpay-bac2f`
3. Click the ⚙️ gear icon → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app or click **Add app** if none exists

### Step 2: Download New google-services.json

**For Android app:**
1. Click on your Android app (or create new one)
2. **Package name:** `com.metartpay.metartpay_mobile`
3. **App nickname:** MetartPay Mobile
4. **Debug SHA-1:** (optional for now, needed for Google Sign-in)
5. Click **Register app**
6. **Download `google-services.json`**
7. Place it in: `C:\Users\PC\metartpay\mobile\android\app\google-services.json`

### Step 3: Update Firebase Options (if needed)

The `firebase_options.dart` might need regeneration:
```bash
cd C:\Users\PC\metartpay\mobile
flutter packages pub run flutterfire_cli:flutterfire configure
```

**OR manually update with new API key from Firebase Console**

### Step 4: Enable Authentication Methods

**In Firebase Console:**
1. Go to **Authentication** → **Sign-in method**
2. **Enable Email/Password:**
   - Click **Email/Password**
   - Toggle **Enable**
   - Click **Save**

3. **Enable Google Sign-in:**
   - Click **Google**
   - Toggle **Enable**
   - Enter **Support email:** your-email@gmail.com
   - Click **Save**

### Step 5: Check API Restrictions (Important!)

**In Google Cloud Console:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `metartpay-bac2f`
3. Navigate to **APIs & Services** → **Credentials**
4. Find your **Android API key**
5. Click **Edit**
6. Under **Application restrictions:**
   - Select **Android apps**
   - Add your package name: `com.metartpay.metartpay_mobile`
   - Add SHA-1 fingerprint (get with: `cd android && ./gradlew signingReport`)

7. Under **API restrictions:**
   - **Restrict key**
   - Enable these APIs:
     - ✅ Firebase Authentication API
     - ✅ Identity Toolkit API
     - ✅ Firebase Installations API
     - ✅ Cloud Firestore API

### Step 6: Test After Configuration

**Replace google-services.json and test:**
1. Place new `google-services.json` in `android/app/`
2. Clean and rebuild:
   ```bash
   cd C:\Users\PC\metartpay\mobile
   flutter clean
   flutter pub get
   flutter run
   ```

## 📱 Quick Test Commands

```bash
# Navigate to mobile directory
cd C:\Users\PC\metartpay\mobile

# Clean build
flutter clean

# Get dependencies  
flutter pub get

# Run app
flutter run
```

## 🎯 Expected Result After Fix

**You should see this instead of API key error:**
```
✅ Firebase Core: Initialized
✅ Firebase Auth: Available
👤 Current User: None
🔗 Project ID: metartpay-bac2f
```

**And authentication should work:**
- ✅ Email/password signup
- ✅ Email/password login
- ✅ Google Sign-in (after SHA-1 setup)

## ⚠️ Important Notes

1. **Backup first:** Save your current `google-services.json` before replacing
2. **Package name must match:** `com.metartpay.metartpay_mobile`
3. **SHA-1 needed for Google:** Get with `./gradlew signingReport`
4. **API restrictions:** Make sure Firebase APIs are enabled
5. **Clean rebuild:** Always `flutter clean` after config changes

---

**Next Action:** Download new `google-services.json` from Firebase Console and replace the current one.