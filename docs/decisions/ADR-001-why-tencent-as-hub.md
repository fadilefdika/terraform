# ADR-001: Pemilihan Tencent Cloud sebagai Hub Utama (24/7)

**Status:** Accepted
**Date:** Juli 2026

## Konteks dan Masalah
Dalam membangun lab SRE multi-cloud, kita membutuhkan sebuah server Hub (Gateway) yang berfungsi untuk routing lalu lintas web (Nginx Proxy Manager), manajemen kontainer (Portainer), dan pemantauan terpusat (Prometheus & Grafana). Server ini harus aktif 24/7 agar metrik pemantauan tidak terputus dan gateway selalu siap merouting trafik.

Namun, menjalankan server secara 24/7 di provider cloud utama seperti DigitalOcean atau AWS mengonsumsi budget secara berkelanjutan. Hal ini berpotensi menghabiskan saldo kredit lebih cepat dari yang diharapkan, mengurangi kesempatan untuk berlatih *provisioning* server skala besar.

## Opsi yang Dipertimbangkan
1. **DigitalOcean Basic Droplet 24/7:** Menggunakan kredit DO yang sudah ada ($187).
2. **AWS EC2 Free Tier / Spot Instances:** Menggunakan AWS (namun risiko *over-billing* jika lewat batas *free tier*).
3. **Provider Lokal (Tencent Cloud):** Menyewa VPS berbiaya rendah dengan harga *flat* bulanan.

## Keputusan
Kita memilih **Opsi 3 (Tencent Cloud)** sebagai server Hub utama yang aktif 24/7.
- **Spesifikasi:** 2 vCPU, 2 GB RAM, 40 GB SSD.
- **Biaya:** Rp 60.000 / bulan (Flat).
- **IP Publik:** 43.133.131.141

## Alasan Keputusan
1. **Cost Isolation & Runway (FinOps):** Dengan memisahkan biaya Hub (flat Rp 60.000) dari biaya eksperimen Terraform (DigitalOcean), kredit DO sebesar $187 dapat dialokasikan 100% murni untuk eksperimen IaC (Infrastructure as Code) yang sifatnya bongkar-pasang. Ini memperpanjang *runway* belajar hingga bertahun-tahun.
2. **Simulasi Arsitektur Hybrid Enterprise:** Pendekatan ini secara akurat mensimulasikan arsitektur *hybrid* di dunia nyata. Banyak perusahaan meletakkan *Load Balancer / Gateway* di provider murah dengan *bandwidth* melimpah, sementara *Compute Layer* (Aplikasi utama) dikelola di provider cloud raksasa (DO/AWS) demi memanfaatkan keandalan API IaC (Terraform).
3. **Blast Radius Reduction:** Pemisahan *state*. Kerusakan sistem atau *destroy* masal pada *compute layer* di DO (lingkungan Sandbox) tidak akan pernah menyentuh atau merusak infrastruktur pemantauan (Grafana) dan gateway di Tencent.

## Konsekuensi
- **Positif:** Efisiensi kredit DO maksimal, arsitektur lebih tangguh, menonjolkan kemampuan *cost-optimization* di mata rekruter.
- **Negatif:** Menambah overhead operasional karena harus mengelola dua provider yang berbeda. Hub tidak dibuat via Terraform, melainkan dikonfigurasi melalui skrip Bash atau **Ansible**. Hal ini dimitigasi dengan menggunakan *Ansible Playbook* untuk mengotomatisasi setup Hub.
