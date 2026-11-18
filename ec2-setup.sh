#!/bin/bash
# Run on a fresh Ubuntu 24.04 EC2 instance:  bash ec2-setup.sh
set -e

# 1) 2 GB swap so Jenkins + Docker + scikit-learn fit on a small instance
if ! swapon --show | grep -q swapfile; then
  sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
  sudo mkswap /swapfile && sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# 2) Base packages: Java (for Jenkins), Python venv (for train.py/tests), git, curl, Docker
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-21-jre python3-venv python3-pip git curl docker.io

# 3) Jenkins LTS (2026 signing key)
sudo mkdir -p /etc/apt/keyrings
sudo wget -q -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# 4) Let Jenkins run docker, then restart services
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker
sudo systemctl restart jenkins

echo "------------------------------------------------------------"
echo "Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "Open http://$(curl -s ifconfig.me):8080"
