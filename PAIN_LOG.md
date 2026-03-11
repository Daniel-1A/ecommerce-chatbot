# PAIN_LOG.md — Ecommerce Chatbot Setup Audit

> **Auditor environment:** Node v22.22.0, npm 10.9.4, Linux (Fedora 43), Python 3.x  
> **Date:** 2026-03-10  
> **Method:** Followed README.md instructions verbatim on a clean checkout.

---

## Friction Points

1. **[VERSION_HELL]** README says "Node^8" but does not specify an upper bound. The project's core dev-dependency (`node-sass@^4.9.4`) requires **Node 8–12** and will **not compile** on Node 14+. A new engineer running any modern Node version (16, 18, 20, 22) is dead on arrival.  
   **Severity: BLOCKER** — `npm i` fails with a native compilation error. No workaround is documented.

2. **[IMPLICIT_DEP]** `node-sass` requires **Python 2** and a **C++ build toolchain** (`make`, `g++`) for its native `node-gyp` build step. Neither is listed in the Prerequisites section. On modern systems with only Python 3, `node-gyp@3.8.0` crashes with `SyntaxError: Missing parentheses in call to 'print'`.  
   **Severity: BLOCKER** — even if the correct Node version is used, missing build tools cause the same install failure.

3. **[BROKEN_CMD]** `npm i` (step 1 in Installation) **fails as written** on any Node version > 12. The error output is ~80 lines of gyp noise with no actionable fix suggested.  
   **Severity: BLOCKER** — nothing can proceed past this step.

4. **[BROKEN_CMD]** `npm start` fails with `sh: node-sass: command not found` because the install step failed. Even if corrected, the `start` script runs `node-sass` as a shell command (expects it in `$PATH`), which only works if installed globally or via `npx`.  
   **Severity: BLOCKER** — cascading failure from #3.

5. **[BROKEN_CMD]** `npm run compile:sass // watch sass change` — the `// watch sass change` part is a JS-style comment embedded in a shell command in the README. A new engineer copying this line verbatim gets a shell error. Should be `npm run compile:sass` with the comment on a separate line.  
   **Severity: MINOR** — confusing but guessable.

6. **[IMPLICIT_DEP]** The app requires a running **PostgreSQL** server. PostgreSQL is **not listed** in the Prerequisites section (only "Node^8" and "npm" are listed). A new engineer has no idea they need to install, start, and configure PostgreSQL.  
   **Severity: BLOCKER** — even with Node/npm fixed, the app crashes at startup when it can't connect to Postgres.

7. **[ENV_GAP]** Database connection parameters are **hardcoded** in `db/queries.js`:  
   ```js
   user: 'jhonatan', host: 'localhost', database: 'ebot',
   password: 'jhonatan', port: 5432
   ```  
   There is no `.env.example`, no documentation of required environment variables, and the existing `.env` file only contains `PORT=3000`. A new engineer must **read the source code** to discover they need a PostgreSQL user named `jhonatan` with password `jhonatan` and a database called `ebot`. The password is also committed to version control in plaintext.  
   **Severity: BLOCKER** — app will crash with `ECONNREFUSED` or auth error; no docs explain what DB to create.

8. **[MISSING_DOC]** There are **no instructions** for setting up the database. The repo includes `db/init.sql` with `CREATE DATABASE ebot` and table definitions, but the README never mentions running it. A new engineer would need to discover this file independently and figure out: `psql -U postgres -f db/init.sql`.  
   **Severity: BLOCKER** — without the schema, all API routes (`/users`, `/products`) throw errors.

9. **[BROKEN_CMD]** `db/init.sql` contains a **SQL syntax error** on line 31 — a trailing comma in the `categories` table definition:  
   ```sql
   CREATE TABLE categories(
       id SERIAL PRIMARY KEY,
       category_name VARCHAR(150) NOT NULL,   -- ← trailing comma = syntax error
   );
   ```  
   Even if an engineer finds and runs the init script, it will **fail partway through**, leaving the database in an inconsistent state (some tables created, some not).  
   **Severity: HIGH** — silent partial failure; tables created before the error succeed, tables after it don't.

10. **[MISSING_DOC]** The `db/init.sql` has a circular dependency issue: `categories` table adds a `product_id` column referencing `products(id)`, but `products` already references `categories(id)`. The `ALTER TABLE` on line 64 works around this, but it's never explained and could confuse engineers trying to understand the schema.  
    **Severity: LOW** — works if run in order, but undocumented and fragile.

11. **[MISSING_DOC]** The README says nothing about the `db-lectures/` directory which contains 6 SQL files (`07.sql`, `08.sql`, `alter-drop.sql`, `aula1.sql`, `aula2.sql`, `secao03.sql`). These appear to be **classroom exercise files** unrelated to the application. A new engineer may waste time trying to understand if they're needed.  
    **Severity: LOW** — noise that slows onboarding.

12. **[MISSING_DOC]** The chatbot UI is entirely in **Portuguese** (e.g., "Olá, eu sou o ebot!", "Enviar", "Digite commands para saber a lista de comandos") but nothing in the README mentions this. The project name, README, and code comments are in English. A non-Portuguese-speaking engineer would be confused by the UI text.  
    **Severity: LOW** — doesn't block functionality, but unexpected.

13. **[SILENT_FAIL]** The `.gitignore` excludes `package-lock.json` and `yarn.lock`. This means **dependency versions are not pinned**, so different developers will get different versions of transitive dependencies. Combined with the ancient `node-sass` requirement, this makes reproducible builds impossible.  
    **Severity: HIGH** — builds are non-deterministic across machines even when Node version matches.

14. **[MISSING_DOC]** The `public/css/main.css` (compiled output) is committed to the repo, but the README never explains the relationship between the `sass/` directory and `public/css/`. The `compile:sass` command is listed as a third step but is actually **also run by `npm start`** (the start script runs `node-sass` first, then `nodemon`). The README makes it look like a separate required step.  
    **Severity: LOW** — misleading but not blocking.

15. **[ENV_GAP]** The `app.js` file uses `process.env.PORT` to set the listening port, with a fallback `|| 3000` only in the **log message** (not the actual `.listen()` call). If `.env` is missing or `PORT` is unset, `app.listen(undefined)` would bind to a random port silently.  
    **Severity: MEDIUM** — `.env` is committed so it works by accident, but the fallback logic is broken.

---

## Severity Summary

| Metric | Value |
|---|---|
| **Total friction points found** | **15** |
| **BLOCKER-level issues** | **6** (#1, #2, #3, #4, #6, #7, #8) |
| **HIGH-level issues** | **2** (#9, #13) |
| **MEDIUM-level issues** | **1** (#15) |
| **LOW/MINOR issues** | **4** (#5, #10, #11, #12, #14) |
| **First complete blocker** | **Step 1 — `npm i`** (the very first command) |
| **How far a new hire gets** | Cannot get past `npm install`. Zero functionality is reachable. |
| **Estimated time lost** | **2–4 hours** (researching node-sass, downgrading Node, finding/installing PostgreSQL, discovering hardcoded creds, debugging init.sql syntax, piecing together the full setup from source code) |

### Root Cause

The project was written for **Node 8** circa 2018–2019 and uses `node-sass`, a native C++ binding that has been **deprecated** and replaced by the pure-JS `sass` (Dart Sass) package. Combined with zero database setup documentation and hardcoded credentials, this repo is effectively **unbuildable and unrunnable** from the README alone on any modern development machine.

### Recommended Fixes (if the project were to be maintained)

1. Replace `node-sass` with `sass` (Dart Sass) — no native compilation needed
2. Add PostgreSQL to Prerequisites, with version and install instructions
3. Add a "Database Setup" section to the README with step-by-step `psql` commands
4. Fix the trailing comma SQL syntax error in `db/init.sql`
5. Move DB credentials to `.env` and create a `.env.example`
6. Add `engines` field to `package.json` specifying supported Node versions
7. Stop gitignoring `package-lock.json`
8. Remove or move `db-lectures/` out of the main repository
