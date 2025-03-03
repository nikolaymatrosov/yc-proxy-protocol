#!/usr/bin/env bash

set -e
exec > >(tee -i /var/log/install.log)
exec 2>&1

# Wait until /var/lib/apt/lists/lock is released
while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Waiting for other software managers to finish..."
    sleep 2
done

# Install Nginx, WireShark, and Go
sudo apt-get update
sudo apt-get install -y nginx tshark golang

# Install Go-httpbin
go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@latest

# Install Go-httpbin as a service
sudo cp ~/go/bin/go-httpbin /usr/local/bin/go-httpbin

# Create a service file for Go-httpbin
cat <<EOF | sudo tee /etc/systemd/system/go-httpbin.service
[Unit]
Description=Go-httpbin
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/go-httpbin -port 8000 -host 127.0.0.1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start the Go-httpbin service
sudo systemctl daemon-reload
sudo systemctl enable go-httpbin
sudo systemctl start go-httpbin

# Configure Nginx
cat <<'EOF' | sudo tee /etc/nginx/conf.d/01_httpbin.conf
server {
    listen 8080;
    server_name demo;

    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Restart Nginx
sudo systemctl restart nginx
