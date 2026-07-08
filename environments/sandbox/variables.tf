variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Nama SSH Key Anda yang terdaftar di DigitalOcean"
  type        = string
}
