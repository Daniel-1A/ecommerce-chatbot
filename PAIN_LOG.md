# Deliverable 1 — Pain Log

## Auditoría de fricción — ecommerce-chatbot

1. [MISSING_DOC]

El README indica que el proyecto requiere Node ^8, pero no proporciona instrucciones sobre cómo instalar o cambiar a esa versión.

El repositorio tampoco incluye archivos comunes para gestionar versiones como `nvm` o un Dockerfile.

Esto obliga a investigar manualmente cómo instalar o cambiar la versión de Node.

Severidad: MEDIA — genera fricción en el setup inicial.

### 2. [BROKEN_CMD]

Al ejecutar `npm install` siguiendo las instrucciones del README, la instalación falla durante la compilación de la dependencia `node-sass`.

El proceso termina con `Build failed with error code: 1`, por lo que no es posible completar la instalación de dependencias.

Severidad: BLOCKER — no se pueden instalar las dependencias del proyecto.

### 3. [IMPLICIT_DEP]

Durante la instalación de dependencias, `node-gyp` intenta encontrar `python2` o `python` para compilar `node-sass`.

Aunque Python está instalado en el sistema (Python 3.12), el proceso de instalación no logra detectarlo correctamente y muestra el error:

"Can't find Python executable 'python'".

El README no menciona que Python sea un requisito ni qué versión es compatible para compilar dependencias nativas.

Severidad: ALTA — la instalación de dependencias falla debido a requisitos del sistema no documentados.

### 4. [IMPLICIT_DEP]

El proyecto utiliza `node-sass`, el cual requiere herramientas de compilación nativas (`node-gyp`).

El README no menciona que en Windows se necesitan herramientas de compilación como:

- Python
- Visual Studio Build Tools

Esto provoca que la instalación falle en entornos nuevos.

Severidad: ALTA.

### 5. [VERSION_HELL]

Durante la instalación aparece que `node-gyp` está utilizando Node v25.0.0 mientras que el proyecto fue diseñado para Node ^8.

Esto provoca incompatibilidad con dependencias antiguas como `node-sass`.

El README menciona Node ^8 pero no proporciona una forma sencilla de usar esa versión.

Severidad: ALTA.

### 6. [BROKEN_CMD]

El README indica ejecutar `npm start` para iniciar la aplicación.  
Sin embargo, al ejecutarlo aparece el siguiente error:

'node-sass' is not recognized as an internal or external command.

Esto ocurre porque `npm install` falla previamente y las dependencias no se instalan correctamente, por lo que el script de inicio no puede ejecutarse.

Severidad: BLOCKER — la aplicación no puede iniciarse.

### 7. [ENV_GAP]

El repositorio incluye un archivo `.env`, pero no existe un archivo `.env.example` que documente las variables necesarias para configurar el entorno.

Esto dificulta conocer qué variables son requeridas o qué valores se deben utilizar.

Severidad: MEDIA — configuración del entorno poco clara.

### 8. [MISSING_DOC]

Existe una carpeta `db` con un archivo `init.sql`, lo que indica que el proyecto requiere una base de datos.

Sin embargo, el README no explica:

- qué base de datos se debe utilizar
- cómo crear la base de datos
- cómo ejecutar el script `init.sql`

Severidad: ALTA — la aplicación probablemente no funcionará sin la base de datos configurada.

### 9. [MISSING_DOC]

El repositorio contiene múltiples scripts SQL en la carpeta `db-lectures`, pero no existe documentación que explique:

- si estos scripts son necesarios
- en qué orden deben ejecutarse
- si forman parte de migraciones o datos de ejemplo

Esto genera confusión sobre cómo preparar correctamente la base de datos.

Severidad: MEDIA.

### 10. [MISSING_DOC]

El archivo `.env` solo contiene la variable `PORT=3000`.

No se documenta si existen otras variables de entorno necesarias para la conexión a la base de datos u otros servicios.

Severidad: MEDIA.

## Severity Summary

Total friction points found: 10

First complete blocker encountered:
El primer bloqueo crítico ocurre durante `npm install`, cuando falla la compilación de la dependencia `node-sass` debido a incompatibilidades de versión y requisitos del sistema no documentados.

Estimated time lost for a new hire:
Entre 2 y 4 horas intentando diagnosticar problemas de versión de Node, dependencias nativas (node-gyp), requisitos del sistema (Python / build tools) y configuración de base de datos.    