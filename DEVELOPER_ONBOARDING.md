# SurveyScriber - Developer Onboarding Guide

## 🎯 Overview

This document contains all the information you need to work on SurveyScriber with the production VPS backend.

---

## 📍 Production Environment

### Backend API (VPS)

**Base URL:** `http://192.95.33.150:3000/api/v1`

**Important Endpoints:**
- Health Check: `http://192.95.33.150:3000/api/v1/health`
- API Documentation: `http://192.95.33.150:3000/api/docs` (Swagger UI)
- Auth Login: `http://192.95.33.150:3000/api/v1/auth/login`
- Auth Register: `http://192.95.33.150:3000/api/v1/auth/register`

### Admin Credentials

```
Email: admin@surveyscriber.com
Password: Admin123!
```

**Test the backend:**
```bash
curl http://192.95.33.150:3000/api/v1/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-01-10T05:32:55.597Z",
  "uptime": 109.928565346,
  "database": {
    "status": "up",
    "responseTime": "2ms"
  }
}
```

---

## 🚀 Quick Start - Connect to Production Backend

### Option 1: Run App with Production Backend (Default)

The app is already configured to use production by default:

```bash
# Just run normally - connects to VPS
flutter run
```

### Option 2: Run with Local Backend (For Development)

If you want to test against a local backend:

```bash
# For Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# For Physical Device (replace with your computer's IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api/v1
```

### Option 3: Build Production APK

```bash
# Using the build script
./build-scripts/build-production.sh

# Or manually
flutter build apk --release
```

---

## 📁 Project Structure

```
scriber/
├── lib/                                    # Flutter App
│   ├── main.dart                           # Entry point
│   ├── app/
│   │   ├── router/                         # Navigation (go_router)
│   │   └── theme/                          # App theme & colors
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          # ⭐ API_BASE_URL configured here
│   │   ├── network/                        # API client (Dio)
│   │   ├── database/                       # Local SQLite (Drift)
│   │   └── sync/                           # Offline sync logic
│   └── features/                           # Feature modules
│       ├── auth/                           # Login, Register
│       ├── surveys/                        # Survey CRUD
│       ├── dashboard/                      # Main screen
│       ├── media/                          # Photo, audio, signatures
│       └── ...
│
├── backend/                                # NestJS Backend (deployed on VPS)
│   ├── src/
│   │   ├── main.ts                         # Bootstrap
│   │   ├── modules/
│   │   │   ├── auth/                       # JWT authentication
│   │   │   ├── surveys/                    # Survey endpoints
│   │   │   ├── media/                      # File uploads
│   │   │   └── ...
│   │   └── prisma/                         # Database ORM
│   ├── prisma/
│   │   ├── schema.prisma                   # Database schema
│   │   └── migrations/                     # DB migrations
│   ├── Dockerfile                          # Production Docker image
│   ├── docker-compose.prod.yml             # Production deployment
│   └── .env.production                     # Production config (on VPS only)
│
└── build-scripts/                          # Build automation
    ├── build-production.sh                 # Build for VPS backend
    └── build-development.sh                # Build for local backend
```

---

## 🔧 Configuration Files

### 1. Flutter App Configuration

**File:** `lib/core/constants/app_constants.dart`

```dart
// Current configuration (line 32-35)
static const String _rawBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.95.33.150:3000/api/v1',  // ⭐ Points to VPS
);
```

**What this means:**
- By default, the app connects to the VPS backend
- You can override this using `--dart-define=API_BASE_URL=...`
- No code changes needed to switch between environments

### 2. Backend Configuration (VPS Only)

**Location:** `/opt/surveyscriber/.env` on VPS

**Contents (already configured on VPS):**
```bash
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://surveyscriber:...@postgres:5432/surveyscriber_db
JWT_ACCESS_SECRET=37bc89127e6f5aa8de8e33be8d23acfe7b5062f7b12b2921e9669f5404504b465882630ad05333c0d734c2dac2e0439a9aa9e6a2b68cd90bc9c823c749631af6
JWT_REFRESH_SECRET=40f894426ec88c7910ebd91d748e14b54d612add0f8d00a3274a1567dc336bd22aa8a8f3bf3058260da3d2f69d8322f2b330b87a0790298304d5a7d9d3494b22
CORS_ORIGINS=*
```

**⚠️ Important:** You don't need to modify this. It's already set up on the VPS.

---

## 🏗️ Development Workflow

### Scenario 1: Work on Flutter App (Using Production Backend)

```bash
# 1. Pull latest code
git pull

# 2. Install dependencies
flutter pub get

# 3. Run on device/emulator
flutter run

# 4. Make your changes
# ... edit code ...

# 5. Hot reload (press 'r' in terminal)
# Or hot restart (press 'R')

# 6. Test login with admin credentials
# Email: admin@surveyscriber.com
# Password: Admin123!
```

### Scenario 2: Work on Backend Locally

```bash
# 1. Navigate to backend
cd backend

# 2. Install dependencies
npm install

# 3. Set up local PostgreSQL
docker-compose up -d postgres

# 4. Copy environment file
cp .env.example .env

# 5. Update .env with local settings
# DATABASE_URL=postgresql://surveyscriber:surveyscriber_secret@localhost:5432/surveyscriber_db

# 6. Run migrations
npx prisma migrate dev

# 7. Start backend
npm run start:dev

# 8. Test Flutter app with local backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

### Scenario 3: Deploy Backend Changes to VPS

**You'll need VPS SSH access. Ask the team lead for:**
- VPS IP: `192.95.33.150`
- SSH Username: `ali`
- SSH Password: (provided separately)

```bash
# 1. SSH into VPS
ssh ali@192.95.33.150

# 2. Navigate to project
cd /opt/surveyscriber

# 3. Pull latest code
git pull

# 4. Rebuild and restart
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build

# 5. Run migrations if needed
docker compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

# 6. Check logs
docker compose -f docker-compose.prod.yml logs -f backend

# 7. Test
curl http://localhost:3000/api/v1/health
```

---

## 🔐 VPS Access Information

**VPS Details:**
- **IP Address:** `192.95.33.150`
- **SSH User:** `ali`
- **SSH Password:** (ask team lead)
- **Project Location:** `/opt/surveyscriber`

**SSH Connection:**
```bash
ssh ali@192.95.33.150
```

**Useful VPS Commands:**
```bash
# Check if services are running
docker compose -f docker-compose.prod.yml ps

# View backend logs
docker compose -f docker-compose.prod.yml logs -f backend

# View PostgreSQL logs
docker compose -f docker-compose.prod.yml logs -f postgres

# Restart services
docker compose -f docker-compose.prod.yml restart

# Stop services
docker compose -f docker-compose.prod.yml down

# Start services
docker compose -f docker-compose.prod.yml up -d
```

---

## 📱 Build & Run Commands

### Development Builds

```bash
# Android (connects to VPS by default)
flutter run

# iOS (connects to VPS by default)
flutter run -d ios

# With local backend (emulator)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# With local backend (physical device - use your IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api/v1
```

### Production Builds

```bash
# Using build script (recommended)
./build-scripts/build-production.sh

# Manual build
flutter build apk --release

# Build for iOS
flutter build ios --release

# Install on connected device
flutter install
```

---

## 🧪 Testing

### Test Backend API

```bash
# Health check
curl http://192.95.33.150:3000/api/v1/health

# Login
curl -X POST http://192.95.33.150:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@surveyscriber.com",
    "password": "Admin123!"
  }'

# View API docs in browser
open http://192.95.33.150:3000/api/docs
```

### Test Flutter App

1. **Install app on device:**
   ```bash
   flutter install
   ```

2. **Login with admin credentials:**
   - Email: `admin@surveyscriber.com`
   - Password: `Admin123!`

3. **Test key features:**
   - ✅ Create new survey
   - ✅ Add sections and answers
   - ✅ Upload photos
   - ✅ Test offline mode (airplane mode)
   - ✅ Sync data when back online

---

## 🐛 Troubleshooting

### "Connection Refused" or "Network Error"

**Check if VPS backend is running:**
```bash
curl http://192.95.33.150:3000/api/v1/health
```

If this fails, the backend is down. SSH to VPS and restart:
```bash
ssh ali@192.95.33.150
cd /opt/surveyscriber
docker compose -f docker-compose.prod.yml up -d
```

### "API_BASE_URL not set" or Wrong Backend

**Check your Flutter configuration:**
```bash
# View current config
cat lib/core/constants/app_constants.dart | grep defaultValue

# Should show: defaultValue: 'http://192.95.33.150:3000/api/v1'
```

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# For Android issues
cd android
./gradlew clean
cd ..
flutter run
```

### VPS Backend Issues

```bash
# SSH to VPS
ssh ali@192.95.33.150

# Check status
cd /opt/surveyscriber
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f

# Restart
docker compose -f docker-compose.prod.yml restart
```

---

## 📚 Important Documentation

**In this repository:**
- `FLUTTER_VPS_INTEGRATION.md` - Flutter + VPS integration guide
- `backend/VPS_DEPLOYMENT.md` - Complete VPS deployment guide
- `backend/QUICK_START_VPS.md` - Quick deployment reference
- `build-scripts/README.md` - Build script documentation
- `GITHUB_PUSH_GUIDE.md` - How to push code to GitHub

**Online Resources:**
- API Documentation: http://192.95.33.150:3000/api/docs
- Flutter Docs: https://docs.flutter.dev
- NestJS Docs: https://docs.nestjs.com
- Prisma Docs: https://www.prisma.io/docs

---

## 🔄 Git Workflow

### Pull Latest Changes

```bash
git pull origin main
```

### Push Your Changes

```bash
# 1. Stage changes
git add .

# 2. Commit
git commit -m "Description of your changes"

# 3. Push
git push origin main
```

### Branch Strategy (if using)

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Work on your feature
# ... make changes ...

# Commit and push
git add .
git commit -m "Add your feature"
git push origin feature/your-feature-name

# Create PR on GitHub
```

---

## ✅ Checklist for New Developers

- [ ] Clone repository
- [ ] Run `flutter pub get`
- [ ] Install Android Studio and Flutter SDK
- [ ] Set up emulator or connect physical device
- [ ] Test app with `flutter run`
- [ ] Login with admin credentials
- [ ] Test creating a survey
- [ ] Review `lib/core/constants/app_constants.dart` for API config
- [ ] Read `FLUTTER_VPS_INTEGRATION.md`
- [ ] Bookmark API docs: http://192.95.33.150:3000/api/docs
- [ ] Get VPS SSH credentials from team lead (if needed)

---

## 🆘 Getting Help

**Common Issues:**
1. **Build errors:** Check `Troubleshooting` section above
2. **API connection issues:** Verify backend is running with health check
3. **VPS access:** Contact team lead for SSH credentials
4. **Code questions:** Review documentation in repository

**Team Communication:**
- Ask team lead for Slack/Discord/communication channel
- Share error logs when asking for help
- Document solutions for future reference

---

## 🎯 Summary

**Production Backend:**
- URL: `http://192.95.33.150:3000/api/v1`
- Admin: `admin@surveyscriber.com` / `Admin123!`
- Already configured as default in Flutter app

**Your Tasks:**
1. Pull latest code
2. Run `flutter run` (connects to VPS automatically)
3. Make your changes
4. Test thoroughly
5. Push to GitHub
6. (Optional) Deploy backend changes if needed

**No special configuration needed - the app already points to production!**

---

**Last Updated:** January 10, 2026
**Contact:** Team Lead for VPS access and additional credentials
