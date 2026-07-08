module "backend_sandbox" {
  source = "../../modules/backend"

  ssh_key_name = var.ssh_key_name
  droplet_name = "fadil-sandbox-api"
  region       = "sgp1"
  droplet_size = "s-1vcpu-1gb" # Size paling hemat untuk latihan
  
  # IP Tencent Server Anda (Hanya IP ini yang boleh akses port aplikasi)
  hub_ip       = "43.133.131.141"
  
  # Port aplikasi REST API Anda. Silakan ubah jika berbeda (misal 3000)
  app_port     = "8080"
}
