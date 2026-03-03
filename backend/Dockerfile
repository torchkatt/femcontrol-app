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

# Exponer estrictamente el puerto 443
EXPOSE 443

# Comando para iniciar la aplicación (asegúrate de que tu server escuche en el 443)
CMD ["node", "dist/server.js"]
