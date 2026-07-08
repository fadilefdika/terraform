data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_name
}

resource "digitalocean_droplet" "main" {
  image      = "ubuntu-22-04-x64"
  name       = var.droplet_name
  region     = var.region
  size       = var.droplet_size
  ssh_keys   = [data.digitalocean_ssh_key.main.id]
  monitoring = true

  # Script sederhana untuk install Docker dasar di backend
  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail
              apt-get update
              apt-get install -y docker.io
              systemctl enable --now docker
              
              # Nanti Anda bisa deploy container REST API Anda di sini
              EOF

  timeouts {
    delete = "5m"
  }
}

resource "digitalocean_firewall" "backend" {
  name        = "${var.droplet_name}-firewall"
  droplet_ids = [digitalocean_droplet.main.id]

  # Port 22 (SSH) terbuka untuk publik agar Anda bisa login dari laptop
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # RESTRICTED: Port Aplikasi HANYA bisa diakses dari IP Tencent Hub
  inbound_rule {
    protocol         = "tcp"
    port_range       = var.app_port
    source_addresses = [var.hub_ip]
  }

  # Outbound bebas agar server bisa download package/docker image
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
