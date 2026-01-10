# Flutter App - VPS Backend Integration

Your Flutter app has been configured to connect to the deployed VPS backend.

## ✅ Changes Made

### 1. Updated API Configuration

**File:** `lib/core/constants/app_constants.dart`

**Changed:**
```dart
// OLD: Default to Android emulator localhost
defaultValue: 'http://10.0.2.2:3000/api/v1/'

// NEW: Default to production VPS
defaultValue: 'http://192.95.33.150:3000/api/v1'
```

**Impact:**
- All API calls now go to your VPS by default
- Production builds connect to `http://192.95.33.150:3000`
- Can still override for local development using `--dart-define`

### 2. Created Build Scripts

**Files:**
- `build-scripts/build-production.sh` - Builds for production VPS
- `build-scripts/build-development.sh` - Builds for local development
- `build-scripts/README.md` - Complete build documentation

### 3. Backend CORS Configuration

**Status:** ✅ Already configured
- CORS is set to `*` (allow all origins)
- Mobile apps can make requests without issues

---

## 🚀 How to Test

### Option 1: Quick Test (Development Mode)

```bash
# Run on connected device/emulator
flutter run
```

**What this does:**
- Uses production VPS backend: `http://192.95.33.150:3000/api/v1`
- Enables hot reload for quick testing
- Shows debug logs

### Option 2: Production Build

```bash
# Build production APK
./build-scripts/build-production.sh

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Test Steps

1. **Launch the app** on your device/emulator

2. **Login with admin credentials:**
   - Email: `admin@surveyscriber.com`
   - Password: `Admin123!`

3. **Test key features:**
   - ✅ Login/Logout
   - ✅ View surveys list
   - ✅ Create new survey
   - ✅ Add sections and answers
   - ✅ Upload photos/media
   - ✅ Sync data

4. **Verify API calls in logs:**
   ```
   Look for: "API Request: http://192.95.33.150:3000/api/v1/..."
   ```

---

## 🔧 Development Options

### For Android Emulator (Local Backend)

If you want to test with a local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

### For Physical Device (Local Backend)

1. **Find your computer's IP:**
   ```bash
   # Mac/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1

   # Windows
   ipconfig | findstr IPv4
   ```

2. **Run with your IP:**
   ```bash
   flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api/v1
   ```

### For Production (VPS Backend)

```bash
# Just run normally - uses production by default
flutter run

# Or explicitly specify production
flutter run --dart-define=API_BASE_URL=http://192.95.33.150:3000/api/v1
```

---

## 🐛 Troubleshooting

### Connection Errors

**Symptom:** "Network error" or "Connection refused"

**Solutions:**

1. **Verify backend is running:**
   ```bash
   curl http://192.95.33.150:3000/api/v1/health
   ```
   Should return: `{"status":"ok",...}`

2. **Check VPS firewall:**
   ```bash
   # On VPS
   sudo ufw status
   sudo ufw allow 3000/tcp
   ```

3. **Verify app configuration:**
   - Check logs for API URL
   - Make sure it shows: `http://192.95.33.150:3000/api/v1`

### CORS Errors

**Symptom:** "CORS policy blocked"

**Solution:**
The backend CORS is already set to `*`, but if you see this:

```bash
# On VPS, verify CORS setting
cat /opt/surveyscriber/.env | grep CORS

# Should show: CORS_ORIGINS=*
```

### SSL Certificate Errors

**Symptom:** "Certificate verification failed"

**Note:** You're using HTTP (not HTTPS), so this shouldn't happen. But if it does:
- Make sure URL starts with `http://` (not `https://`)
- Check `app_constants.dart` for correct URL

---

## 📊 Backend Status

**API Base URL:** `http://192.95.33.150:3000/api/v1`
**Health Check:** `http://192.95.33.150:3000/api/v1/health`
**API Docs:** `http://192.95.33.150:3000/api/docs`

**Admin Account:**
- Email: `admin@surveyscriber.com`
- Password: `Admin123!`

---

## 🔒 Security Notes

### Current Setup (Development)
- ✅ HTTP connections (not encrypted)
- ✅ IP address access (not domain)
- ✅ CORS allows all origins

### For Production (Future)
- 🔄 Set up HTTPS with SSL certificate
- 🔄 Use domain name (e.g., `https://api.surveyscriber.com`)
- 🔄 Restrict CORS to specific origins
- 🔄 Add rate limiting
- 🔄 Implement certificate pinning

---

## 📝 Next Steps

1. **Test the app** with the VPS backend
2. **Create sample surveys** to verify functionality
3. **Test offline sync** (create survey offline, then sync)
4. **Test media uploads** (photos, audio, signatures)
5. **Verify all features work** end-to-end

### Optional Improvements

1. **Set up domain name:**
   - Point domain to `192.95.33.150`
   - Update API URL to `https://api.yourdomain.com`

2. **Enable SSL:**
   - Install Let's Encrypt certificate
   - Update backend to use HTTPS
   - Update Flutter app URL

3. **Add monitoring:**
   - Set up error tracking (Sentry, Crashlytics)
   - Add analytics (Firebase Analytics)
   - Monitor API performance

---

## 🎯 Summary

**What Changed:**
- ✅ Flutter app now points to VPS backend
- ✅ API URL: `http://192.95.33.150:3000/api/v1`
- ✅ CORS configured for mobile apps
- ✅ Build scripts created for easy deployment

**What to Test:**
- ✅ Login/Authentication
- ✅ Survey CRUD operations
- ✅ Media uploads
- ✅ Offline sync
- ✅ All API endpoints

**Status:**
🟢 **Ready to test!** Run `flutter run` to start.

---

Need help? Check:
- `build-scripts/README.md` - Build documentation
- `backend/VPS_DEPLOYMENT.md` - Backend deployment guide
- `backend/QUICK_START_VPS.md` - Quick deployment steps
