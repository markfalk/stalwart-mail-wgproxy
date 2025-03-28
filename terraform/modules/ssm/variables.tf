variable "wireguard_client_public_key" {
  description = "Public key for the WireGuard peer"
  type        = string
}

variable "wireguard_server_private_key" {
  description = "Private key of the WireGuard server"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}
