# GOLDEN_PATH.md — ecommerce-chatbot - setup.sh

Ruta de configuración verificada de extremo a extremo para un nuevo contribuidor en una máquina limpia.

---

## Prerequisitos

| Herramienta | Versión mínima | Cómo instalar |
|-------------|---------------|---------------|
| Node.js | 18 LTS | [nodejs.org](https://nodejs.org) o `nvm install 18` |
| npm | incluido con Node | — |
| PostgreSQL | 13+ | [postgresql.org/download](https://www.postgresql.org/download/) |
| Git | cualquiera | [git-scm.com](https://git-scm.com) |

> No se requiere Python, Visual Studio Build Tools ni compiladores nativos.

---

## Paso 1 — Clonar el repositorio

```bash
git clone <repo-url>
cd ecommerce-chatbot
```

---

## Paso 2 — Verificar la versión de Node

```bash
node --version   # debe ser v18 o superior
```

Si no lo es, cambia de versión con nvm:

```bash
nvm install 18
nvm use 18
```

El archivo `.nvmrc` en la raíz del repositorio fija la versión correcta — `nvm use` sin argumentos lo lee automáticamente.

---

## Paso 3 — Inicializar el entorno

Ejecuta el script de configuración. Verifica los runtimes, crea `.env` e instala las dependencias:

```bash
bash setup.sh
```

Salida esperada (máquina limpia):

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
...instrucciones impresas...

━━━ Setup Complete ━━━
[OK]    All checks passed.
```

Si algún paso falla, el script termina con un mensaje de error descriptivo que indica cómo resolverlo.

---

## Paso 4 — Configurar las variables de entorno

Abre `.env` (creado automáticamente desde `.env.example`) y completa tus credenciales de PostgreSQL:

```dotenv
PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=ebot
DB_USER=tu_usuario_pg
DB_PASSWORD=tu_contraseña_pg
```

---

## Paso 5 — Configurar la base de datos

Conéctate a PostgreSQL como superusuario y ejecuta el esquema:

```bash
psql -U postgres
```

Dentro de psql:

```sql
\i db/init.sql
```

Esto crea la base de datos `ebot` y todas las tablas (`sellers`, `categories`, `products`, `users`, `addresses`, `credit_cards`, `transactions`, `shippings`, `orders`).

> **Problema conocido en init.sql:** la definición de la tabla `categories` tiene una coma al final del último campo. Si psql reporta un error en esa instrucción, abre `db/init.sql`, elimina la coma y vuelve a ejecutar el script.

---

## Paso 6 — Iniciar la aplicación

```bash
npm start
```

Esto compila el SCSS a `public/css/main.css` una vez y luego inicia el servidor con nodemon en el puerto definido en `.env` (por defecto `3000`).

Para observar cambios en SCSS durante el desarrollo:

```bash
npm run compile:sass
```

Abre `http://localhost:3000` en tu navegador.

---

## Paso 7 — Verificar las rutas

| Ruta | Método | Resultado esperado |
|------|--------|--------------------|
| `/` | GET | Se renderiza la página de inicio |
| `/users` | GET | Arreglo JSON de usuarios |
| `/users/:id` | GET | Objeto JSON del usuario |
| `/users/username/:username` | GET | Objeto JSON del usuario |
| `/products` | GET | Arreglo JSON de productos |
| `/users` | POST | Crea usuario, retorna 201 |
| `/users/:id` | PUT | Actualiza usuario, retorna 200 |

---

## Sobre db-lectures/

Los archivos en `db-lectures/` son **ejercicios SQL del curso** — no son necesarios para ejecutar la aplicación.

| Archivo | Propósito |
|---------|-----------|
| `aula1.sql` | Lección 1 — SELECT / INSERT básico |
| `aula2.sql` | Lección 2 — JOINs y filtros |
| `07.sql` | Ejercicios de la sección 7 |
| `08.sql` | Ejercicios de la sección 8 |
| `secao03.sql` | Ejercicios de la sección 3 |
| `alter-drop.sql` | Práctica de ALTER TABLE / DROP TABLE |

Para ejecutar cualquiera de ellos manualmente:

```bash
psql -U tu_usuario_pg -d ebot -f db-lectures/<archivo>.sql
```

---

## Artefactos para resolver los bloqueos del Pain Log

| Pain # | Tipo | Problema | Artefacto | Estado |
|--------|------|----------|-----------|--------|
| #1 | MISSING_DOC | Versión de Node no documentada, sin archivo nvm | `.nvmrc` fija Node 18; `setup.sh` §1 verifica la versión en tiempo de ejecución | **Resuelto** |
| #2 | BROKEN_CMD | `npm install` falla — error de compilación nativa de `node-sass` | `package.json` — `node-sass` reemplazado por `sass` (JS puro, sin bindings en C) | **Resuelto** |
| #3 | IMPLICIT_DEP | `node-gyp` no encuentra Python | Eliminado al remover `node-sass`; `sass` no tiene dependencias nativas | **Resuelto** |
| #4 | IMPLICIT_DEP | Se requieren Windows Build Tools, no documentado | Eliminado al remover `node-sass`; no se necesita toolchain de compilación | **Resuelto** |
| #5 | VERSION_HELL | Node v25 incompatible con dependencias de Node ^8 | `engines: ">=18"` en `package.json` + `.nvmrc` + verificación de versión en `setup.sh` | **Resuelto** |
| #6 | BROKEN_CMD | `npm start` falla porque la instalación nunca se completó | Derivado del #2 — una vez que `npm install` pasa, `npm start` funciona | **Resuelto** |
| #7 | ENV_GAP | Sin `.env.example`, configuración opaca | `.env.example` con todas las variables documentadas; `setup.sh` lo copia automáticamente | **Resuelto** |
| #8 | MISSING_DOC | Configuración de BD no documentada (qué BD, cómo ejecutar init.sql) | `setup.sh` §6 imprime instrucciones paso a paso; documentado aquí en §5 | **Resuelto** |
| #9 | MISSING_DOC | Propósito y orden de scripts en `db-lectures/` desconocidos | `db-lectures/README.md` lista el propósito de cada archivo y el comando para ejecutarlo | **Resuelto** |
| #10 | MISSING_DOC | `.env` solo tenía `PORT`, sin variables de BD | `.env.example` documenta las 6 variables requeridas con comentarios | **Resuelto** |
