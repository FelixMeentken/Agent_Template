# 1. Bau-Phase (Builder)
FROM node:18-alpine AS builder

# Arbeitsverzeichnis im Container erstellen
WORKDIR /app

# Abhängigkeiten installieren
COPY package*.json ./
RUN npm ci

# Den Rest des Codes kopieren
COPY . .

# Die App bauen (Frontend -> statische Dateien, Backend vorbereiten)
RUN npm run build

# 2. Laufzeit-Phase (Runner) - Das macht das Image klein und sicher
FROM node:18-alpine AS runner

WORKDIR /app

# Wir kopieren nur das Nötigste aus der Bau-Phase
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
# Falls es einen separaten Backend-Ordner oder server.js gibt, wird er meist durch den Build verarbeitet
# oder ist im Root. Bei managed-chatkit ist oft ein "server"-File wichtig.
# Wir kopieren zur Sicherheit alles Gebaute.

ENV NODE_ENV=production
ENV PORT=3000

# Port freigeben
EXPOSE 3000

# Startbefehl (Startet den Node-Server, der Frontend & API bedient)
CMD ["npm", "run", "start"]
