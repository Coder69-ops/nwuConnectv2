# Build stage
FROM node:20-alpine AS builder

WORKDIR /app



# We check for a local .env.local (present on EC2) to override the placeholders
RUN if [ -f .env.local ]; then cp .env.local .env.production; else touch .env.production; fi

RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Prune dev dependencies before copying
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
RUN npm prune --production
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.ts ./

EXPOSE 3001

# Next.js default port is 3000, we force 3001 to avoid conflict if on same network
ENV PORT=3001
CMD ["npm", "start"]
