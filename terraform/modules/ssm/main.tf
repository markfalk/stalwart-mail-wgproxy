resource "aws_ssm_parameter" "wg_config" {
  name        = "WireGuardConfig"
  type        = "String"
  value       = <<EOF
[Interface]
Address = 192.168.128.1/24
PrivateKey = ${var.wireguard_server_private_key}
ListenPort = 51820
PostUp = /etc/wireguard/postup.sh %i
PostDown = /etc/wireguard/postdown.sh %i

[Peer]
PublicKey = ${var.wireguard_client_public_key}
AllowedIPs = 192.168.128.0/24
PersistentKeepalive = 25
EOF
}
