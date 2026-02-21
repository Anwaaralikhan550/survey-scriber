#!/bin/bash

# ============================================
# SurveyScriber VPS Installation Script
# ============================================
# Automates Docker and Docker Compose installation
# on Ubuntu/Debian systems
#
# Usage: sudo ./vps-install.sh
# ============================================

set -e  # Exit on error

echo "=========================================="
echo "  SurveyScriber VPS Setup"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    echo "   Usage: sudo ./vps-install.sh"
    exit 1
fi

echo "✓ Running with root privileges"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "❌ Cannot detect OS. Only Ubuntu/Debian supported."
    exit 1
fi

echo "📋 Detected OS: $OS $VERSION"
echo ""

# Check if Ubuntu or Debian
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo "❌ This script only supports Ubuntu and Debian"
    exit 1
fi

# Update system packages
echo "📦 Updating system packages..."
apt-get update -qq
echo "✓ System packages updated"
echo ""

# Install prerequisites
echo "📦 Installing prerequisites..."
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    wget \
    nano \
    ufw

echo "✓ Prerequisites installed"
echo ""

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✓ Docker already installed: $(docker --version)"
else
    echo "🐳 Installing Docker..."

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "✓ Docker installed: $(docker --version)"
fi

echo ""

# Start and enable Docker
echo "🚀 Starting Docker service..."
systemctl start docker
systemctl enable docker
echo "✓ Docker service started and enabled"
echo ""

# Check if Docker Compose is installed
if docker compose version &> /dev/null; then
    echo "✓ Docker Compose already installed: $(docker compose version)"
else
    echo "❌ Docker Compose not found (should have been installed with Docker)"
    exit 1
fi

echo ""

# Configure firewall
echo "🔥 Configuring firewall (UFW)..."

# Check if UFW is active
if ufw status | grep -q "Status: active"; then
    echo "⚠️  UFW is already active. Skipping firewall configuration."
    echo "   Make sure ports 22, 80, 443, and 3000 are allowed."
else
    # Allow SSH, HTTP, HTTPS, and API
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 3000/tcp comment 'API'

    echo "✓ Firewall configured"
fi

echo ""

# Create application directory
echo "📁 Creating application directory..."
APP_DIR="/opt/surveyscriber"

if [ ! -d "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
    echo "✓ Created directory: $APP_DIR"
else
    echo "✓ Directory already exists: $APP_DIR"
fi

echo ""

# Set up Docker to run without sudo (optional)
echo "👤 Adding current user to docker group..."
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
    echo "✓ User $SUDO_USER added to docker group"
    echo "⚠️  Log out and back in for this to take effect"
else
    echo "⚠️  Run manually: sudo usermod -aG docker \$USER"
fi

echo ""
echo "=========================================="
echo "  ✅ Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Clone your repository:"
echo "   cd $APP_DIR"
echo "   git clone <your-repo-url> ."
echo ""
echo "2. Navigate to backend:"
echo "   cd $APP_DIR/backend"
echo ""
echo "3. Configure environment variables:"
echo "   cp .env.production.example .env.production"
echo "   nano .env.production"
echo ""
echo "4. Deploy:"
echo "   docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "5. Verify:"
echo "   curl http://localhost:3000/api/v1/health"
echo ""
echo "=========================================="
echo "📖 Full guide: See VPS_DEPLOYMENT.md"
echo "=========================================="
