# 📱 Panduan Akses Sistem Pendaftaran Produk Air (SPPA)

## 🚀 Cara Mengakses Sistem

### **Dari Komputer Server / LAN yang Sama**
```
URL: http://192.168.1.52:8081/sistemppa/
```

### **Dari Komputer Lokal (Host Server)**
```
URL: http://localhost:8081/sistemppa/
```

---

## 🔐 Login Pengguna

### **Akaun Admin (Default)**
- **Username:** `admin`
- **Password:** `admin123`

### **Akaun Pengguna Biasa**
- **Username:** `user1`
- **Password:** `user123`

> ⚠️ **PENTING:** Tukar password default selepas login pertama kali (Profil → Update Maklumat Pengguna)

---

## 📋 Keperluan Teknikal

### **Browser Yang Disokong**
- ✅ Google Chrome / Chromium 90+
- ✅ Mozilla Firefox 88+
- ✅ Microsoft Edge 90+
- ✅ Safari 14+

### **Persyaratan Jaringan**
1. **Komputer harus pada rangkaian yang sama (LAN)** dengan server (192.168.1.x)
2. **Port 8081 mesti terbuka** pada firewall server
   - Kontrol Panel → Windows Defender Firewall → Benarkan App Melalui Firewall
   - Atau jalankan PowerShell sebagai Admin:
   ```powershell
   New-NetFirewallRule -DisplayName "SPPA Tomcat 8081" -Direction Inbound -Protocol TCP -LocalPort 8081 -Action Allow -Profile Any
   ```

---

## 🎯 Fitur Sistem

### **Untuk Pengguna Biasa:**
- 📝 Borang Pendaftaran Produk
- 👤 Lihat/Update Profil
- 📦 Senarai Produk Berdaftar
- 🔍 Cari & Filter Produk
- 📱 Responsive Design (Desktop/Mobile)

### **Untuk Admin:**
- 📊 Dashboard Pentadbir
- ✅ Ulasan & Kelulusan Aplikasi
- 👥 Senarai Pengguna Berdaftar
- 📈 Statistik Sistem
- 📥 Export PDF / Excel
- 🔧 Pengurusan Produk

---

## 🔧 Pemecahan Masalah

### **"Tidak Boleh Akses URL"**
1. ✓ Sahkan Tomcat sedang berjalan:
   ```powershell
   Get-Process | Where-Object { $_.ProcessName -like "*java*" }
   ```
   Jika tidak ada, jalankan: `runtime\apache-tomcat-11.0.18\bin\startup.bat`

2. ✓ Sahkan rangkaian terhubung — `ipconfig` dan cek sama ada dalam subnet 192.168.1.x

3. ✓ Sahkan port 8081 terbuka (firewall)

### **"Login Ditolak"**
- Pastikan username/password betul (huruf besar/kecil penting)
- Lupa password? Klik **"Terlupa Kata Laluan"** dan reset melalui emel


### **"Akses Perlahan"**
- Semak network bandwidth `ipconfig /all`
- Tutup browser tabs lain / aplikasi berat

---

## 🖥️ Status Sistem Semasa

| Komponen | Status |
|----------|--------|
| **Tomcat Server** | ✅ Berjalan (Port 8081) |
| **Database (MySQL)** | ✅ Aktif |
| **Aplikasi Web** | ✅ Siap diakses |
| **IP Server** | 192.168.1.52 |

---

## 📞 Sokongan Teknikal

Jika mengalami masalah:
1. Periksa fail log: `runtime\apache-tomcat-11.0.18\logs\catalina.out`
2. Hubungi pentadbir sistem
3. Restart Tomcat jika perlu:
   ```powershell
   # Tutup Tomcat
   runtime\apache-tomcat-11.0.18\bin\shutdown.bat
   # Tunggu 5 saat
   Start-Sleep -Seconds 5
   # Jalankan Tomcat
   runtime\apache-tomcat-11.0.18\bin\startup.bat
   ```

---

**Versi Sistem:** 1.0.0 | **Java:** 21 LTS | **Framework:** Jakarta EE / Servlet API 6.0
