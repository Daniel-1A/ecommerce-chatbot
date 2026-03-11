#!/usr/bin/env bash
# =============================================================================
# setup.sh — ecommerce-chatbot bootstrap
# Fixes Pain Points: #1, #2, #3, #4, #5, #6, #7, #8
# =============================================================================
set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
section() { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# =============================================================================
# 1. NODE VERSION CHECK  (Pain #1 · #5)
# =============================================================================
section "Runtime: Node.js"

REQUIRED_MAJOR=18     # minimum Node major version (LTS, no native build tools needed)

if ! command -v node &>/dev/null; then
  error "Node.js is not installed."
  echo    "  Install nvm (https://github.com/nvm-sh/nvm) then run:"
  echo    "    nvm install 18 && nvm use 18"
  echo    "  Or download directly from https://nodejs.org"
  exit 1
fi

NODE_VERSION=$(node --version)           # e.g. v25.0.0
NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v\([0-9]*\).*/\1/')

if [ "$NODE_MAJOR" -lt "$REQUIRED_MAJOR" ]; then
  error "Node ${NODE_VERSION} detected — minimum required is v${REQUIRED_MAJOR}."
  echo  "  Switch versions with nvm:  nvm install 18 && nvm use 18"
  echo  "  Or download from https://nodejs.org/en/download"
  exit 1
fi

ok "Node ${NODE_VERSION} — meets minimum v${REQUIRED_MAJOR}"

# =============================================================================
# 2. NPM CHECK  (Pain #1)
# =============================================================================
section "Runtime: npm"

if ! command -v npm &>/dev/null; then
  error "npm is not installed. It ships with Node.js — reinstall Node from https://nodejs.org"
  exit 1
fi

ok "npm $(npm --version)"

# =============================================================================
# 3. POSTGRESQL CHECK  (Pain #8)
# =============================================================================
section "Runtime: PostgreSQL"

if ! command -v psql &>/dev/null; then
  warn "psql not found in PATH. PostgreSQL may not be installed or may not be in PATH."
  echo "  Download: https://www.postgresql.org/download/"
  echo "  The app will start but all /users and /products routes will fail without a DB."
  echo "  Continuing setup — fix DB separately (see Section 6 below)."
else
  ok "psql $(psql --version)"
fi

# =============================================================================
# 4. ENVIRONMENT FILE  (Pain #7 · #10)
# =============================================================================
section "Environment: .env"

if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    ok ".env created from .env.example"
    warn "Open .env and fill in your database credentials before starting the app."
  else
    error ".env.example is missing. Cannot create .env automatically."
    exit 1
  fi
else
  ok ".env already exists — skipping copy"
  # Check that required DB vars are present
  MISSING_VARS=()
  for VAR in DB_USER DB_HOST DB_NAME DB_PASSWORD DB_PORT PORT; do
    grep -q "^${VAR}=" .env || MISSING_VARS+=("$VAR")
  done
  if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    warn "The following variables are missing from your .env: ${MISSING_VARS[*]}"
    warn "Copy them from .env.example and fill in the values."
  fi
fi

# =============================================================================
# 5. DEPENDENCY INSTALLATION  (Pain #2 · #3 · #4 · #6)
# =============================================================================
section "Dependencies: npm install"

info "Installing packages (this uses 'sass' — pure JS, no build tools required)..."
if npm install; then
  ok "npm install completed successfully"
else
  error "npm install failed."
  echo  "  Common causes:"
  echo  "  • Network issues — check your internet connection"
  echo  "  • Corrupted cache — run: npm cache clean --force"
  echo  "  • Try: rm -rf node_modules package-lock.json && npm install"
  exit 1
fi

# =============================================================================
# 6. DATABASE SETUP INSTRUCTIONS  (Pain #8 · #9)
# =============================================================================
section "Database Setup"

echo -e "${BOLD}The app requires a PostgreSQL database named 'ebot'.${RESET}"
echo
echo "  Step 1 — Connect to PostgreSQL as a superuser:"
echo -e "    ${CYAN}psql -U postgres${RESET}"
echo
echo "  Step 2 — Create the database and run the schema:"
echo -e "    ${CYAN}\\i db/init.sql${RESET}"
echo
echo "  NOTE: init.sql contains a small syntax error (trailing comma in"
echo "  the categories table). If psql reports an error on that statement,"
echo "  remove the comma after the last column and re-run."
echo
echo "  Step 3 — Update .env with your credentials:"
echo -e "    ${CYAN}DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME${RESET}"
echo
echo -e "  ${YELLOW}db-lectures/ contains course SQL exercises — NOT required for the app.${RESET}"
echo "  Files: 07.sql, 08.sql, aula1.sql, aula2.sql, secao03.sql, alter-drop.sql"
echo "  Run them manually in psql if you want to explore the lesson data."

# =============================================================================
# 7. READY
# =============================================================================
section "Setup Complete"

ok "All checks passed. Start the app with:"
echo -e "    ${CYAN}npm start${RESET}         → compile CSS once, then run server with nodemon"
echo -e "    ${CYAN}npm run compile:sass${RESET} → watch SCSS for changes"
echo
warn "Ensure .env has valid DB credentials, or the DB routes will throw errors."
