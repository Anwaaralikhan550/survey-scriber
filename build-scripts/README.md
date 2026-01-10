# SurveyScriber Build Scripts

Automated build scripts for different environments.

## Quick Start

### Production Build (VPS Backend)

```bash
# Build production APK
chmod +x build-scripts/build-production.sh
./build-scripts/build-production.sh
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`
**Backend:** `http://192.95.33.150:3000/api/v1`

### Development Build (Local Backend)

```bash
# Build development APK
chmod +x build-scripts/build-development.sh
./build-scripts/build-development.sh
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`
**Backend:** `http://10.0.2.2:3000/api/v1` (Android Emulator)

---

## Manual Builds

### Production (VPS)

```bash
# APK
flutter build apk --release --dart-define=API_BASE_URL=http://192.95.33.150:3000/api/v1

# App Bundle (Google Play)
flutter build appbundle --release --dart-define=API_BASE_URL=http://192.95.33.150:3000/api/v1
```

### Development (Local)

```bash
# For Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# For Physical Device (replace with your IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api/v1
```

---

## Install APK on Device

```bash
# Via Flutter
flutter install --release

# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Find Your Computer's IP

**Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows:**
```bash
ipconfig | findstr IPv4
```

---

## Environment Variables

The app uses `--dart-define` to inject the API URL at build time:

| Variable | Description | Example |
|----------|-------------|---------|
| `API_BASE_URL` | Backend API base URL | `http://192.95.33.150:3000/api/v1` |

### Default Values

- **Default (Production):** `http://192.95.33.150:3000/api/v1` (VPS)
- **Development Override:** `http://10.0.2.2:3000/api/v1` (Emulator)
- **Physical Device:** `http://YOUR_IP:3000/api/v1` (LAN)

---

## iOS Builds (Future)

```bash
# Production
flutter build ios --release --dart-define=API_BASE_URL=http://192.95.33.150:3000/api/v1

# Development
flutter run -d ios --dart-define=API_BASE_URL=http://YOUR_IP:3000/api/v1
```

---

## Troubleshooting

### "Connection refused" or "Network error"

**Emulator:**
- Use `http://10.0.2.2:3000/api/v1` (NOT `localhost`)

**Physical Device:**
- Make sure device and computer are on same WiFi
- Use your computer's IP address (not localhost)
- Check firewall allows port 3000

**Production:**
- Verify VPS backend is running: `curl http://192.95.33.150:3000/api/v1/health`
- Check VPS firewall allows port 3000

### Clean Build

```bash
flutter clean
flutter pub get
flutter build apk
```

---

## Build Variants

### Debug (Development)
- Fast build
- Hot reload enabled
- Verbose logging
- Debug symbols included

```bash
flutter build apk --debug
```

### Release (Production)
- Optimized code
- Minified
- Obfuscated
- Smaller APK size

```bash
flutter build apk --release
```

### Profile (Performance Testing)
- Optimized code
- Performance tracing enabled
- Debug symbols included

```bash
flutter build apk --profile
```

---

## CI/CD Integration

### GitHub Actions

```yaml
- name: Build Production APK
  run: |
    flutter build apk --release \
      --dart-define=API_BASE_URL=${{ secrets.PRODUCTION_API_URL }}
```

### Docker

```dockerfile
ARG API_BASE_URL=http://192.95.33.150:3000/api/v1
RUN flutter build apk --release --dart-define=API_BASE_URL=$API_BASE_URL
```

---

## Questions?

See the main project README or contact the development team.
