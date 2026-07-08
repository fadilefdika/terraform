output "sandbox_ip" {
  description = "IP Publik Backend. (Masukkan IP ini ke Nginx Proxy Manager di Tencent)"
  value       = module.backend_sandbox.droplet_ip
}
