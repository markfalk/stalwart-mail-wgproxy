# Stalwart Mail WireGuard Proxy

This project sets up a secure email server infrastructure using [Stalwart Mail Server](https://stalw.art/mail-server/) and [BIND](https://www.isc.org/bind/) on a self-hosted server, with traffic routed through an AWS EC2 instance using [WireGuard](https://www.wireguard.com/). The EC2 instance acts as a proxy, routing all email-related traffic and DNS resolution requests to the self-hosted server over a WireGuard tunnel.

The intent is to allow users to self-host a modest mail server suitable for small to moderate use at a low cost.  The cost of the AWS infrastructure is less than $7 a month after exhausting the free tier.  This is primarily the cost of the public IP (EIP) and the cost of the EC2 instance (t4g.nano).

## Architecture Overview

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/markfalk/stalwart-mail-wgproxy/blob/main/self-hosted-mail-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/markfalk/stalwart-mail-wgproxy/blob/main/self-hosted-mail-light.svg">
  <img alt="Architecture Diagram" src="https://github.com/markfalk/stalwart-mail-wgproxy/blob/main/self-hosted-mail-light.svg">
</picture>

- **Self-Hosted Server**:
  - Runs the Stalwart Mail Server and BIND DNS server in Docker containers.
  - Connects to the AWS EC2 instance via a WireGuard client in a Docker container.
  - Handles all email processing and DNS resolution.

- **AWS EC2 Instance**:
  - Runs a WireGuard server in a Docker container.
  - Routes all inbound Internet traffic on required ports to the self-hosted server over the WireGuard tunnel.
  - Exposes a public Elastic IP for external communication.

- **Clients and MTAs**:
  - Communicate with the EC2 instance using its public Elastic IP.
  - Have no direct knowledge of the self-hosted server, enhancing security and providing a layer of abstraction.

## Features

- **Secure Traffic Routing**: All traffic is encrypted and routed through a WireGuard tunnel.
- **Public Elastic IP**: The EC2 instance is assigned a stable public IP for email communication and DNS resolution. The EIP also enables reverse DNS resolution required for compliant mail hosting.
- **Self-Hosted Control**: The self-hosted server retains full control of email and DNS services.

## Known Limitations

To keep costs down and the project simple, the following limitations are in place:

- **Single EC2 Instance**: The project currently supports only a single EC2 instance.
- **No Load Balancing**: The project does not support load balancing for increased availability.

## Prerequisites

1. **AWS Account**:
   - Project requires an AWS account to provision resources.

2. **Self-Hosted Server**:
   - A server capable of running Docker and WireGuard.
   - Sufficient resources to run the Stalwart Mail Server and BIND.

3. **Terraform**:
   - Installed locally to provision AWS resources.

4. **AWS CLI**:
   - Installed locally to interact with AWS resources.

## Project Structure

```txt
stalwart-mail-wgproxy/
├── bind/
│   ├── named.conf.template         # BIND DNS server configuration template
│   └── db.yourdomain.tld.template  # DNS zone file template
├── terraform/
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Variable definitions
│   └── terraform.tfvars            # Variable values (do not commit)
├── wg-conf/
│   ├── wg0.conf                    # WireGuard server configuration
│   └── client.conf                 # WireGuard client configuration
├── docker-compose-local.yml        # Local development compose file
└── docker-compose-unraid.yml       # UnRAID deployment compose file
```

## Setup Instructions

Extensive instructions are provided on GitHub pages and includes instructions for using Unraid to host the docker containers.
