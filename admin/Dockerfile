# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
# Next.js build needs env vars at build time for NEXT_PUBLIC prefix
# We use a conditional copy to avoid failing in CI/CD where the file is ignored
RUN if [ -f .env.local ]; then cp .env.local .env.production; else touch .env.production; fi
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./

EXPOSE 3001

# Next.js default port is 3000, we force 3001 to avoid conflict if on same network
ENV PORT 3001
CMD ["npm", "start"]
