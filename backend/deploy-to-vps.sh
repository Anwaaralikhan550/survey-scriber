#!/bin/bash

VPS_IP="148.113.203.250"
VPS_USER="ubuntu"
VPS_PATH="/opt/surveyscriber/backend"

echo "🚀 Deploying to VPS: $VPS_IP"
echo "======================================"

# Backup on VPS
echo "📦 Creating backup..."
ssh ${VPS_USER}@${VPS_IP} "cd ${VPS_PATH} && mkdir -p backups/\$(date +%Y%m%d_%H%M%S) && cp field-mapping-config.json excel-phrase-library.json app-fields.json backups/\$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || echo 'No previous files to backup'"

# Upload files
echo "📤 Uploading fixed mapping files..."
scp field-mapping-config.json ${VPS_USER}@${VPS_IP}:${VPS_PATH}/
scp excel-phrase-library.json ${VPS_USER}@${VPS_IP}:${VPS_PATH}/
scp app-fields.json ${VPS_USER}@${VPS_IP}:${VPS_PATH}/

# Verify
echo "✅ Verifying files..."
ssh ${VPS_USER}@${VPS_IP} "cd ${VPS_PATH} && node -e \"const m = require('./field-mapping-config.json'); const low = Object.values(m).filter(v => v.confidence === 'low').length; console.log('Mappings:', Object.keys(m).length - 1, '| Low confidence:', low); process.exit(low > 0 ? 1 : 0);\""

# Restart backend
echo "🔄 Restarting backend..."
ssh ${VPS_USER}@${VPS_IP} "cd ${VPS_PATH} && docker compose restart backend || pm2 restart backend || echo 'Manual restart needed'"

echo "✅ Deployment complete!"
