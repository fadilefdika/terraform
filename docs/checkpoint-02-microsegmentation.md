# 🛡️ Checkpoint 02: Arsitektur Zero Trust & Micro-segmentation

**Status:** Selesai
**Fokus Utama:** Peningkatan postur keamanan dari arsitektur *Flat Network* menjadi *Defense in Depth* berbasis *Micro-segmentation*.

---

## 🛑 Akar Masalah (Vulnerability Findings)
Pada Checkpoint 01, seluruh container (Nginx, Portainer, Grafana, Prometheus) digabung ke dalam satu jaringan bridge raksasa bernama `proxy-network`.
Melalui audit keamanan (*Offensive Security*), ditemukan kelemahan fatal:
1. **Lateral Movement:** Jika Nginx Proxy Manager (yang menghadap publik) diretas, *hacker* bisa langsung menjangkau Prometheus (`http://prometheus:9090`) dan menyedot data jaringan.
2. **Information Disclosure & Container Escape:** *Hacker* bisa mengakses metrik OS dari Node Exporter (`:9100`) untuk mencari versi presisi dari Kernel Linux, yang bisa digunakan untuk meluncurkan serangan eksploitasi *Docker Escape* (menjebol keluar ke VPS utama).
3. **Root Privilege:** Container Nginx berjalan sebagai `root` secara bawaan, memberikan kewenangan berbahaya jika terjadi eksploitasi kode (RCE).

---

## 🛠️ Solusi yang Diimplementasikan (Defense in Depth)

### 1. Network Micro-segmentation
Jaringan `proxy-network` dipecah menjadi 3 zona virtual yang diisolasi ketat oleh aturan internal *iptables* Docker:
*   **`proxy-net` (Zona Merah/DMZ):** Hanya diisi oleh Nginx Proxy Manager.
*   **`monitoring-net` (Zona Hijau):** Diisi oleh Prometheus, Grafana, dan Node Exporter.
*   **`management-net` (Zona Biru):** Diisi murni oleh Portainer.

*Hasil:* Nginx tidak lagi memiliki jalur komunikasi untuk mencapai Prometheus atau Portainer. Upaya koneksi akan otomatis digagalkan (*Connection Refused*).

### 2. Container OS Hardening
Meskipun Nginx harus berjalan sebagai *root* (batasan dari *image* `jc21/nginx-proxy-manager`), kapabilitas *root* tersebut telah ditekan di level Kernel Linux dengan menambahkan:
*   `--cap-drop=NET_RAW`: Melumpuhkan *tools* peretas yang bergantung pada *raw socket* (ping ICMP, tcpdump, SYN scan nmap). *TCP connect scan dan koneksi biasa (seperti curl) tetap berfungsi, sehingga pertahanan utama bertumpu pada isolasi network.*
*   `--security-opt="no-new-privileges:true"`: Memblokir segala macam upaya dari *user* di dalam container untuk melakukan eskalasi hak istimewa (naik pangkat).

### 3. Simulasi & Validasi (Testing)
Verifikasi keamanan berlapis telah dilakukan dengan skenario "Negative Test" (harus gagal) dan "Positive Test" (harus berhasil):

**A. Negative Testing (Skenario Serangan Hacker):**
```bash
# 1. Buktikan Resolusi DNS Gagal:
sudo docker exec -it nginx-proxy-manager curl -v http://prometheus:9090

# 2. Buktikan Isolasi Jaringan Aktual (Gunakan IP address dari docker inspect, bukan hostname):
sudo docker exec -it nginx-proxy-manager curl -v http://<IP_prometheus>:9090

# 3. Buktikan Raw Socket Diblokir (Operation not permitted):
sudo docker exec -it nginx-proxy-manager ping 1.1.1.1
```

**B. Positive Testing (Functional Regression Check):**
Untuk memastikan segmentasi jaringan tidak merusak fungsionalitas (Zero Downtime/Regression):
- Dipastikan Grafana (di `monitoring-net`) tetap berhasil melakukan *query* ke Prometheus (di `monitoring-net`).
- Dipastikan admin tetap dapat mengakses dashboard Grafana dan Portainer melalui jalur SSH Tunneling.

---

## 📚 Pembelajaran Arsitektur (Next Roadmap)
Dari evaluasi skenario aplikasi *"Backend & Database"*, diputuskan bahwa *best practice* di masa depan adalah menerapkan arsitektur 3-Tier:
- Database harus dikunci di dalam jaringan *Internal* (tanpa akses internet / `internal: true`) dengan *user* berhak akses minimal (bukan root).
- Container jembatan (seperti Backend API) diizinkan menempel di dua jaringan sekaligus (`proxy-net` dan `db-net`) dengan deklarasi `external: true` di Docker Compose.
- **Secrets Management** (seperti *password* database dan admin) akan tetap dijaga super ketat tanpa jejak teks polos menggunakan **Ansible Vault**.
- **Technical Debt & Roadmap Lanjutan:** Karena dependensi *image* NPM terhadap `s6-overlay`, implementasi `--cap-drop=ALL` (serta *allow by exception*) dan *read-only filesystem* (`read_only: true` dengan `tmpfs`) belum diterapkan untuk mencegah kerusakan aplikasi (*breakage*). Akan dieksplorasi di fase pengerasan tingkat lanjut atau diganti dengan image alternatif.
