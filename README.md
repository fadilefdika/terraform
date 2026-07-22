# 🛡️ Tencent Hub — Automated Monitoring Stack

![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![Security](https://img.shields.io/badge/Security-Zero--Trust-success?style=for-the-badge)

## 📌 Project Overview

Repository ini berisi Ansible Playbook untuk provisioning otomatis **Tencent Cloud Hub** — server gateway 24/7 yang berfungsi sebagai pusat monitoring dan reverse proxy dalam arsitektur hybrid cloud (Tencent + DigitalOcean).

Seluruh stack dikonfigurasi menggunakan **Infrastructure as Code** dengan prinsip **idempotency** — playbook bisa dijalankan berkali-kali tanpa error atau perubahan yang tidak diinginkan.

---

## ✨ Key Technical Achievements

- **Full Idempotency**: Menggunakan modul resmi `community.docker.docker_container` — bukan `command: docker run`. Jalankan 1x atau 100x, hasilnya selalu sama.
- **Zero-Trust Security**: Semua dashboard admin (Portainer, Grafana, NPM) di-bind ke `127.0.0.1`. Tidak ada port admin yang terbuka ke internet publik.
- **Ansible Handlers**: Perubahan pada `prometheus.yml` otomatis men-trigger restart container — tanpa restart manual.
- **Internal DNS**: Semua container berkomunikasi via nama (`http://prometheus:9090`), bukan IP — resilient terhadap container recreation.
- **Secret Management**: Credentials tidak pernah hardcoded di playbook. Dikelola via Ansible Vault atau environment variable.

---

## 🏗️ Architecture (Network Micro-segmentation)

> **[TODO: Masukkan link atau embed gambar diagram dari Eraser.io di sini]**

**Network Topology Flow (Micro-segmentation):**
```text
Internet (Public)
      │
      ▼
[ Cloud Firewall ]
  Port 22, 80, 443 only
      │
      ▼
[ Tencent VPS — Ubuntu 22.04 ]
  2 vCPU / 2GB RAM / Always-ON
      │
      ▼
[ Docker Engine ] (Iptables Isolated)
      │
      ├── proxy-net (Zona Merah / DMZ)
      │     └── Nginx Proxy Manager  → :80, :443 (PUBLIC)
      │
      ├── monitoring-net (Zona Hijau)
      │     ├── Prometheus           → :9090 (localhost only)
      │     ├── Grafana              → :3000 (localhost only)
      │     └── Node Exporter        → :9100 (internal only)
      │
      └── management-net (Zona Biru)
            └── Portainer CE         → :9000 (localhost only)
```

Infrastruktur ini menerapkan **Micro-segmentation** untuk membatasi *lateral movement* jika terjadi peretasan:
- **`proxy-net` (Zona Merah):** Area publik (DMZ) yang hanya berisi Nginx Proxy Manager.
- **`monitoring-net` (Zona Hijau):** Terisolasi dari publik, berisi Prometheus, Grafana, dan Node Exporter.
- **`management-net` (Zona Biru):** Terisolasi murni, khusus untuk Portainer.

> Akses admin hanya via SSH Tunnel — lihat bagian [Accessing Dashboards](#-accessing-dashboards).

---

## 📂 Repository Structure

```
ansible/
├── setup-hub.yml             # Main playbook (entry point)
├── inventory.ini             # Target server definition
├── secrets.yml               # File rahasia terenkripsi (Ansible Vault)
docs/
├── checkpoint-01-hub-monitoring.md # Refleksi & pembelajaran Fase 1
├── decisions/
│   └── ADR-001-why-tencent-as-hub.md
.gitignore
README.md
```

---

## 🚀 How to Run

### Prerequisites

```bash
# Install Ansible di local machine
pip install ansible

# Install Docker collection
ansible-galaxy collection install community.docker
```

### 1. Setup Inventory

```ini
# inventory.ini
[hub]
tencent-hub ansible_host=<IP_TENCENT> ansible_user=root
```

### 2. Jalankan Playbook

```bash
# Dry-run dulu (tidak ada perubahan nyata)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini setup-hub.yml --check --vault-password-file .vault_pass.txt

# Apply
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini setup-hub.yml -k --vault-password-file .vault_pass.txt
```

### 3. Verifikasi

```bash
# Cek semua container berjalan
ansible -i inventory.ini hub -m command -a "docker ps"
```

---

## 🔒 Accessing Dashboards

Semua dashboard admin **tidak bisa diakses langsung dari browser** karena di-bind ke `127.0.0.1`. Akses menggunakan SSH tunnel:

**Portainer (Container Management) — Port 9000:**

```bash
ssh -L 9000:127.0.0.1:9000 root@<IP_TENCENT>
```

Buka: `http://localhost:9000`

**Grafana (Monitoring Dashboard) — Port 3000:**

```bash
ssh -L 3000:127.0.0.1:3000 root@<IP_TENCENT>
```

Buka: `http://localhost:3000`

**Nginx Proxy Manager Admin — Port 81:**

```bash
ssh -L 81:127.0.0.1:81 root@<IP_TENCENT>
```

Buka: `http://localhost:81`

> **Tip:** Bisa forward semua sekaligus dalam satu command:
>
> ```bash
> ssh -L 9000:127.0.0.1:9000 -L 3000:127.0.0.1:3000 -L 81:127.0.0.1:81 root@<IP_TENCENT>
> ```

---

## 🔐 Security & Reliability

- **Secrets Management (Ansible Vault):** Seluruh kredensial (password Grafana, Portainer, dll) tidak pernah di-commit dalam bentuk *plain-text*. File `ansible/secrets.yml` dienkripsi secara penuh menggunakan Ansible Vault (termasuk praktik *Identity-Based Verification*).
- **Container Hardening:** Nginx Proxy Manager dikonfigurasi dengan `--security-opt="no-new-privileges:true"` (mencegah eskalasi *privilege*) dan `--cap-drop=NET_RAW` (memblokir tools *network scanning* bawaan hacker seperti ping/nmap dari dalam container).
- **Rollback Plan (Disaster Recovery):** Infrastruktur dibangun sepenuhnya via Ansible (IaC) dan terikat dengan Git. Jika terjadi kegagalan sistem paska-deploy (downtime), *rollback* dapat dilakukan secara deterministik dengan me-revert commit terakhir di Git dan menjalankan ulang perintah `ansible-playbook setup-hub.yml`.

---

## 📊 Monitoring Stack

| Service                 | Role                   | Port    | Access          |
| ----------------------- | ---------------------- | ------- | --------------- |
| **Nginx Proxy Manager** | Reverse proxy + SSL    | 80, 443 | Public          |
| **Portainer CE**        | Docker management UI   | 9000    | SSH Tunnel only |
| **Prometheus**          | Metrics scraper (Pull) | 9090    | SSH Tunnel only |
| **Grafana**             | Metrics visualization  | 3000    | SSH Tunnel only |
| **Node Exporter**       | Host metrics agent     | 9100    | Internal only   |

---

## 🗺️ Roadmap

- [x] Fase 1 — Setup Hub: Docker, NPM, Portainer
- [x] Fase 1 — Monitoring: Prometheus + Grafana + Node Exporter
- [x] Fase 1 — Security: Zero-Trust, SSH Tunnel, Firewall, Ansible Vault
- [ ] Fase 3 — Cross-cloud monitoring: scrape Node Exporter dari DO Sandbox
- [ ] Fase 5 — Alerting: Prometheus AlertManager

---

## 📚 Documentation

| Dokumen                                             | Deskripsi                                |
| --------------------------------------------------- | ---------------------------------------- |
| [Checkpoint 01](docs/checkpoint-01-hub-monitoring.md)              | Refleksi & rangkuman pembelajaran Fase 1 |
| [ADR-001](docs/decisions/ADR-001-why-tencent-as-hub.md) | Keputusan: Kenapa Tencent sebagai Hub    |
| [ADR-002](docs/decisions/ADR-002-network-microsegmentation.md) | Keputusan: Network Micro-segmentation & Hardening |
| [AGENTS.md](AGENTS.md)                           | Standar & guidelines project             |

---

_Part of **DevOps/SRE Lab** — 8-week hands-on infrastructure learning sprint._
