# Dockerfile para el Backend Node.js
FROM node:18-alpine

# Install openssl and libc6-compat for Prisma
RUN apk add --no-cache openssl openssl-dev libc6-compat

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

# Prisma generate
RUN npx prisma generate

RUN npm run build

# Cloud Run usa el puerto 8080 por defecto
EXPOSE 8080

# Iniciar servidor asegurando que la base de datos esté migrada
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
