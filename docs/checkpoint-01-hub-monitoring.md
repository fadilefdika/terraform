# Checkpoint 01: SRE Hub & Monitoring Automation

**Tanggal:** 8 Juli 2026
**Fase:** Penyelesaian Fase 1 (Ansible & Tencent Hub)

File ini adalah catatan refleksi dan rangkuman materi SRE yang telah berhasil dipraktikkan. Gunakan catatan ini sebagai bahan *review* (*study guide*) sebelum melanjutkan ke materi yang lebih kompleks.

## 1. Arsitektur Hybrid Cloud (Tencent + DigitalOcean)
- **Tencent (Hub):** Berfungsi sebagai "Gerbang Utama" (Gateway) 24/7. Mengelola *routing* (Nginx) dan pemantauan (Prometheus/Grafana). Server ini menampung aplikasi administratif.
- **DigitalOcean (Sandbox):** Berfungsi sebagai "Pabrik Aplikasi". Server ini bersifat *ephemeral* (bisa dihancurkan dan dibuat kapan saja menggunakan Terraform) demi menghemat biaya (FinOps).

## 2. Pemahaman Konsep Ansible
Ansible adalah alat *Configuration Management* (Infrastructure as Code).
- **Idempotency:** Fitur ajaib Ansible. Jika kita menyuruh Ansible menginstal Docker tapi Docker sudah ada, Ansible tidak akan *error* atau menginstal ulang, ia hanya membalas `ok` (Skip).
- **Modul `command` vs Modul Spesifik:** 
  - Menggunakan `command: docker run` sangat rawan *error* jika kontainer sudah ada (sehingga kita akali dengan `ignore_errors: yes`). Ini disebut *Anti-Pattern*.
  - Praktik *SRE Sejati* menyarankan penggunaan modul resmi seperti `community.docker.docker_container` agar Ansible bisa mendeteksi perubahan volume dan menghancurkan kontainer lama secara cerdas (tanpa *error* merah).
- **Modul `file` & `copy`:** Membuktikan bahwa Ansible bisa membuat folder (`/opt/monitoring`) dan menyuntikkan file teks langsung ke dalam server tanpa campur tangan manusia (tanpa editor `nano`).

## 3. Pemahaman Konsep Docker
- **Immutable:** Kontainer yang sudah menyala tidak bisa diubah "jeroannya". Jika kita mengubah lokasi file *volume*, kita wajib menghancurkan kontainer lama (`docker rm -f`) dan membuat kontainer baru agar ia bisa menyedot data dari jalur yang baru.
- **Volume Mounting:** Konsep "menyuntikkan" atau "memfotokopi" file dari server fisik (misal `/opt/monitoring/prometheus.yml`) ke dalam perut kontainer Docker (`/etc/prometheus/...`).
- **Internal DNS (Network):** Karena semua kontainer berada di satu jaringan `proxy-network`, Grafana bisa memanggil Prometheus cukup dengan memanggil namanya (`http://prometheus:9090`), tanpa perlu tahu IP-nya.

## 4. Pemahaman Konsep Grafana & Prometheus
- **Prometheus (Backend):** Bertindak sebagai "Pengepul Data" atau *Scraper*. Ia butuh file teks `prometheus.yml` untuk mengetahui ke mana ia harus mengambil data metrik (contoh: menyedot metrik dari Node Exporter).
- **Node Exporter:** Sebuah "Agen" atau detektif kecil yang dipasang di setiap server (Tencent & DO) untuk mencatat seberapa lelah CPU dan seberapa penuh RAM server tersebut.
- **Grafana (Frontend):** Bertindak sebagai "Layar TV". Grafana itu bodoh jika tidak disambungkan ke *Data Source* (Prometheus). Semua pengaturannya (seperti *import dashboard* ID 1860) bisa dilakukan sepenuhnya lewat *User Interface* (UI) berbasis klik, sehingga tidak butuh file konfigurasi `.yml` di server.

## 5. Konsep Zero-Trust Security & Tunneling
- **Jangan Percaya Internet:** Halaman administratif (Portainer, Nginx Admin, Grafana) TIDAK BOLEH diekspos ke publik dengan domain (`portainer.domain.com`) untuk menghindari serangan *brute-force* dari *bot hacker*.
- **Localhost Binding:** Semua port admin dikunci ke `127.0.0.1` di dalam konfigurasi Docker.
- **SSH Tunneling:** Satu-satunya cara untuk membukanya adalah dengan membuat "Terowongan Gaib" menggunakan fitur Port Forwarding di Termius. Cara ini menjadikan keamanan setingkat Enterprise (100% kebal serangan publik).

## 6. Tritunggal Ansible (Variables, Modules, Handlers)
- **Variables (`vars:`):** Memisahkan konfigurasi (seperti nomor *port*) ke bagian paling atas *playbook* agar mudah diganti. Pemanggilannya menggunakan *Jinja2 Templating* (`{{ nama_variabel }}`).
- **Modul Resmi (`docker_container`):** Cara elegan yang bersifat Deklaratif (Stateful). Ansible tidak lagi mengetik perintah `docker run` secara buta, melainkan mewawancarai *Docker Engine* lewat API. Jika kontainer sudah ada dan konfigurasinya sama, ia akan diam (`ok`). Jika beda, ia akan menghancurkan yang lama dan membuat yang baru (`changed`). Tidak akan pernah ada pesan *Error Conflict*!
- **Handlers:** Kecerdasan kausalitas (*Sebab-Akibat*). Jika file konfigurasi (seperti `prometheus.yml`) berubah, Ansible akan memanggil *Handler* untuk me-*restart* kontainer secara otomatis di akhir proses. Jika file tidak berubah, *restart* tidak akan dieksekusi.

## 7. Wawancara Teknis: Prometheus & Zero-Trust
- **HTTP Pull Mechanism:** Prometheus mengambil data dengan cara "menyedot" (*Scrape/Pull*) secara proaktif ke *endpoint* HTTP `/metrics` milik targetnya (seperti Node Exporter) sesuai jadwal `scrape_interval`.
- **Keamanan Jaringan Internal:** *Endpoint* metrik ini sangat rahasia. Mengapa *browser* publik ditolak (*Connection Refused*) saat mengakses `http://IP:9100/metrics`? Karena kita **tidak mengekspos** (*publish*) port 9100 tersebut ke *host*. Node Exporter dan Prometheus berada di satu ruang isolasi (*Docker Bridge Network*), sehingga hanya Prometheus yang bisa mengakses metrik tersebut dari dalam melalui *Internal DNS*.

---
*Misi Selanjutnya (Fase 3): Melahirkan Sandbox DO dan menggabungkannya ke ekosistem pemantauan ini.*
