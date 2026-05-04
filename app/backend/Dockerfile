<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 26285aa (feat: src code example)
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

USER node

EXPOSE 8080
<<<<<<< HEAD
=======
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

USER node

EXPOSE 8080
>>>>>>> 8edcc40 (feat: src code example)
=======
>>>>>>> 26285aa (feat: src code example)
CMD ["node", "index.js"]