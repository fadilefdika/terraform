# 🚀 Scalable Cloud Infrastructure with Terraform & DigitalOcean

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![DigitalOcean](https://img.shields.io/badge/DigitalOcean-%230180FF.svg?style=for-the-badge&logo=digitalOcean&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![Security](https://img.shields.io/badge/Security-Strict-success?style=for-the-badge)

## 📌 Project Overview
This repository showcases an enterprise-grade **Infrastructure as Code (IaC)** deployment using **Terraform** on **DigitalOcean**. It is designed with modularity, scalability, and strict security practices at its core. 

Instead of a traditional monolithic script, this project implements a highly scalable **Modular Architecture** separating environments (e.g., `dev`, `prod`) from reusable infrastructure blueprints (modules).

## ✨ Key Technical Achievements

- **Modular Architecture**: Built a reusable `vps` module, enabling instantaneous provisioning of identical environments (`dev`, `staging`, `prod`) while adhering to the DRY (Don't Repeat Yourself) principle.
- **Automated Provisioning (Cloud-Init)**: Utilized Bash scripting injected via `user_data` to automatically install Docker, Portainer, and Nginx Proxy Manager on boot without human intervention.
- **Resilient Container Networking**: Implemented a custom Docker bridge network (`proxy-network`) enabling automatic Internal DNS resolution, ensuring seamless reverse proxying regardless of dynamic IP assignments.
- **Zero-Trust Security & Hardening**:
  - Direct public access to administrative dashboards (Portainer & NPM Admin) is **blocked**.
  - Internal admin services are bound strictly to `127.0.0.1`.
  - Secure access is facilitated exclusively via **SSH Tunneling**.
  - Strict Firewall configurations allowing only port `22`, `80`, and `443` inbound.
- **Secret Management**: API tokens and SSH keys are explicitly excluded from version control via `.gitignore` and handled dynamically through `.tfvars` to prevent credentials leakage.

---

## 🏗️ Architecture Visualization

[![Project Architecture](https://app.eraser.io/workspace/wkt4PvQbUT8Yd0HsOsSm/preview?elements=8Yh63-Fw-8WcK-a2x3U8qQ&type=embed)](https://app.eraser.io/workspace/wkt4PvQbUT8Yd0HsOsSm?origin=share)

> **Note:** Click the image above to view the interactive diagram and source code on Eraser.io.

---

## 📂 Scalable Directory Structure

```text
.
├── environments/
│   └── dev/                  # Development Environment
│       ├── main.tf           # Calls the 'vps' module
│       ├── variables.tf      # Env-specific variables
│       ├── outputs.tf        
│       ├── providers.tf      # DigitalOcean Provider Config
│       └── terraform.tfvars  # [IGNORED] Secrets & Keys
├── modules/
│   └── vps/                  # Reusable Blueprint Module
│       ├── main.tf           # Droplet & Firewall Resources
│       ├── variables.tf
│       ├── outputs.tf
│       └── scripts/
│           └── init.sh       # Bootstrap script (Docker, Portainer, NPM)
├── AGENTS.md                 # DevOps & Security Guidelines
└── README.md                 # Project Documentation
```

## 🚀 How to Run (Development)

1. Navigate to the desired environment:
   ```bash
   cd environments/dev
   ```
2. Initialize Terraform (downloads providers & modules):
   ```bash
   terraform init
   ```
3. Preview the infrastructure plan:
   ```bash
   terraform plan -out=rencana.tfplan
   ```
4. Deploy to DigitalOcean:
   ```bash
   terraform apply "rencana.tfplan"
   ```

## 🔒 Accessing Admin Dashboards (Post-Deploy)

To access the administrative tools safely without exposing them to the internet, establish an SSH tunnel using the dynamically generated IPs outputted by Terraform.

**Portainer (Container Management):**
```bash
ssh -L 9000:127.0.0.1:9000 root@<DROPLET_IP>
```
*Access via browser at `http://localhost:9000`*

**Nginx Proxy Manager (Reverse Proxy Admin):**
```bash
ssh -L 81:127.0.0.1:81 root@<DROPLET_IP>
```
*Access via browser at `http://localhost:81`*
