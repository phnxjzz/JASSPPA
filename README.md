# Sistem Permohonan Pendaftaran Produk Air Jabatan Air Sabah_

### Penerangan Sistem
SPPPA ialah platform web untuk urus pendaftaran dan pengesahan produk air di Sabah. Sistem ini membolehkan pentadbir semak permohonan dan pengguna awam hantar permohonan pendaftaran produk.

## Developer Onboarding (Quick Link)

- Rujuk panduan setup lengkap: [DEVELOPER_SETUP_GUIDE.md](DEVELOPER_SETUP_GUIDE.md)
- Repo ini boleh dikongsi sebagai pakej penuh termasuk skrip operasi, runtime Tomcat, dan tools yang dibundel untuk setup developer pada Windows.

---

##  Struktur

```text
ProjectLI/
+-- pom.xml # Maven configuration
+-- src/
|   +-- main/
|   |   +-- java/
|   |   |   +-- com/sistemppa/
|   |   |       +-- config/
|   |   |       |   +-- DatabaseConfig.java
|   |   |       +-- servlet/
|   |   |       |   +-- LoginServlet.java
|   |   |       |   +-- LogoutServlet.java
|   |   |       |   +-- DashboardServlet.java
|   |   |       +-- util/
|   |   +-- webapp/
|   |       +-- WEB-INF/
|   |       |   +-- web.xml
|   |       +-- assets/
|   |       +-- login.jsp
|   |       +-- admin-dashboard.jsp
|   |       +-- user-dashboard.jsp
|   |       +-- index.jsp
+-- database/
|   +-- schema.sql # Database schema
+-- data/
|   +-- water_products.json
|   +-- water_products.csv
+-- SistemPPA.py # Python scraper for data import
```

---

##  Ciri-ciri Sistem

### Pentadbir
- Melihat dan menyemak permohonan
- Meluluskan atau menolak permohonan
- Menggantung akaun pengguna
- Mewujudkan akaun pentadbir baharu
- Melihat statistik sistem
- Audit log aktiviti

### Pemohon / Pengguna
- Membuat permohonan pendaftaran baharu
- Melihat profil dan status permohonan
- Mengemas kini maklumat akaun
- Tukar kata laluan
- Akses senarai produk berdaftar

---

##  Pangkalan Data

### Jadual Utama

#### `users`
Menyimpan maklumat pengguna dan pentadbir.

```sql
- id (Primary Key)
- username (UNIQUE)
- email (UNIQUE)
- password_hash
- role (ADMIN / USER)
- full_name
- avatar_url
- status (ACTIVE / SUSPENDED / INACTIVE)
```

#### `applications`
Menyimpan tebusan permohonan pendaftaran produk.

```sql
- id (Primary Key)
- user_id (Foreign Key)
- product_name
- product_category
- company_name
- status (DRAFT / PENDING / APPROVED / REJECTED / SUSPENDED)
- reviewed_by (Foreign Key)
- admin_notes
```

#### `products`
Menyimpan senarai produk air berdaftar (dari data Sabah Water Department).

```sql
- id (Primary Key)
- no (UNIQUE)
- supplier_agent
- supplier_valid_until
- product_materials
- product_type
- classification
- brand
- attachment_urls
```

#### `audit_log`
Menyimpan log aktiviti sistem untuk keselamatan.

```sql
- id (Primary Key)
- user_id (Foreign Key)
- action
- details
- ip_address
```

---

##  Pemasangan Dan Deployment

### Prasyarat
- Java JDK 11 atau lebih tinggi
- Apache Maven 3.6+
- Apache Tomcat 9.0+
- MySQL 8.0+

### Langkah 1: Sediakan Pangkalan Data

```bash
mysql -u root -p < database/schema.sql
```

### Langkah 2: Konfigurasi Sambungan Database
Edit `src/main/java/com/sistemppa/config/DatabaseConfig.java`:

```java
config.setJdbcUrl("jdbc:mysql://localhost:3306/sistemppa");
config.setUsername("root");
config.setPassword("your_password");
```

### Langkah 3: Bina & Deploy dengan Maven

```bash
mvn clean package
# Kemudian salin sistemppa.war ke tomcat/webapps/
```

Akses di: `http://localhost:8080/sistemppa`

### Langkah 4: Import Data Produk Air (Pilihan)

```bash
python SistemPPA.py
```

---

## Lancarkan Sistem (Quick Start)

### Cara Terpantas

```powershell
# Dari mana-mana direktori (tidak perlu Administrator)
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\startup-system.ps1" -NoBrowser
```

**Apa yang dilakukan automatik:**
- Pastikan MySQL 8.0 berjalan
- Auto-kesan JAVA_HOME jika tidak ditetapkan
- Jalankan Tomcat
- Sahkan endpoint HTTP 200

### Akses Sistem
- **Lokal (Komputer Server)**: `http://localhost:8081/sistemppa/`
- **Jaringan LAN**: `http://192.168.1.52:8081/sistemppa/`

---

## Sistem Sentiasa Berjalan (Always-On)

### Arahan Pantas

| Tujuan | Perintah |
|--------|----------|
| Mulakan sistem | `powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\startup-system.ps1" -NoBrowser` |
| Mulakan watchdog | `powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\always-run-system.ps1"` |
| Auto update bila kod berubah | `powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\dev-auto-update.ps1" -RunOnStart` |
| Daftar autostart (Windows boot) | `powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\register-autostart.ps1"` |
| Semak status watchdog | `Get-ScheduledTask -TaskName SPPPA-AlwaysRun | Select-Object TaskName,State` |
| Semak log watchdog | `Get-Content "p:\ProjectLI\runtime\watchdog.log" -Tail 30` |
| Henti watchdog manual | `Stop-ScheduledTask -TaskName SPPPA-AlwaysRun` |
| Buang autostart | `powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\register-autostart.ps1" -Unregister` |
| Tutup sistem | `powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\shutdown-system.ps1"` |

### Cara Daftarkan Autostart (Satu Kali Sahaja)

Jalankan **sekali** sebagai Administrator untuk daftarkan Windows Task Scheduler:

```powershell
# Buka PowerShell sebagai Administrator kemudian:
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\register-autostart.ps1"
```

Selepas ini, SPPPA akan dimulakan secara automatik setiap kali Windows dihidupkan tanpa perlu tindakan manual.

### Cara Watchdog Berfungsi

```text
Windows Boot
     |
     v
Task Scheduler -> ops-scripts\_task-launcher.ps1
                          |
                          v
                 always-run-system.ps1  (setiap 45 saat)
                          |
                  +-------+-------+
                  |               |
              SIHAT?          TIDAK SIHAT?
                  |               |
             Log & tunggu    startup-system.ps1
                                  |
                             Tomcat dimulakan semula
```

### Auto Build + Deploy Untuk Kerja Coding

Kalau ada ubah kod Java atau JSP dan mahu sistem deploy semula secara automatik, jalankan watcher ini dalam terminal berasingan:

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\dev-auto-update.ps1" -RunOnStart
```

Watcher ini akan pantau:
- `src/main/java`
- `src/main/webapp`
- `pom.xml`

Setiap kali perubahan dikesan, skrip akan jalankan build dan deploy WAR secara automatik.

### Semak Status Sistem

```powershell
# Semak sama ada endpoint boleh diakses
Invoke-WebRequest http://localhost:8081/sistemppa/ -UseBasicParsing | Select-Object StatusCode

# Semak status task scheduler
Get-ScheduledTask -TaskName SPPPA-AlwaysRun | Select-Object TaskName, State, LastRunTime, LastTaskResult

# Lihat log terbaharu
Get-Content "p:\ProjectLI\runtime\watchdog.log" -Tail 30
```

---

**Dokumen Lanjut:**
- **[PANDUAN_PENGGUNA.md](PANDUAN_PENGGUNA.md)** - Untuk pengguna akhir (maklumat log masuk, fungsi, semak masalah)
- **[LANCARKAN_SISTEM.md](LANCARKAN_SISTEM.md)** - Untuk pentadbir (cara hidupkan sistem, tutup sistem, uji sistem, akses rangkaian)

---

##  Akaun Default

| Peranan | Username | Kata Laluan | Nota |
|---------|----------|-------------|------|
| Pentadbir | admin | admin123 | Tukar selepas log masuk pertama |
| Pemohon | (Daftar sendiri) | - | Pengguna baharu boleh mendaftar |

> **Catatan**: Sistem berjalan di port **8081** (bukan port default 8080)

---

##  Halaman Utama

### Halaman Log Masuk (`/login`)
- Pengesahan nama pengguna dan kata laluan
- Sokongan untuk dua peranan (Pentadbir dan Pemohon)
- Keselamatan sesi dengan HTTP-only cookies

### Dashboard Pentadbir (`/admin-dashboard`)
- Statistik sistem (jumlah permohonan, status tertangguh)
- Senarai permohonan yang perlu dikaji
- Tindakan untuk meluluskan/menolak permohonan

### Dashboard Pemohon (`/user-dashboard`)
- Lihat status permohonan mereka
- Kemaskini profil dan kata laluan
- Akses senarai produk yang telah diluluskan

### Halaman Utama (`/index.jsp`)
- Maklumat tentang sistem
- Butiran ciri dan peranan pengguna
- Pautan untuk log masuk

---

##  Keselamatan

- Pengesahan kata laluan dengan SHA-256 hashing
- Sesi dengan timeout (30 minit)
- HTTP-only cookies untuk sesi
- Audit log untuk semua aktiviti penting
- Pengesahan input (SQL injection protection)
- Status pengguna (suspend/inactive)

---

##  Data Import

Data produk air dari Sabah Water Department telah dikumpul dan disimpan dalam:
- **JSON**: `data/water_products.json` (267 produk)
- **CSV**: `data/water_products.csv`

---

##  Skrip & Dokumen Penting Dalam Repo

### Skrip Operasi - Startup Dan Shutdown Sistem
- `ops-scripts/startup-system.ps1` - Lancarkan sistem (MySQL + Tomcat, auto-kesan JAVA_HOME)
- `ops-scripts/shutdown-system.ps1` - Tutup sistem (Tomcat + optional MySQL)
- `ops-scripts/always-run-system.ps1` - Watchdog: semak endpoint setiap 45 saat, restart Tomcat jika mati
- `ops-scripts/register-autostart.ps1` - Daftar/nyahaktif Windows Task Scheduler untuk autostart semasa boot
- `ops-scripts/build-and-deploy.ps1` - Build WAR (`mvn clean package`) dan deploy ke Tomcat `webapps`
- `ops-scripts/smoke-test.ps1` - Ujian pantas endpoint utama sistem
- `SistemPPA.py` - Skrip ambil atau kemas kini data produk air

### Dokumen Penting
- `README.md` - Panduan setup, deployment, dan struktur sistem
- `database/schema.sql` - Skema pangkalan data utama
- `docs/ERD-SPPPA.md` - Dokumen ERD sistem
- `src/main/webapp/assets/forms/*.pdf` - Borang PPP1/PPP2 dan garis panduan rasmi

---

##  Teknologi Digunakan (Detail)

Bahagian ini menerangkan komponen sebenar yang digunakan untuk membina, menjalankan, dan mengoperasikan SPPPA berdasarkan kod projek semasa.

### A. Aplikasi Web Utama (Java)

- **Bahasa & Runtime**: Java 21
  - Ditetapkan dalam `pom.xml` melalui `maven.compiler.source=21` dan `maven.compiler.target=21`.
- **Seni bina backend**: Jakarta Servlet + JSP (tanpa framework MVC berat)
  - Sesuai untuk aplikasi pentadbiran dalaman dan aliran borang/permohonan.
- **Servlet API**: `jakarta.servlet:jakarta.servlet-api:6.1.0` (`scope: provided`)
- **Build tool**: Apache Maven
  - Packaging aplikasi: `war`
  - Plugin utama:
  - `maven-war-plugin:3.3.2` (menghasilkan `sistemppa.war`)
  - `maven-compiler-plugin:3.14.0`
  - `maven-surefire-plugin:3.5.4`

### B. Pelayan Aplikasi

- **Application server**: Apache Tomcat
  - Runtime semasa projek: `runtime/apache-tomcat-11.0.18`
  - Port operasi aktif semasa: `8081`
  - Aplikasi dideploy sebagai: `sistemppa.war`

### C. Pangkalan Data

- **DBMS**: MySQL 8.x
- **Driver JDBC**: `com.mysql:mysql-connector-j:9.2.0`
- **Connection pooling**: `com.zaxxer:HikariCP:5.0.1`
- **Schema utama**: `database/schema.sql`

### D. Pemprosesan Data & Dokumen

- **JSON**: `com.google.code.gson:gson:2.10.1`
- **Excel/OOXML**: `org.apache.poi:poi-ooxml:5.2.5`
- **PDF**: `com.github.librepdf:openpdf:1.3.39`

### E. Logging

- **Logging API**: `org.slf4j:slf4j-api:2.0.5`
- **Implementasi log ringkas**: `org.slf4j:slf4j-simple:2.0.5`

### F. Frontend

- **View layer**: JSP
- **Web statik**: HTML5, CSS, JavaScript (di bawah `src/main/webapp`)
- **Aset UI**: `src/main/webapp/assets`

### G. Automasi Operasi (Windows)

- **Skrip operasi**: PowerShell (`ops-scripts/*.ps1`)
- Fungsi utama operasi:
  - startup/shutdown sistem
  - build + deploy WAR automatik
  - watchdog kesihatan endpoint
  - autostart melalui Task Scheduler

### H. Skrip Data Import (Python)

- **Fail**: `SistemPPA.py`
- **Kegunaan**: scrape data produk air rasmi dan simpan ke JSON/CSV serta upsert ke MySQL
- **Pakej Python digunakan**:
  - `requests`
  - `beautifulsoup4`
  - `mysql-connector-python`

### I. Output Build & Data

- **Artefak deploy Java**: `target/sistemppa.war`
- **Data produk air (hasil skrip Python)**:
  - `data/water_products.json`
  - `data/water_products.csv`

### J. Ringkasan Stack (Satu Baris)

SPPPA dibina menggunakan **Java 21 + Jakarta Servlet/JSP + Maven (WAR) + Tomcat + MySQL + HikariCP + SLF4J**, serta **Python scraper** untuk pengumpulan dan penyegaran data produk air.

---

##  API Endpoints Tambahan

Berikut ialah contoh REST API yang boleh ditambah:

- POST   /api/auth/login                - Log masuk
- POST   /api/auth/logout               - Log keluar
- POST   /api/auth/register             - Pendaftaran pengguna baharu
- GET    /api/applications              - Senarai permohonan (admin)
- POST   /api/applications              - Hantar permohonan baharu (user)
- GET    /api/applications/{id}         - Butir permohonan
- PUT    /api/applications/{id}         - Kemas kini permohonan
- PUT    /api/applications/{id}/approve - Luluskan permohonan (admin)
- PUT    /api/applications/{id}/reject  - Tolak permohonan (admin)
- GET    /api/products                  - Senarai produk air
- GET    /api/users                     - Senarai pengguna (admin)
- POST   /api/users                     - Cipta pengguna pentadbir (admin)
- PUT    /api/users/{id}                - Kemaskini profil pengguna

---

##  Semak Masalah

### Ralat Sambungan Database

Error: Access denied for user 'root'@'localhost'
Penyelesaian: Semak nama pengguna, kata laluan, dan port MySQL

### Halaman Blank Selepas Build

Penyelesaian: Pastikan web.xml berada di src/main/webapp/WEB-INF/

### Port 8080 Sudah Digunakan

Penyelesaian: Tukar port di server.xml Tomcat atau hentikan aplikasi lain

---

##  Sokongan & Maklum Balas

Untuk sokongan teknikal atau cadangan ciri, hubungi:
- Email: admin@sistemppa.gov.my
- Jabatan Air Negeri Sabah

---

##  Lesen

Sistem ini dibangunkan untuk Jabatan Air Negeri Sabah.
Semua hak terpelihara (c) 2026.

---

**Versi**: 1.0.0
**Tarikh**: 17 Mei 2026
**Status**: Beta (Dalam pembangunan)
