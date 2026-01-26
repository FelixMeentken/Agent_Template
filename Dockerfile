# 1. Bau-Phase (Builder)
FROM node:18-alpine AS builder

WORKDIR /app

# Wir installieren grundlegende Tools (manchmal nötig für Node-Module)
RUN apk add --no-cache git python3 make g++

# Kopiere das ganze Repo in den Container
COPY . .

# --- HIER IST DER FIX ---
# Statt "npm run build" im Root aufzurufen, gehen wir direkt ins Frontend.
# Das verhindert den "Command not found" (127) Fehler.

WORKDIR /app/frontend
# Installiere Frontend-Abhängigkeiten
RUN npm install
# Baue das Frontend (Erstellt den dist Ordner)
RUN npm run build

# Zurück zum Hauptverzeichnis für den Rest
WORKDIR /app

# 2. Laufzeit-Phase (Runner)
FROM node:18-alpine AS runner

WORKDIR /app

# Auch im Runner brauchen wir evtl. Python für das Backend-Skript
RUN apk add --no-cache python3 make g++

# Kopiere die Root-Package-Dateien
COPY package*.json ./

# Installiere die Root-Abhängigkeiten (für das Backend-Start-Skript)
RUN npm install --omit=dev

# Kopiere das Backend
COPY backend ./backend

# Kopiere das fertig gebaute Frontend aus der Builder-Phase
# (Der Pfad ist jetzt sicher /app/frontend/dist)
COPY --from=builder /app/frontend/dist ./frontend/dist

# Kopiere den Rest des Frontends (manchmal braucht der Server Files von dort)
COPY --from=builder /app/frontend/package.json ./frontend/package.json

# WICHTIG: Mache das Start-Skript ausführbar
RUN chmod +x ./backend/scripts/run.sh

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Startbefehl
CMD ["npm", "run", "start"]
