# GOLDEN_PATH.md — Ecommerce Chatbot

End-to-end verified setup path for a new contributor on a clean machine.

---

## Prerequisites

| Tool | Minimum version | How to install |
|------|----------------|----------------|
| Node.js | 18 LTS | [nodejs.org](https://nodejs.org) or `nvm install 18` |
| npm | bundled with Node | — |
| Git | any | [git-scm.com](https://git-scm.com) |

**Choose one of two setup paths:**

| Path | Extra requirements | Command |
|------|-------------------|---------|
| **A — Docker** (recommended) | Docker + Docker Compose | `docker compose up --build` |
| **B — Local** | PostgreSQL 13+ | `bash setup.sh` |

> No Python, no Visual Studio Build Tools, no native compilers required.

---

## Path A — Docker (recommended)

One command brings up the full stack (app + PostgreSQL + schema migration):

```bash
git clone <repo-url>
cd ecommerce-chatbot
cp .env.example .env
docker compose up --build -d
```

Open http://localhost:3000 — the chatbot UI should load.

**Useful commands:**

```bash
docker compose logs -f app     # stream app logs
docker compose ps              # check service status
docker compose down -v         # stop & remove everything
make up                        # alias for docker compose up --build -d
```

> The `docker-compose.yml` creates a PostgreSQL container with the correct user, password, and database. The `db/docker-init.sql` schema is auto-imported on first start.

---

## Path B — Local (setup.sh)

### Step 1 — Clone and verify Node

```bash
git clone <repo-url>
cd ecommerce-chatbot
node --version   # must be v18+
```

If needed: `nvm install 18 && nvm use 18` (the `.nvmrc` file pins v18).

### Step 2 — Run the setup script

```bash
bash setup.sh
```

This checks runtimes, creates `.env` from `.env.example`, and installs dependencies.

### Step 3 — Configure `.env`

Open `.env` and fill in your PostgreSQL credentials:

```dotenv
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ebot
DB_USER=your_pg_username
DB_PASSWORD=your_pg_password
```

### Step 4 — Set up the database

```bash
psql -U postgres
```

Inside psql:

```sql
\i db/init.sql
```

This creates the `ebot` database and all tables.

### Step 5 — Start the app

```bash
npm start
```

Open http://localhost:3000.

---

## Verify routes

| Route | Method | Expected result |
|-------|--------|----------------|
| `/` | GET | Home page with chatbot UI |
| `/users` | GET | JSON array (empty if no data) |
| `/users/:id` | GET | JSON user object |
| `/users/username/:username` | GET | JSON user object |
| `/products` | GET | JSON array (empty if no data) |
| `/users` | POST | Creates user, returns 201 |
| `/users/:id` | PUT | Updates user, returns 200 |

---

## About `db-lectures/`

Course SQL exercises — **not required** to run the application.

| File | Purpose |
|------|---------|
| `aula1.sql` | Lesson 1 — basic SELECT / INSERT |
| `aula2.sql` | Lesson 2 — JOINs and filtering |
| `07.sql` | Section 7 exercises |
| `08.sql` | Section 8 exercises |
| `secao03.sql` | Section 3 exercises |
| `alter-drop.sql` | ALTER TABLE / DROP TABLE practice |

---

## Pain Point → Artifact Mapping

| Pain # | Tag | Pain Point | Artifact that fixes it | Status |
|--------|-----|------------|----------------------|--------|
| 1 | VERSION_HELL | Node ^8 with no upper bound, modern Node fails | `.nvmrc` pins Node 18; `package.json` `engines: ">=18"`; `setup.sh` checks version | **Fixed** |
| 2 | IMPLICIT_DEP | `node-sass` requires Python 2 + C++ build tools | `package.json` — replaced `node-sass` with `sass` (pure JS, zero native deps) | **Fixed** |
| 3 | BROKEN_CMD | `npm i` fails on Node > 12 | Follows from #2 — `sass` installs cleanly on any modern Node | **Fixed** |
| 4 | BROKEN_CMD | `npm start` fails (node-sass not found) | Follows from #2 — scripts updated to use `sass` CLI | **Fixed** |
| 5 | BROKEN_CMD | `compile:sass` README has inline comment | `package.json` scripts use clean `sass` syntax | **Fixed** |
| 6 | IMPLICIT_DEP | PostgreSQL not in prerequisites | `docker-compose.yml` bundles PostgreSQL; `setup.sh` checks for `psql` | **Fixed** |
| 7 | ENV_GAP | DB credentials hardcoded in `queries.js` | `db/queries.js` reads `process.env.*`; `.env.example` documents all vars | **Fixed** |
| 8 | MISSING_DOC | No DB setup instructions | `docker-compose.yml` auto-migrates; `setup.sh` prints step-by-step guide | **Fixed** |
| 9 | BROKEN_CMD | `init.sql` trailing comma syntax error | Fixed in `db/init.sql`; clean copy in `db/docker-init.sql` | **Fixed** |
| 10 | MISSING_DOC | Circular FK in schema unexplained | — | Out of Scope |
| 11 | MISSING_DOC | `db-lectures/` purpose unknown | Documented above in this file | **Fixed** |
| 12 | MISSING_DOC | UI in Portuguese, undocumented | — | Out of Scope |
| 13 | SILENT_FAIL | `package-lock.json` gitignored | `.gitignore` updated: `package-lock.json` no longer ignored | **Fixed** |
| 14 | MISSING_DOC | Sass/CSS relationship unclear | — | Out of Scope |
| 15 | ENV_GAP | `app.listen(undefined)` if PORT unset | `app.js` fixed: `const PORT = process.env.PORT \|\| 3000` | **Fixed** |

**Summary:** 12 Fixed · 3 Out of Scope · 0 Partial

---

## What the AI Got Wrong

> The deliverable requires documenting at least 2 things the AI hallucinated or that had to be manually corrected.

### 1. Dart Sass `@import` deprecation broke the Docker build

The AI replaced `node-sass` with `sass` (Dart Sass) in `package.json` and updated the Dockerfile to compile SCSS. However, it did **not** anticipate that Dart Sass treats `@import` as deprecated and emits deprecation warnings that, when combined with other issues, make the output look like a wall of errors. The `--silence-deprecation=import` flag had to be added manually to the Dockerfile's `RUN npx sass ...` command after the first failed build.

### 2. The AI missed a CSS syntax error exposed by the stricter Dart Sass parser

The original `sass/pages/_home.scss` file contained `@media screen and(max-width: 29em)` — missing a space between `and` and `(`. The old `node-sass` (LibSass) silently accepted this, but Dart Sass treats it as a hard error (`Error: Expected whitespace`). The AI did not flag this during planning or code review — it was only discovered when `docker compose up --build` failed at the sass compilation step. The fix was a one-character change (`and(` → `and (`), but it required a full rebuild cycle to diagnose.

### 3. The AI included `version: "3.8"` in `docker-compose.yml`

Modern Docker Compose (v2) no longer uses the `version` field — it's ignored and emits a warning: *"the attribute 'version' is obsolete"*. The AI generated the file with `version: "3.8"` based on outdated training data. This had to be removed manually after the first build showed the warning.

---

## Artifacts Committed

| File | Type | Description |
|------|------|-------------|
| `Dockerfile` | NEW | Multi-stage build: Node 18 + sass compilation |
| `docker-compose.yml` | NEW | Full stack: app + PostgreSQL 15 with healthcheck |
| `db/docker-init.sql` | NEW | Fixed SQL schema for Docker auto-migration |
| `.env.example` | NEW | All environment variables documented with comments |
| `.nvmrc` | NEW | Pins Node 18 for `nvm use` |
| `setup.sh` | NEW | Bootstrap script with runtime checks and colored output |
| `Makefile` | NEW | Common targets: `make setup`, `make up`, `make down` |
| `package.json` | MODIFIED | `node-sass` → `sass`, added `engines` field |
| `app.js` | MODIFIED | `dotenv` moved to line 1, PORT fallback fixed |
| `db/queries.js` | MODIFIED | Hardcoded DB creds → `process.env.*` |
| `db/init.sql` | MODIFIED | Fixed trailing comma + missing semicolon |
| `.gitignore` | MODIFIED | Removed `package-lock.json`, added `.env` |
| `sass/pages/_home.scss` | MODIFIED | Fixed `@media screen and(` syntax |
