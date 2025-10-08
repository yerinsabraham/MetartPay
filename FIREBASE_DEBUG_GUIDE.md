# Firebase Authentication Troubleshooting Guide

## 🔍 Current Issues
- Unable to login with email/password
- Unable to login with Google Sign-in
- Need to diagnose authentication problems

## 🧪 Debug Steps

### Step 1: Test Firebase Connection
I've created a Firebase Debug screen that will:
1. ✅ Check Firebase initialization
2. ✅ Test Firebase Auth availability  
3. ✅ Show current user status
4. ✅ Test email signup/login directly
5. ✅ Show detailed error messages

### Step 2: Run the Debug App
```bash
cd C:\Users\PC\metartpay\mobile
flutter hot-reload  # or flutter run if not running
```

The app now shows the Firebase Debug screen instead of the normal login.

### Step 3: Test Authentication
Use the debug screen to:
1. **Check Status** - Verify Firebase is connected
2. **Test Signup** - Try creating a new account
3. **Test Login** - Try signing in
4. **Read Errors** - Get detailed error codes and messages

## 🔧 Common Firebase Auth Issues

### Issue 1: Authentication Not Enabled
**Firebase Console Check:**
1. Go to https://console.firebase.google.com/
2. Select project: `metartpay-bac2f`
3. Go to **Authentication > Sign-in method**
4. Ensure **Email/Password** is **Enabled**
5. Ensure **Google** is **Enabled** (if using Google Sign-in)

### Issue 2: Authorized Domains
**Check Authorized Domains:**
1. In Firebase Console > Authentication > Settings
2. **Authorized domains** should include:
   - `localhost` (for development)
   - Your domain if deployed

### Issue 3: Google Sign-in Configuration
**For Google Sign-in to work:**
1. **Android**: Need SHA-1 fingerprint in Firebase
2. **google-services.json** must be in `android/app/`
3. **Google Sign-in** must be enabled in Firebase Console

### Issue 4: Network/Firewall Issues
- Check internet connection
- Corporate firewalls may block Firebase
- Try on mobile data vs WiFi

## 📋 Expected Debug Results

### ✅ Success Output:
```
✅ Firebase Core: Initialized
✅ Firebase Auth: Available  
👤 Current User: None
🔗 Project ID: metartpay-bac2f
📱 App ID: 1:563072068325:android:8c9a97a8b8c4a5cd4a6e8f
```

### ❌ Failure Examples:
```
❌ Email Signup Failed
Code: weak-password
Message: Password should be at least 6 characters

❌ Email Login Failed  
Code: user-not-found
Message: No user found with this email

❌ Firebase Error: [firebase_core/no-app] No Firebase App '[DEFAULT]' has been created
```

## 🚨 Action Items

### If Firebase Core Fails:
1. Check `firebase_options.dart` configuration
2. Verify `google-services.json` exists in `android/app/`
3. Check internet connectivity

### If Authentication Fails:
1. Enable Email/Password in Firebase Console
2. Check Firebase project permissions
3. Verify API keys are correct

### If Google Sign-in Fails:
1. Add SHA-1 fingerprint to Firebase project
2. Enable Google Sign-in provider
3. Check OAuth client configuration

## 🎯 Next Steps

1. **Run Debug Screen** - Get detailed error information
2. **Check Firebase Console** - Verify authentication is enabled
3. **Fix Configuration** - Based on error messages
4. **Restore Normal App** - Once authentication works

---

**Debug Mode Active:** The app now shows Firebase diagnostics instead of the normal login screen. This will help identify exactly what's preventing authentication from working.