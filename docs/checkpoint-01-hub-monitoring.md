# Checkpoint 01: SRE Hub & Monitoring Automation

**Tanggal:** 8 Juli 2026  
**Fase:** Penyelesaian Fase 1 (Ansible & Tencent Hub)  
**Status:** ✅ Complete

---

## Apa yang Dibangun

Server Tencent Cloud berhasil dikonfigurasi penuh sebagai Hub permanen menggunakan Ansible Playbook.

| Komponen             | Tools                         | Status |
| -------------------- | ----------------------------- | ------ |
| Container Runtime    | Docker + Compose Plugin       | ✅     |
| Reverse Proxy        | Nginx Proxy Manager           | ✅     |
| Container Management | Portainer CE                  | ✅     |
| Metrics Collection   | Prometheus                    | ✅     |
| Host Metrics Agent   | Node Exporter                 | ✅     |
| Visualization        | Grafana (Dashboard ID: 1860)  | ✅     |
| Automation           | Ansible Playbook (Idempotent) | ✅     |

---

## Bukti Visual

### Grafana Dashboard — Four Golden Signals

![Grafana Dashboard](screenshots/checkpoint-01/grafana-dashboard.png)

### Prometheus Targets — Semua Status UP

![Prometheus Targets](screenshots/checkpoint-01/prometheus-targets.png)

### Portainer — Running Containers

![Portainer](screenshots/checkpoint-01/portainer-containers.png)

---

## Keputusan Teknis yang Dibuat

### 1. Modul `community.docker.docker_container` vs `command: docker run`

Awalnya menggunakan `command: docker run` di playbook — ini **anti-pattern** karena:

- Error kalau container sudah ada ("name already in use")
- Tidak idempotent — tidak bisa dijalankan ulang dengan aman

Solusi: beralih ke `community.docker.docker_container`. Ansible sekarang "mewawancarai" Docker Engine via API — kalau config sama, skip. Kalau berbeda, update otomatis.

### 2. Semua Port Admin di-bind ke `127.0.0.1`

Port Portainer (:9000), Grafana (:3000), dan NPM Admin (:81) tidak diekspos ke publik. Akses hanya via SSH tunnel. Ini mencegah brute-force attack dari bot otomatis.

### 3. Internal DNS sebagai Backbone Komunikasi Container

Grafana mengakses Prometheus via `http://prometheus:9090` — bukan via IP. Ketika container di-recreate, tidak perlu update konfigurasi apapun karena Docker internal DNS otomatis resolve nama container ke IP baru.

---

## Konsep yang Dipahami

**Idempotency**  
Jalankan playbook 1x atau 100x — hasilnya sama. Tidak ada error di run ke-2. Ini bukan fitur eksklusif Ansible, tapi mindset yang harus ada di semua script provisioning.

**Ansible Handlers**  
Kecerdasan sebab-akibat: kalau `prometheus.yml` berubah, handler otomatis restart container Prometheus di akhir play. Kalau tidak berubah, restart tidak dieksekusi. Efisien dan predictable.

**Docker Immutability**  
Container yang sudah menyala tidak bisa diubah konfigurasinya dari dalam. Kalau konfigurasi volume berubah, harus destroy container lama dan buat baru. Ini bukan bug — ini desain yang intentional.

**Prometheus Pull Mechanism**  
Prometheus tidak menunggu data dikirim (push). Ia aktif "menyedot" metrics dari endpoint `/metrics` milik Node Exporter sesuai interval yang dikonfigurasi di `prometheus.yml`.

**Zero-Trust Networking**  
Tidak ada service admin yang boleh dipercaya untuk diekspos ke internet, sekalipun sudah ada password. Attack surface yang tidak ada tidak bisa diserang.

---

## Yang Masih Perlu Diperbaiki

- [x] **Ansible Vault** — secrets di playbook sudah dienkripsi menggunakan Vault
- [ ] **Semantic versioning** — belum ada `git tag` untuk milestone ini
- [ ] **Alerting** — Prometheus sudah collect metrics tapi belum ada alert kalau server down

---

## Lesson Learned

Yang paling unexpected dari Fase 1 ini:

> Ansible bukan tentang "otomasi command". Ansible tentang **mendeklarasikan state yang diinginkan** — lalu membiarkan Ansible yang cari tahu cara mencapainya, apapun kondisi server saat ini.

Perbedaan mindset ini yang membedakan script provisioning biasa dari Infrastructure as Code yang sesungguhnya.

---

_Next: Fase 2 — Terraform DO Sandbox & integrasi cross-cloud monitoring._
