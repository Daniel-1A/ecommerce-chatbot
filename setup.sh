#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# setup.sh — Bootstrap the ecommerce-chatbot dev environment
# Usage:  chmod +x setup.sh && ./setup.sh
# ──────────────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# ── 1. Check Docker ──────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo " Ecommerce Chatbot — Setup"
echo "══════════════════════════════════════════════"
echo ""

if ! command -v docker &>/dev/null; then
    error "Docker is not installed."
    echo "  Install from: https://docs.docker.com/get-docker/"
    exit 1
fi
info "Docker found: $(docker --version)"

if ! docker compose version &>/dev/null; then
    error "Docker Compose (v2) is not available."
    echo "  It should be included with Docker Desktop."
    echo "  For Linux: https://docs.docker.com/compose/install/"
    exit 1
fi
info "Docker Compose found: $(docker compose version --short)"

# ── 2. Environment file ─────────────────────────────
if [ ! -f .env ]; then
    cp .env.example .env
    info "Created .env from .env.example"
    warn "Review .env and adjust values if needed."
else
    info ".env already exists — skipping copy."
fi

# ── 3. Build and start ──────────────────────────────
echo ""
info "Building and starting services with Docker Compose..."
echo ""
docker compose up --build -d

echo ""
info "Waiting for services to become healthy..."
sleep 5

# ── 4. Health check ─────────────────────────────────
MAX_RETRIES=12
RETRY=0
until curl -sf http://localhost:3000/ > /dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        error "App did not become healthy after ${MAX_RETRIES} retries."
        echo "  Check logs with: docker compose logs app"
        exit 1
    fi
    echo "  Waiting for app to start... (attempt $RETRY/$MAX_RETRIES)"
    sleep 3
done

echo ""
echo "══════════════════════════════════════════════"
info "Setup complete! App is running at:"
echo ""
echo "    http://localhost:3000"
echo ""
echo "  Useful commands:"
echo "    docker compose logs -f app   # stream app logs"
echo "    docker compose down -v       # stop & remove everything"
echo "    make dev                     # alias for docker compose up"
echo "══════════════════════════════════════════════"
