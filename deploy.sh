#!/bin/bash

check=$( getent hosts | grep -e broker )

if [ "$check" == "" ]; then
  echo "10.4.90.52 broker" | sudo tee -a /etc/hosts
  echo "10.4.90.62 broker" | sudo tee -a /etc/hosts
fi

# Update repos
sudo apt update

# Do full upgrade of system
sudo apt full-upgrade -y

# Remove leftover packages and purge configs
sudo apt autoremove -y --purge

# Install required packages
sudo apt install -y ufw nginx wget unzip php-bcmath php-amqp php-curl php-cli php-zip php-mbstring inotify-tools

# Setup firewall
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Install zerotier
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -s https://install.zerotier.com | sudo bash

# Stop nginx
sudo systemctl stop nginx

# Setup Self Signed Cert
sudo openssl req -subj '/CN=stonX/OU=IT 490/O=NJIT/C=US' -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
sudo openssl dhparam -out /etc/ssl/dhparam.pem 2048

# Copy config over
sudo cp -r nginx.conf /etc/nginx/nginx.conf
sudo chown -R root:root /etc/nginx
sudo find /etc/nginx -type d -exec chmod 755 {} \;
sudo find /etc/nginx -type f -exec chmod 644 {} \;
sudo nginx -t

# Start nginx
sudo systemctl start nginx

# Setup Central Logging
git clone git@github.com:stonX-IT490/logging.git ~/logging
cd /home/webserver/logging
chmod +x deploy.sh
./deploy.sh
cd /home/webserver/

# Reload systemd
sudo systemctl daemon-reload
