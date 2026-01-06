#!/bin/sh

# Add current node in  /etc/hosts
echo "127.0.1.1 $(hostname)" >> /etc/hosts
echo "192.168.56.32 $(hostname)" >> /etc/hosts
echo "192.168.56.31 hashikube1" >> /etc/hosts
echo "192.168.56.33 consul1" >> /etc/hosts

# Get current IP adress
export currentip=$(/sbin/ip -o -4 addr list enp0s8 | awk '{print $4}' | cut -d/ -f1)

# Add Hashicorp repository

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install vault & prereq

sudo apt update
sudo apt install vault net-tools apt-transport-https gnupg curl wget bat -y

# Set up UFW

sudo ufw allow OpenSSH
sudo ufw allow https

for i in 8200/tcp 8201/tcp 8250/tcp 443/tcp
do sudo ufw allow $i
done

#sudo ufw enable -y

# prepare vault configuration

mv /tmp/vault.crt /tmp/vault.key /tmp/vault-ca.crt /etc/vault.d/tls/

chown vault:vault /etc/vault.d/tls/*
chmod 600 /etc/vault.d/tls/vault.key

# add vault CA to trusted certs

sudo cp /tmp/vault-ca.crt /usr/local/share/ca-certificates/vault-ca.crt
sudo update-ca-certificates

sed -i 's/serverip/'$currentip'/g' /tmp/config.hcl
mv /tmp/config.hcl /etc/vault.d/config.hcl

# Create user without login for vault service
sudo adduser vault --shell=/bin/false --no-create-home --disabled-password --gecos GECOS

# granting access to vault user
chmod 700 -R /opt/vault
chown vault -R /opt/vault


sudo tee -a /etc/systemd/system/vault.service > /dev/null <<EOT
[Unit]
Description="Hashicorp Vault"
Documentation="https://developer.hashicorp.com/vault/docs"
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/config.hcl
[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/config.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOT
# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl start vault.service
sudo systemctl enable vault.service