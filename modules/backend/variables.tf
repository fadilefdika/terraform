variable "droplet_name" {
  description = "Nama droplet backend"
  type        = string
}

variable "region" {
  description = "Region droplet"
  type        = string
  default     = "sgp1"
}

variable "droplet_size" {
  description = "Ukuran droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "ssh_key_name" {
  description = "Nama SSH key di DigitalOcean"
  type        = string
}

variable "hub_ip" {
  description = "IP Publik dari server Hub (Tencent) yang diizinkan mengakses port aplikasi"
  type        = string
}

variable "app_port" {
  description = "Port aplikasi REST API berjalan (contoh: 8080)"
  type        = string
  default     = "8080"
}
