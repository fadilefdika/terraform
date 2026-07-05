output "droplet_ip" {
  description = "IP publik VPS"
  value       = module.vps.droplet_ip
}

output "portainer_access" {
  description = "Cara akses Portainer via SSH tunnel"
  value       = module.vps.portainer_access
}

output "npm_access" {
  description = "Cara akses dashboard admin Nginx Proxy Manager (NPM) via SSH tunnel"
  value       = module.vps.npm_access
}
