#!/bin/bash

# 1. Update System
echo "🔄 Updating System..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install Docker & Git
echo "🐳 Installing Docker & Git..."
sudo apt-get install -y docker.io docker-compose git

# 3. Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# 4. Create Project Directory
mkdir -p ~/NWUC

echo "✅ Server Ready! You can now logout and log back in (to apply Docker permissions)."
echo "   Then clone your repo:"
echo "   git clone <YOUR_REPO_URL> ~/NWUC"
