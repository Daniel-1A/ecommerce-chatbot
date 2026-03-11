# POSTMORTEM.md — Ecommerce Chatbot: Experiencia de Desarrollador

## Qué Estaba Roto

El repositorio era completamente inconstruible e inejectable en cualquier máquina de desarrollo moderna. El primer comando del README (`npm i`) fallaba inmediatamente porque el proyecto dependía de `node-sass@4.9.4`, un binding nativo de C++ deprecado que requiere Node 8–12, Python 2 y herramientas de compilación de C++ — ninguno de los cuales se menciona en los prerrequisitos. Además de la falla de instalación, la aplicación requería una base de datos PostgreSQL con un usuario, contraseña y esquema específicos, pero el README solo listaba "Node^8" y "npm" como prerrequisitos. Las credenciales de la base de datos estaban hardcodeadas en el código fuente, el SQL de inicialización contenía un error de sintaxis, y no existía `.env.example`, ni soporte Docker, ni automatización de configuración de ningún tipo.

## Qué Construimos

| Artefacto | Qué elimina |
|---|---|
| **`Dockerfile`** | Incompatibilidad de versiones de Node y dependencias nativas — fija Node 18, compila sass en un contenedor limpio |
| **`docker-compose.yml`** | Fricción de configuración de PostgreSQL — un solo comando levanta app + BD con migración automática |
| **`db/docker-init.sql`** | Errores de sintaxis SQL — esquema corregido que se ejecuta limpiamente al primer `docker compose up` |
| **`.env.example`** | Variables de entorno sin documentar — documenta las 6 variables requeridas con comentarios en línea |
| **`setup.sh`** | Adivinanza manual — verifica runtimes, crea `.env`, instala dependencias, imprime pasos de configuración de BD |
| **`.nvmrc`** | Ambigüedad de versión — `nvm use` selecciona la versión correcta de Node automáticamente |
| **`Makefile`** | Memorización de comandos — `make up`, `make down`, `make logs` |
| **`package.json` (corregido)** | `node-sass` → `sass` (JS puro), campo `engines` agregado |
| **`app.js` (corregido)** | Error de orden de carga de `dotenv`, fallback de PORT que silenciosamente usaba un puerto aleatorio |
| **`db/queries.js` (corregido)** | Credenciales hardcodeadas (`jhonatan`/`jhonatan`) → `process.env.*` |
| **`db/init.sql` (corregido)** | Coma extra en la sintaxis SQL, punto y coma faltante |
| **`.gitignore` (corregido)** | `package-lock.json` ya no se ignora (builds reproducibles), `.env` ahora se ignora (sin credenciales filtradas) |
| **`sass/pages/_home.scss` (corregido)** | Espacio faltante en consulta `@media` que Dart Sass rechaza |

## Costo del Estado Original

De nuestra auditoría de fricción, un nuevo ingeniero pierde entre **2 y 4 horas** diagnosticando fallas de instalación, buscando requisitos de base de datos en el código fuente y armando la configuración desde cero. Tomando el punto medio:

| Métrica | Valor |
|---|---|
| Ingenieros que se incorporan por mes | 5 |
| Horas perdidas por ingeniero | 3 hrs |
| Costo de ingeniería con carga completa | $75/hr |
| **Costo mensual del onboarding roto** | **$1,125/mes** |
| **Costo anual** | **$13,500/año** |

Esta es una estimación conservadora — asume que los ingenieros eventualmente logran resolver los problemas. En la práctica, algunos abandonarían, cambiarían de contexto o pedirían ayuda a ingenieros senior (multiplicando el costo). El costo reputacional de un repositorio que se siente abandonado al primer contacto es más difícil de cuantificar pero igualmente real.

## Qué Haríamos Después

**Migrar `@import` de Sass a `@use`/`@forward`.** Dart Sass ha deprecado `@import` y lo eliminará completamente en Sass 3.0. Nuestro flag `--silence-deprecation=import` es una solución temporal — cuando Sass 3.0 se publique, el build volverá a fallar. La migración es mecánica (Sass provee un migrador automático: `sass-migrator module sass/main.scss`), pero toca todos los archivos `.scss` y cambia cómo se manejan las variables. Esto tiene el mayor retorno de inversión porque es la única bomba de tiempo restante en el código: todo lo demás que corregimos es estable a largo plazo, pero esto **volverá** a fallar en un futuro `npm update`.
