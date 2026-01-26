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

#  Zwinge das Skript, auf 0.0.0.0 zu hören
# Wir ersetzen "127.0.0.1" durch "0.0.0.0" direkt in der Datei
RUN sed -i 's/127.0.0.1/0.0.0.0/g' ./backend/scripts/run.sh
# Sicherheitshalber auch "localhost" ersetzen, falls es so drin steht
RUN sed -i 's/localhost/0.0.0.0/g' ./backend/scripts/run.sh

# Ausführbar machen
RUN chmod +x ./backend/scripts/run.sh

ENV NODE_ENV=production
ENV PORT=8000
EXPOSE 8000

CMD ["npm", "run", "start"]
