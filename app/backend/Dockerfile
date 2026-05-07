# ==========================================
# STAGE 1: Base 
# ==========================================
FROM node:20-alpine AS base

WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache libc6-compat

# ==========================================
# STAGE 2: Dependencies
# ==========================================
FROM base AS dependencies

COPY package*.json ./

RUN npm ci --only=production && npm cache clean --force

# ==========================================
# STAGE 3: Builder 
# ==========================================
FROM dependencies AS builder

COPY . .

RUN echo "Building and verifying backend for Startup X..."

# ==========================================
# STAGE 4: Runner 
# ==========================================
FROM base AS runner

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 expressjs

COPY --from=dependencies /app/node_modules ./node_modules

COPY --from=builder /app ./

USER expressjs

EXPOSE 8080

CMD ["node", "index.js"]