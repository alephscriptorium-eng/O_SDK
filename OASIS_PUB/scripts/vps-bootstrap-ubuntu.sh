#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required for this bootstrap script."
  exit 1
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg ufw git rsync

. /etc/os-release
DOCKER_DISTRO="ubuntu"
if [ "${ID:-}" = "debian" ]; then
  DOCKER_DISTRO="debian"
fi

sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DOCKER_DISTRO} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8008/tcp
sudo ufw --force enable

cat <<'MSG'
VPS bootstrap complete.
Log out and back in so your user gets Docker group permissions.
Recommended repo path: /srv/oasis-scriptorium or /opt/oasis-scriptorium.
MSG
