# 1. Bau-Phase (Builder)
FROM node:18-alpine AS builder

WORKDIR /app

# Abhängigkeiten kopieren
COPY package*.json ./

# Abhängigkeiten installieren
RUN npm ci

# Den restlichen Code kopieren
COPY . .

# Umgebungsvariablen für den Build (verhindert manche Vite-Warnungen)
ENV NODE_ENV=production

# Bauen (Dies erstellt /app/frontend/dist)
RUN npm run build

# 2. Laufzeit-Phase (Runner)
FROM node:18-alpine AS runner

WORKDIR /app

# Wir brauchen python3 für manche Backend-Skripte (falls nötig), sicherheitshalber installieren
RUN apk add --no-cache python3 make g++

# Kopiere package.json und installiere nur Production-Deps
COPY package*.json ./
RUN npm ci --omit=dev

# --- HIER WAR DER FEHLER ---
# Wir kopieren den gebauten 'dist' Ordner aus dem frontend-Unterverzeichnis
# an die gleiche Stelle im neuen Container
COPY --from=builder /app/frontend/dist ./frontend/dist
# ---------------------------

# Kopiere den Backend-Code und den Rest (damit der Server läuft)
COPY --from=builder /app/backend ./backend
COPY --from=builder /app/frontend ./frontend

# WICHTIG: Das Start-Skript ausführbar machen
RUN chmod +x ./backend/scripts/run.sh

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Startbefehl
CMD ["npm", "run", "start"]
