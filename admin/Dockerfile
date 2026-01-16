# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Next.js build needs env vars at build time for NEXT_PUBLIC prefix.
# We define ARGs so these can be passed from CI, or use dummy values to prevent crashes.
ARG NEXT_PUBLIC_FIREBASE_API_KEY=placeholder
ARG NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=placeholder
ARG NEXT_PUBLIC_FIREBASE_PROJECT_ID=placeholder
ARG NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=placeholder
ARG NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=placeholder
ARG NEXT_PUBLIC_FIREBASE_APP_ID=placeholder
ARG NEXT_PUBLIC_API_URL=http://localhost:3000

# Set ENVs for the build process
ENV NEXT_PUBLIC_FIREBASE_API_KEY=$NEXT_PUBLIC_FIREBASE_API_KEY
ENV NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=$NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
ENV NEXT_PUBLIC_FIREBASE_PROJECT_ID=$NEXT_PUBLIC_FIREBASE_PROJECT_ID
ENV NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=$NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
ENV NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=$NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
ENV NEXT_PUBLIC_FIREBASE_APP_ID=$NEXT_PUBLIC_FIREBASE_APP_ID
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# We check for a local .env.local (present on EC2) to override the placeholders
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
ENV PORT=3001
CMD ["npm", "start"]
