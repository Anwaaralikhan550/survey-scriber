# SurveyScriber - Developer Quick Reference Card

Print this or keep it handy!

---

## 🔑 Production Access

**Backend API:**
```
http://192.95.33.150:3000/api/v1
```

**Admin Login:**
```
Email: admin@surveyscriber.com
Password: Admin123!
```

**API Docs:**
```
http://192.95.33.150:3000/api/docs
```

**VPS SSH:**
```bash
ssh ali@192.95.33.150
# Password: (ask team lead)
```

---

## ⚡ Quick Commands

### Run App (Production Backend)
```bash
flutter run
```

### Run App (Local Backend)
```bash
# Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# Physical device (use your IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api/v1
```

### Build Production APK
```bash
./build-scripts/build-production.sh
```

### Test Backend
```bash
curl http://192.95.33.150:3000/api/v1/health
```

### Deploy Backend to VPS
```bash
ssh ali@192.95.33.150
cd /opt/surveyscriber
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

---

## 📁 Key Files

**API Config:**
```
lib/core/constants/app_constants.dart (line 32-35)
```

**VPS Backend Config:**
```
/opt/surveyscriber/.env (on VPS)
```

**Docker Deployment:**
```
backend/docker-compose.prod.yml
```

---

## 🐛 Quick Fixes

**App won't connect to backend:**
```bash
curl http://192.95.33.150:3000/api/v1/health
# If fails, backend is down - restart on VPS
```

**Build errors:**
```bash
flutter clean && flutter pub get && flutter run
```

**VPS backend restart:**
```bash
ssh ali@192.95.33.150
cd /opt/surveyscriber
docker compose -f docker-compose.prod.yml restart
```

---

## 📖 Full Documentation

See `DEVELOPER_ONBOARDING.md` for complete guide.

---

**Need Help?** Ask team lead!
