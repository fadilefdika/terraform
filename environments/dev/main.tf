module "vps" {
  source = "../../modules/vps"

  ssh_key_name = var.ssh_key_name
  droplet_name = "fadil-learning-vps-dev"
  region       = var.region
  droplet_size = var.droplet_size
}
