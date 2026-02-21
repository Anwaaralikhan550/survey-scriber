#!/bin/bash
# Manual E2E Tests for Booking Change Requests and Audit Logs

ADMIN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkYTA0NmU0Mi1lNWQyLTRhYWUtOTI2Yy1hZGVmNTRjMGQ1MzkiLCJlbWFpbCI6Im1hbnVhbC10ZXN0LWFkbWluQHRlc3QubG9jYWwiLCJyb2xlIjoiQURNSU4iLCJpYXQiOjE3Njc0MjI2MTksImV4cCI6MTc2NzQyNjIxOX0.3NmtIH7qOPc8SeWRgEZA2j5Ku_UEzZx5cSUNalsDSrY"
CLIENT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwZWI3OGMwMC00Y2ZlLTQwYWYtYTEzNS03NWQzMzRkMDE4MTIiLCJlbWFpbCI6Im1hbnVhbC10ZXN0LWNsaWVudEB0ZXN0LmxvY2FsIiwidHlwZSI6ImNsaWVudCIsImlhdCI6MTc2NzQyMjYxOSwiZXhwIjoxNzY3NDI2MjE5fQ.M7UEzQGxCitnsOPw7qkVEWGs713sGHjInMsRcR4yo70"
BOOKING_ID="a970095d-809d-4296-8b26-4c7990f6da95"

echo "=== TEST 1: Client creates RESCHEDULE request ==="
sleep 2
curl -s -X POST http://localhost:3000/api/v1/client/booking-changes \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"bookingId\": \"$BOOKING_ID\", \"type\": \"RESCHEDULE\", \"proposedDate\": \"2026-02-01\", \"proposedStartTime\": \"14:00\", \"proposedEndTime\": \"16:00\", \"reason\": \"MANUAL_TEST need to reschedule\"}"
echo ""
echo ""

echo "=== TEST 2: Client lists their requests ==="
sleep 2
curl -s http://localhost:3000/api/v1/client/booking-changes \
  -H "Authorization: Bearer $CLIENT_TOKEN"
echo ""
echo ""

echo "=== TEST 3: Staff (Admin) lists all requests ==="
sleep 2
curl -s http://localhost:3000/api/v1/booking-changes \
  -H "Authorization: Bearer $ADMIN_TOKEN"
echo ""
echo ""

echo "=== TEST 4: Admin queries audit logs ==="
sleep 2
curl -s "http://localhost:3000/api/v1/audit-logs?limit=5" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
echo ""
echo ""

echo "=== TESTS COMPLETE ==="
