# ── Build Stage ──────────────────────────────
FROM node:18-slim AS build

# Install native build tools required by node-sass (node-gyp)
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 make g++ && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files first for layer caching
COPY package.json package-lock.json* ./
RUN npm install

# Copy application source
COPY . .

# Compile Sass → CSS
RUN npx sass sass/main.scss public/css/main.css --silence-deprecation=import

# ── Runtime Stage ────────────────────────────
FROM node:18-slim

WORKDIR /app

# Copy everything from the build stage
COPY --from=build /app .

EXPOSE 3000

CMD ["node", "app.js"]
