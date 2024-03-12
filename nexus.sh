#!/bin/bash

nexusInstall() {
    # Update system
    sudo apt-get update

    # Install Java (OpenJDK 8)
    sudo apt-get install -y openjdk-8-jdk

    # Create a user for Nexus
    sudo useradd --system --no-create-home --shell /bin/false nexus

    # Download Nexus
    NEXUS_VERSION="3.42.0-01"
    wget "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz"

    # Extract Nexus
    sudo tar -zxvf "nexus-${NEXUS_VERSION}-unix.tar.gz" -C /opt
    sudo ln -s "/opt/nexus-${NEXUS_VERSION}" /opt/nexus

    # Set permissions
    sudo chown -R nexus:nexus /opt/nexus /opt/sonatype-work

    # Create Nexus service
    sudo tee /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd daemon
    sudo systemctl daemon-reload

    # Enable and start Nexus service
    sudo systemctl enable nexus
    sudo systemctl start nexus

    # Check Nexus status
    sudo systemctl status nexus
}

nginxInstall() {
    # Install Nginx
    sudo apt-get install -y nginx
}

nginxConfig() {
    # Check for proxies file
    if [[ "$1" == "-f" ]] && [[ -f "$2" ]]; then
        PROXIES_FILE="$2"
    else
        echo "Usage: nexus.sh nginxConfig -f ./proxies.txt"
        exit 1
    fi

    # Define Nginx configuration for Nexus with proxy repos
    cat <<EOT | sudo tee /etc/nginx/sites-available/nexus.conf
server {
    listen 80;
    server_name okdnexus.cellcom.corp;

    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

EOT

    # Read proxies from file and add to Nginx config
    while read -r line; do
        read -r name nexus_port host_port <<< "$line"
        echo "    location /v2/${name}/ {" | sudo tee -a /etc/nginx/sites-available/nexus.conf
        echo "        proxy_pass http://localhost:${nexus_port};" | sudo tee -a /etc/nginx/sites-available/nexus.conf
        echo "    }" | sudo tee -a /etc/nginx/sites-available/nexus.conf
    done < "$PROXIES_FILE"

    # Close the server block in Nginx config
    echo "}" | sudo tee -a /etc/nginx/sites-available/nexus.conf

    # Enable the Nginx site
    sudo ln -s /etc/nginx/sites-available/nexus.conf /etc/nginx/sites-enabled/

    # Test and reload Nginx
    sudo nginx -t && sudo systemctl reload nginx
}

# Call functions as needed, e.g., nexusInstall, nginxInstall, nginxConfig -f ./proxies.txt
