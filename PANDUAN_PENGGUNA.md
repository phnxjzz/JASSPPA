# Panduan Menggunakan Sistem Pendaftaran Produk Air (SPPA)

---

## Cara Mengakses Sistem

### Dari Komputer Server / LAN yang Sama
URL: `http://192.168.1.52:8081/sistemppa/`

### Dari Komputer Lokal (Host Server)
URL: `http://localhost:8081/sistemppa/`

---

## Keperluan Teknikal

### Browser Yang Disokong
- Google Chrome / Chromium 90+
- Mozilla Firefox 88+
- Microsoft Edge 90+
- Safari 14+

### Persyaratan Jaringan
1. **Komputer harus pada rangkaian yang sama (LAN)** dengan server (192.168.1.x)
2. **Port 8081 mesti terbuka** pada firewall server
   - Kontrol Panel → Windows Defender Firewall → Benarkan App Melalui Firewall
   - Atau jalankan PowerShell sebagai Admin:
   ```powershell
   New-NetFirewallRule -DisplayName "SPPA Tomcat 8081" -Direction Inbound -Protocol TCP -LocalPort 8081 -Action Allow -Profile Any
   ```

---

## Login Pengguna

### Akaun Admin (Default)
- **Username:** `admin`
- **Password:** `admin123`

### Akaun Pengguna Biasa
- **Username:** `user1`
- **Password:** `user123`

> **PENTING:** Tukar password default selepas login pertama kali — Profil → Kemaskini Maklumat Pengguna

### Pemilihan Portal Semasa Login
Halaman login menyediakan pilihan portal:
- **Portal Pengguna** — untuk mendaftar dan mengurus permohonan produk
- **Portal Admin** — untuk pentadbir sistem sahaja

### Keselamatan Login
- Sistem menguatkuasakan **had percubaan login** (rate limiting). Terlalu banyak cubaan gagal dalam masa singkat akan menyebabkan akses disekat sementara.
- Kata laluan disimpan menggunakan **BCrypt hashing** — sistem tidak menyimpan kata laluan dalam teks biasa.

---

## Pendaftaran Akaun Baharu

1. Klik **"Daftar"** pada halaman utama
2. Isi maklumat: nama penuh, username, emel, dan kata laluan
3. Pilih jenis akaun (Pengguna)
4. Klik **"Daftar Sekarang"**
5. **Semak e-mel** untuk pautan pengesahan akaun
6. Klik pautan dalam e-mel untuk mengaktifkan akaun
7. Log masuk dengan akaun yang telah aktif

> Akaun yang belum disahkan e-mel tidak boleh log masuk.

---

## Terlupa Kata Laluan

1. Klik **"Terlupa Kata Laluan"** pada halaman login
2. Masukkan nama penuh dan alamat e-mel yang didaftarkan
3. Sistem akan menghantar pautan set semula kata laluan ke e-mel
4. Klik pautan dalam e-mel dan tetapkan kata laluan baharu
5. Log masuk semula dengan kata laluan baharu

---

## Fitur Sistem

### Untuk Pengguna Biasa

| Fitur | Penerangan |
|-------|-----------|
| **Borang Permohonan** | Hantar permohonan pendaftaran produk air |
| **Semak Status** | Pantau status permohonan (Menunggu / Diluluskan / Ditolak) |
| **Perakuan Pendaftaran** | Jana dan cetak sijil/perakuan bagi permohonan yang diluluskan |
| **Muat Turun Dokumen** | Muat turun dokumen sokongan permohonan |
| **Senarai Produk** | Lihat dan cari produk air yang berdaftar |
| **Profil Pengguna** | Kemaskini maklumat profil dan gambar avatar |
| **Papan Pemuka** | Lihat pengumuman terkini dan ringkasan permohonan |
| **Responsive Design** | Berfungsi pada desktop dan peranti mudah alih |

### Untuk Admin

| Fitur | Penerangan |
|-------|-----------|
| **Dashboard Admin** | Statistik sistem, pengumuman, dan senarai permohonan terbaru |
| **Semak Permohonan** | Semak, lulus, atau tolak permohonan produk dengan nota |
| **Pengurusan Pengguna** | Lihat dan urus senarai pengguna berdaftar |
| **Export PDF** | Eksport senarai permohonan ke fail PDF |
| **Export Excel (.xlsx)** | Eksport senarai permohonan atau pengguna ke Excel |
| **Pengurusan Pengumuman** | Cipta, kemaskini, dan padam pengumuman (termasuk muat naik gambar) |
| **Gambar Pengumuman** | Muat naik gambar (maksimum 10MB) untuk setiap pengumuman |
| **Perakuan Pendaftaran** | Jana dan cetak perakuan bagi mana-mana permohonan |
| **Log Audit** | Tindakan pentadbir direkodkan secara automatik untuk tujuan audit |
| **Notifikasi E-mel** | Notifikasi automatik dihantar kepada pengguna apabila status permohonan berubah |

---

## Pengurusan Profil & Avatar

1. Log masuk dan klik nama pengguna / ikon profil di navbar
2. Pilih **"Kemaskini Profil"**
3. Boleh kemaskini: nama penuh, emel, nombor telefon
4. **Tukar Kata Laluan:** isi kata laluan lama dan kata laluan baharu
5. **Muat Naik Avatar:** klik pada kawasan gambar profil dan pilih fail imej
   - Format disokong: JPG, PNG, GIF
   - Saiz maksimum: 5MB
6. Klik **"Simpan"** untuk menyimpan perubahan

---

## Pengumuman (Admin)

1. Log masuk sebagai admin dan buka **Dashboard Admin**
2. Bahagian **Pengurusan Pengumuman** tersedia di bawah dashboard
3. **Tambah Pengumuman Baharu:**
   - Isi tajuk dan kandungan pengumuman
   - (Pilihan) Muat naik gambar pengumuman (JPG/PNG, maks 10MB)
   - Klik **"Simpan"**
4. **Padam Pengumuman:** klik ikon padam pada pengumuman berkaitan

---

## Permohonan Produk (Pengguna)

1. Log masuk dan pergi ke **"Borang Permohonan"**
2. Isi semua maklumat produk yang diperlukan
3. Lampirkan dokumen sokongan (jika ada)
4. Klik **"Hantar Permohonan"**
5. Permohonan akan diproses dalam transaksi selamat untuk memastikan data konsisten
6. Pantau status di **"Semak Permohonan Saya"**

---

## Perakuan Pendaftaran (Sijil)

- Perakuan boleh dijana setelah permohonan **diluluskan** oleh admin
- Pengguna: pergi ke permohonan yang diluluskan → klik **"Jana Perakuan"**
- Admin: boleh jana perakuan untuk mana-mana permohonan yang diluluskan
- Perakuan boleh **dicetak** terus dari browser

---

## Pemecahan Masalah

### "Tidak Boleh Akses URL"
1. Sahkan Tomcat sedang berjalan — buka PowerShell dan jalankan:
   ```powershell
   Invoke-WebRequest -Uri "http://localhost:8081/sistemppa/" -UseBasicParsing
   ```
   Jika gagal, mulakan semula Tomcat:
   ```powershell
   .\ops-scripts\startup-system.ps1
   ```
2. Sahkan rangkaian terhubung: `ipconfig` dan semak subnet 192.168.1.x
3. Sahkan port 8081 terbuka (firewall)

### "Login Ditolak"
- Pastikan username/password betul (huruf besar/kecil penting)
- Jika dapat mesej **"Terlalu banyak percubaan"**, tunggu beberapa minit sebelum cuba semula (rate limiting)
- Pastikan akaun telah disahkan melalui e-mel (semak inbox / folder spam)
- Lupa password: klik **"Terlupa Kata Laluan"** dan ikut arahan

### "Akaun Belum Aktif"
- Semak folder inbox dan **spam/junk** e-mel untuk pautan pengesahan
- Jika pautan sudah tamat tempoh, hubungi pentadbir untuk mengaktifkan semula akaun

### "Upload Gambar Gagal"
- Pastikan fail tidak melebihi saiz maksimum (avatar: 5MB, gambar pengumuman: 10MB)
- Gunakan format yang disokong: JPG, PNG, GIF
- Pastikan sambungan internet stabil semasa muat naik

### "Export PDF/Excel Gagal (Error 500)"
- Pastikan Tomcat telah dimulakan menggunakan `build-and-deploy.ps1` (bukan sekadar `startup.bat`) supaya semua JAR library tersedia
- Semak log Tomcat: `runtime\apache-tomcat-11.0.18\logs\catalina.out`

### "Akses Perlahan"
- Semak penggunaan rangkaian: `ipconfig /all`
- Tutup tab browser lain atau aplikasi berat
- Semak log Tomcat untuk kesilapan

---

## Status Sistem Semasa

| Komponen | Status |
|----------|--------|
| **Tomcat Server** | Berjalan (Port 8081) |
| **Database (MySQL)** | Aktif |
| **Aplikasi Web** | Boleh Diakses |
| **IP Server** | 192.168.1.52 |

---

## Skrip Operasi (Untuk Pentadbir)

| Skrip | Tujuan |
|-------|--------|
| `ops-scripts\startup-system.ps1` | Mulakan MySQL dan Tomcat, buka browser |
| `ops-scripts\shutdown-system.ps1` | Hentikan Tomcat (dan MySQL jika perlu) |
| `ops-scripts\build-and-deploy.ps1` | Build semula WAR dan deploy ke Tomcat |
| `ops-scripts\smoke-test.ps1` | Uji semua endpoint utama sistem |

> Semua skrip mesti dijalankan sebagai **Administrator** dalam PowerShell.

---

## Sokongan Teknikal

Jika ada masalah:
1. Periksa fail log: `runtime\apache-tomcat-11.0.18\logs\catalina.out`
2. Jalankan smoke test: `.\ops-scripts\smoke-test.ps1`
3. Restart Tomcat: `.\ops-scripts\startup-system.ps1`
4. Hubungi pentadbir sistem

