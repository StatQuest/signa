#!/bin/bash
set -e  # Exit immediately if any command fails

echo "🛠️ Removing old Docker GPG key (if any)..."
sudo rm -f /etc/apt/keyrings/docker.gpg

echo "🔑 Adding Docker’s official GPG key using GnuPG..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "✅ Verifying the Docker GPG key..."
gpg --show-keys /etc/apt/keyrings/docker.gpg

echo "🗑️ Removing old Docker repository (if any)..."
sudo rm -f /etc/apt/sources.list.d/docker.list

echo "📌 Adding Docker repository for Ubuntu 22.04 (Jammy) to be used on Noble..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "🔄 Updating package list..."
sudo apt update -y

echo "📦 Installing Docker, Buildx, and Compose..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🚀 Starting Docker service..."
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl restart docker || {
    echo "❌ Docker failed to start. Checking for issues..."
    echo "🛠️ Resetting Docker storage (this will remove existing containers & images)..."
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo systemctl restart docker
}

echo "🧩 Checking if Docker service is running..."
sudo systemctl status docker --no-pager || {
    echo "❌ Docker is still failing to start. Trying full reinstall..."
    sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo rm -rf /var/lib/docker /var/lib/containerd
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl restart docker
}

echo "✅ Docker installed successfully!"

echo "🔧 Adding current user to the Docker group (to run without sudo)..."
sudo usermod -aG docker $USER
newgrp docker  # Apply group change immediately

echo "🔎 Checking Docker installation..."
docker --version
docker run hello-world || echo "⚠️ Docker test container failed, check logs."

echo "🔎 Checking Buildx installation..."
docker buildx version || {
    echo "📦 Installing Buildx manually..."
    mkdir -p ~/.docker/cli-plugins/
    curl -sSL https://github.com/docker/buildx/releases/latest/download/buildx-linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
}

echo "🔄 Restarting Docker service..."
sudo systemctl restart docker

echo "⚙️ Enabling BuildKit..."
export DOCKER_BUILDKIT=1
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
source ~/.bashrc

echo "🎉 Setup complete! Run 'docker buildx ls' to verify Buildx is working."
