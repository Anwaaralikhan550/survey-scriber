@echo off
rem Local test backend for the nginx smoke test: docker database ss_desk, throwaway secrets, fake Gemini on :4799.
cd /d E:\survey-scriber\backend
set NODE_ENV=development
set PORT=3099
set DATABASE_URL=postgresql://ss:ss_pw@127.0.0.1:15432/ss_desk?schema=public
set JWT_SECRET=e2e-local-only-access-secret-0123456789abcdef
set JWT_ACCESS_SECRET=e2e-local-only-access-secret-0123456789abcdef
set JWT_REFRESH_SECRET=e2e-local-only-refresh-secret-0123456789abcdef
set EDITOR_BASE_URL=http://localhost:8085
set EDITOR_OPEN_LIMIT_PER_SECOND=50
set EDITOR_OPEN_LIMIT_PER_MINUTE=500
set EDITOR_OPEN_LIMIT_PER_HOUR=5000
set GEMINI_API_KEY=fake
set GEMINI_API_BASE_URL=http://127.0.0.1:4799
set REPORT_RETENTION_ENABLED=false
node dist\src\main.js
