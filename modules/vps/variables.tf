variable "ssh_key_name" {
  description = "Nama SSH key yang sudah diupload ke DO"
  type        = string
}

variable "droplet_name" {
  description = "Nama dari droplet VPS"
  type        = string
}

variable "region" {
  description = "Region server"
  type        = string
  default     = "sgp1"
}

variable "droplet_size" {
  description = "Ukuran droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}
