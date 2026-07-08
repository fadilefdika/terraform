output "droplet_ip" {
  description = "IP Publik dari Backend Droplet"
  value       = digitalocean_droplet.main.ipv4_address
}
