#!/bin/bash
# Amazon Linux 2023 configuration

# Ensure the system is up to date
yum update -y

# Install and start docker
yum install -y docker
systemctl enable --now docker

# Enable IPv6 access
export AWS_USE_DUALSTACK_ENDPOINT=true

# Get the instance ID from metadata
# Step 1: Get the IMDSv2 session token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Step 2: Use the token to retrieve the instance ID
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# Search for an Elastic IP with the tag "Name: wireguard-proxy"
EIP_ALLOCATION_ID=$(aws ec2 describe-addresses \
--filters "Name=tag:Name,Values=wireguard-proxy" \
--query "Addresses[].AllocationId" \
--output text)

# Associate the EIP with the instance
# Check if an EIP was found
if [[ -n "$EIP_ALLOCATION_ID" ]]; then
    echo "Found EIP with allocation ID: $EIP_ALLOCATION_ID"

    MAX_ATTEMPTS=12
    ATTEMPT=0

    # Associate the EIP with the instance
    until aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $EIP_ALLOCATION_ID; do
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            echo "Failed to associate EIP after $MAX_ATTEMPTS attempts"
            break
        fi
        echo "Failed to associate EIP, retrying in 10 seconds..."
        sleep 10
        ((ATTEMPT++))
    done
else
    echo "No unassociated EIP with tag 'Name: wireguard-proxy' found."
fi

# Retrieve WireGuard private key
mkdir -p /etc/wireguard

# Retrieve WireGuard config
AWS_USE_DUALSTACK_ENDPOINT=false aws ssm get-parameter --name "WireGuardConfig" --query "Parameter.Value" --output text > /etc/wireguard/wg0.conf

cat <<'EOF' > /etc/wireguard/postup.sh
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; iptables -A FORWARD -i $1 -j ACCEPT; iptables -A FORWARD -o $1 -j ACCEPT
for i in 25 443 465 587 993 53 4190; do iptables -t nat -A PREROUTING -i eth0 -p tcp --dport $i -j DNAT --to-destination 192.168.128.42:$i; done
for i in 53; do iptables -t nat -A PREROUTING -i eth0 -p udp --dport $i -j DNAT --to-destination 192.168.128.42:$i; done
EOF

cat <<'EOF' > /etc/wireguard/postdown.sh
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; iptables -D FORWARD -i $1 -j ACCEPT; iptables -D FORWARD -o $1 -j ACCEPT
for i in 25 443 465 587 993 53 4190; do iptables -t nat -D PREROUTING -i eth0 -p tcp --dport $i -j DNAT --to-destination 192.168.128.42:$i; done
for i in 53; do iptables -t nat -D PREROUTING -i eth0 -p udp --dport $i -j DNAT --to-destination 192.168.128.42:$i; done
EOF

chmod +x /etc/wireguard/postup.sh
chmod +x /etc/wireguard/postdown.sh

# Start WireGuard Docker container
docker run -d --name wireguard --privileged \
    -v /etc/wireguard:/etc/wireguard \
    -p 51820:51820/udp \
    -p 25:25 \
    -p 443:443 \
    -p 465:465 \
    -p 587:587 \
    -p 993:993 \
    -p 53:53 \
    -p 53:53/udp \
    -p 4190:4190 \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --restart unless-stopped \
    linuxserver/wireguard
