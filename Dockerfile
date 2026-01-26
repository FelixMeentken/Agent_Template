# 1. Bau-Phase (Builder)
FROM node:18-alpine AS builder

WORKDIR /app

# Basis-Tools für Installation
RUN apk add --no-cache git python3 make g++

COPY . .

# Frontend bauen
WORKDIR /app/frontend
RUN npm install
RUN npm run build

# Zurück zum Root
WORKDIR /app

# 2. Laufzeit-Phase (Runner)
FROM node:18-alpine AS runner

WORKDIR /app

# HIER IST DER FIX: Wir installieren 'bash'
RUN apk add --no-cache python3 make g++ bash

# Dateien kopieren
COPY package*.json ./
RUN npm install --omit=dev

COPY backend ./backend
COPY --from=builder /app/frontend/dist ./frontend/dist
COPY --from=builder /app/frontend/package.json ./frontend/package.json

# Windows-Zeilenumbrüche entfernen (Sicherheitsnetz)
RUN sed -i 's/\r$//' ./backend/scripts/run.sh

# Ausführbar machen
RUN chmod +x ./backend/scripts/run.sh

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

CMD ["npm", "run", "start"]
