# ADR-001: Tencent Cloud sebagai Hub Permanen

**Status:** Accepted  
**Tanggal:** 8 Juli 2026  
**Dibuat oleh:** Fadil Efdika

---

## Context

Dalam arsitektur lab ini dibutuhkan satu server yang:

- Selalu menyala 24/7 sebagai gateway dan monitoring center
- Biaya fix dan predictable (bukan bayar per jam)
- Punya bandwidth besar untuk trafik publik (HTTP/HTTPS)

Ada dua kandidat: **Tencent Cloud** dan **DigitalOcean**.

---

## Decision

**Tencent Cloud dipilih sebagai Hub permanen.**

DigitalOcean dipakai sebagai Sandbox — ephemeral, bongkar-pasang via Terraform.

---

## Alasan

| Faktor      | Tencent Cloud       | DigitalOcean           |
| ----------- | ------------------- | ---------------------- |
| Biaya       | Fix Rp 60.000/bulan | Per jam (~$0.009/jam)  |
| Cocok untuk | Always-ON 24/7      | Ephemeral workload     |
| Spek        | 2 vCPU / 2GB RAM    | Scalable via Terraform |
| Lokasi      | Singapore (SGP)     | Singapore (SGP)        |

Kalau Hub ditaruh di DO, setiap `terraform destroy` akan **membunuh monitoring dan gateway sekaligus** — ini melanggar prinsip blast radius isolation.

---

## Consequences

**Positif:**

- Biaya Hub fix dan tidak menguras kredit DO
- `terraform destroy` di DO tidak mempengaruhi Hub sama sekali
- Blast radius terisolasi — kerusakan di Sandbox tidak menjalar ke Hub

**Negatif:**

- Dua provider berbeda = dua cara login, dua dashboard
- Latency antar cloud ada overhead kecil (~1-5ms Singapore ke Singapore)
- Cross-cloud monitoring butuh konfigurasi tambahan (Prometheus scrape target dinamis)

---

## Alternatif yang Dipertimbangkan

**Semua di DigitalOcean:**  
Ditolak — Hub dan Sandbox di provider yang sama berarti `terraform destroy` bisa tidak sengaja menghapus Hub.

**Semua di Tencent:**  
Ditolak — Tencent tidak punya Terraform provider se-mature DigitalOcean untuk workflow bongkar-pasang Sandbox.

---

_Keputusan ini akan di-review di Fase 4 ketika Azure diintegrasikan._
