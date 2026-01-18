#!/bin/bash

echo "🧹 Starting Docker Cleanup..."

# Prune stopped containers, unused networks, and dangling images
echo "STEP 1: System Prune (Containers, Networks, Dangling Images)..."
docker system prune -f

# Prune unused volumes (be careful if you use named volumes for persistence)
# We use --filter to avoid removing volumes currently in use, but user should verify.
# echo "STEP 2: Volume Prune..."
# docker volume prune -f

# Explicitly remove the admin-stage-1 intermediate images if they are dangling
echo "STEP 3: Removing Dangling Build Layers..."
docker image prune -f

echo "✅ Cleanup Complete. Disk space usage:"
df -h
