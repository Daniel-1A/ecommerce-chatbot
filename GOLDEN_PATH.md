# GOLDEN_PATH.md — ecommerce-chatbot - stup.sh

End-to-end verified setup path for a new contributor on a clean machine.

---

## Prerequisites

| Tool | Minimum version | How to install |
|------|----------------|----------------|
| Node.js | 18 LTS | [nodejs.org](https://nodejs.org) or `nvm install 18` |
| npm | bundled with Node | — |
| PostgreSQL | 13+ | [postgresql.org/download](https://www.postgresql.org/download/) |
| Git | any | [git-scm.com](https://git-scm.com) |

> No Python, no Visual Studio Build Tools, no native compilers required.

---

## Step 1 — Clone the repo

```bash
git clone <repo-url>
cd ecommerce-chatbot
```

---

## Step 2 — Verify Node version

```bash
node --version   # must be v18 or higher
```

If it is not, switch with nvm:

```bash
nvm install 18
nvm use 18
```

The `.nvmrc` file at the repo root pins the correct version — `nvm use` with no argument will read it automatically.

---

## Step 3 — Bootstrap the environment

Run the setup script. It checks runtimes, creates `.env`, and installs dependencies:

```bash
bash setup.sh
```

Expected output (clean machine):

```
━━━ Runtime: Node.js ━━━
[OK]    Node v18.x.x — meets minimum v18

━━━ Runtime: npm ━━━
[OK]    npm 10.x.x

━━━ Runtime: PostgreSQL ━━━
[OK]    psql (PostgreSQL) 16.x.x

━━━ Environment: .env ━━━
[OK]    .env created from .env.example

━━━ Dependencies: npm install ━━━
[OK]    npm install completed successfully

━━━ Database Setup ━━━
...instructions printed...

━━━ Setup Complete ━━━
[OK]    All checks passed.
```

If any step fails, the script exits with a descriptive error message pointing at the fix.

---

## Step 4 — Configure environment variables

Open `.env` (auto-created from `.env.example`) and fill in your PostgreSQL credentials:

```dotenv
PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=ebot
DB_USER=your_pg_username
DB_PASSWORD=your_pg_password
```

---

## Step 5 — Set up the database

Connect to PostgreSQL as a superuser and run the schema:

```bash
psql -U postgres
```

Inside psql:

```sql
\i db/init.sql
```

This creates the `ebot` database and all tables (`sellers`, `categories`, `products`, `users`, `addresses`, `credit_cards`, `transactions`, `shippings`, `orders`).

> **Known issue in init.sql:** the `categories` table definition has a trailing comma after its last column. If psql errors on that statement, open `db/init.sql`, remove the trailing comma, and re-run.

---

## Step 6 — Start the app

```bash
npm start
```

This compiles SCSS to `public/css/main.css` once, then starts the server with nodemon on the port defined in `.env` (default `3000`).

To watch SCSS changes during development:

```bash
npm run compile:sass
```

Open `http://localhost:3000` in your browser.

---

## Step 7 — Verify routes

| Route | Method | Expected result |
|-------|--------|----------------|
| `/` | GET | Home page renders |
| `/users` | GET | JSON array of users |
| `/users/:id` | GET | JSON user object |
| `/users/username/:username` | GET | JSON user object |
| `/products` | GET | JSON array of products |
| `/users` | POST | Creates user, returns 201 |
| `/users/:id` | PUT | Updates user, returns 200 |

---

## About db-lectures/

The files in `db-lectures/` are **course SQL exercises** — they are not required to run the application.

| File | Purpose |
|------|---------|
| `aula1.sql` | Lesson 1 — basic SELECT / INSERT |
| `aula2.sql` | Lesson 2 — JOINs and filtering |
| `07.sql` | Section 7 exercises |
| `08.sql` | Section 8 exercises |
| `secao03.sql` | Section 3 exercises |
| `alter-drop.sql` | ALTER TABLE / DROP TABLE practice |

Run any of them manually if needed:

```bash
psql -U your_pg_username -d ebot -f db-lectures/<filename>.sql
```

---

## Artifacts committed to fix Pain Log blockers

| Pain # | Type | Pain Point | Artifact | Status |
|--------|------|------------|----------|--------|
| #1 | MISSING_DOC | No Node version documented, no nvm file | `.nvmrc` pins Node 18; `setup.sh` §1 checks version at runtime | **Fixed** |
| #2 | BROKEN_CMD | `npm install` fails — `node-sass` native compile error | `package.json` — `node-sass` replaced with `sass` (pure JS, no C bindings) | **Fixed** |
| #3 | IMPLICIT_DEP | `node-gyp` can't find Python | Eliminated by removing `node-sass`; `sass` has no native dependencies | **Fixed** |
| #4 | IMPLICIT_DEP | Windows Build Tools required, undocumented | Eliminated by removing `node-sass`; no build toolchain needed | **Fixed** |
| #5 | VERSION_HELL | Node v25 incompatible with Node ^8 deps | `engines: ">=18"` in `package.json` + `.nvmrc` + `setup.sh` version gate | **Fixed** |
| #6 | BROKEN_CMD | `npm start` fails because install never succeeded | Follows from #2 — once `npm install` passes, `npm start` works | **Fixed** |
| #7 | ENV_GAP | No `.env.example`, required config opaque | `.env.example` with all variables documented; `setup.sh` auto-copies it | **Fixed** |
| #8 | MISSING_DOC | DB setup undocumented (which DB, how to run init.sql) | `setup.sh` §6 prints step-by-step instructions; documented here in §5 | **Fixed** |
| #9 | MISSING_DOC | `db-lectures/` purpose and order unknown | `db-lectures/README.md` lists each file's purpose and run command | **Fixed** |
| #10 | MISSING_DOC | `.env` only had `PORT`, DB vars missing | `.env.example` documents all 6 required variables with inline comments | **Fixed** |
