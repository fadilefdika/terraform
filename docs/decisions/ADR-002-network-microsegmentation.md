# ADR-002: Network Micro-segmentation & Container Hardening

**Tanggal:** 22 Juli 2026
**Status:** Diterima (Accepted)
**Konteks:**
Saat ini seluruh stack infrastruktur (Nginx Proxy Manager, Prometheus, Grafana, Portainer) berada di dalam satu Docker bridge network yang sama (`proxy-network`). Selain itu, container Nginx Proxy Manager (NPM) berjalan menggunakan hak akses `root` secara default.
Dalam arsitektur *Flat Network* ini, jika aplikasi NPM yang menghadap publik (port 80/443) berhasil dieksploitasi oleh penyerang, penyerang tersebut berpotensi melakukan pergerakan lateral (*lateral movement*) ke layanan monitoring atau manajemen di dalam jaringan lokal Docker, serta memonopoli *resource* dengan *root privilege*.

**Keputusan:**
1. **Network Micro-segmentation:** Memecah `proxy-network` menjadi tiga jaringan terisolasi:
   - `proxy-net`: Hanya untuk Nginx Proxy Manager (DMZ).
   - `monitoring-net`: Untuk Grafana, Prometheus, dan Node Exporter.
   - `management-net`: Untuk Portainer.
2. **Container Hardening:** Menambahkan opsi keamanan spesifik pada container NPM (karena kita tidak bisa menghilangkan root access secara penuh akibat limitasi s6-overlay):
   - `--cap-drop=NET_RAW`: Melumpuhkan *tools* peretas yang bergantung pada *raw socket* (ping ICMP, tcpdump, SYN scan nmap). *Catatan: TCP connect scan biasa masih bisa berjalan, sehingga pertahanan utama tetap bertumpu pada isolasi network*.
   - `--security-opt="no-new-privileges:true"`: Mencegah eskalasi hak istimewa di dalam container.

**Konsekuensi & Trade-off:**
- **Positif:** Mengurangi *blast radius* (dampak kerusakan) secara drastis jika NPM dibobol. Penyerang akan terkurung di `proxy-net` dan kesulitan melakukan pengintaian diam-diam (*stealth scan/sniffing*) karena hilangnya kapabilitas `NET_RAW`.
- **Negatif:** Konfigurasi menjadi sedikit lebih kompleks. Jika di masa depan NPM perlu melakukan reverse proxy ke aplikasi *Backend*, aplikasi tersebut harus dengan sengaja di-*attach* ke dalam `proxy-net`.
- **Technical Debt:** Karena image NPM menggunakan `s6-overlay` yang membutuhkan banyak hak akses, kita menunda penerapan `--cap-drop=ALL` dan `--read-only` untuk menghindari kerusakan sistem (breakage). Ini dicatat sebagai *roadmap* perbaikan masa depan atau migrasi ke image alternatif.

**Rencana Rollback:**
Jika konfigurasi *Micro-segmentation* menyebabkan terputusnya layanan internal yang tidak terduga, *rollback* akan dilakukan dengan cara:
1. Melakukan *revert* pada *commit* Git terakhir yang memodifikasi `setup-hub.yml`.
2. **Hapus seluruh container secara manual** (`docker rm -f nginx-proxy-manager portainer prometheus grafana node-exporter`) terlebih dahulu. Ini **wajib** dilakukan karena skrip Ansible lama tidak memiliki opsi `purge_networks: true`, sehingga jika langsung dijalankan, container akan terhubung ke 2 jaringan sekaligus (lama dan baru) tanpa memutuskan koneksi jaringan yang salah sasaran.
3. Menjalankan ulang perintah `ansible-playbook -i inventory.ini setup-hub.yml` dari awal untuk mendapatkan *state* yang bersih (*clean slate*).
