#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg

# Install Docker (cara modern)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable --now docker

# Buat Custom Network untuk DNS Resolution internal Docker
docker network create proxy-network

# Install Portainer
docker volume create portainer_data
docker run -d \
  -p 127.0.0.1:9000:9000 \
  --name portainer \
  --network proxy-network \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Install Nginx Proxy Manager
docker volume create npm_data
docker volume create npm_letsencrypt

docker run -d \
  -p 80:80 \
  -p 443:443 \
  -p 127.0.0.1:81:81 \
  --name nginx-proxy-manager \
  --network proxy-network \
  --restart=always \
  -v npm_data:/data \
  -v npm_letsencrypt:/etc/letsencrypt \
  jc21/nginx-proxy-manager:latest
