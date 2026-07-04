output "droplet_ip" {
  description = "IP publik VPS"
  value       = digitalocean_droplet.main.ipv4_address
}

output "portainer_access" {
  description = "Cara akses Portainer via SSH tunnel"
  value       = "ssh -L 9000:127.0.0.1:9000 root@${digitalocean_droplet.main.ipv4_address}"
}
