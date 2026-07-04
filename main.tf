data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_name
}

resource "digitalocean_droplet" "main" {
  image      = "ubuntu-22-04-x64"
  name       = "fadil-learning-vps"
  region     = var.region
  size       = var.droplet_size
  ssh_keys   = [data.digitalocean_ssh_key.main.id]
  monitoring = true
  ipv6       = true

  user_data = file("${path.module}/scripts/init.sh")

  timeouts {
    delete = "5m"
  }
}

resource "digitalocean_firewall" "main" {
  name        = "fadil-server-firewall"
  droplet_ids = [digitalocean_droplet.main.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

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