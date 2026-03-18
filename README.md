# Sistem Pendaftaran Produk Air (SPPA)
## Water Product Registration System for Sabah

### Deskripsi Sistem
SPPA adalah platform web yang dirancang untuk menguruskan pendaftaran dan pengesahan produk air di Sabah. Sistem ini membolehkan pentadbir untuk mengesahkan permohonan dan pengguna awam untuk menghantar permohonan pendaftaran produk mereka.

---

## 🏗️ Struktur Projek

```
ProjectLI/
├── pom.xml                              # Maven configuration
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/sistemppa/
│   │   │       ├── config/
│   │   │       │   └── DatabaseConfig.java
│   │   │       ├── servlet/
│   │   │       │   ├── LoginServlet.java
│   │   │       │   ├── LogoutServlet.java
│   │   │       │   └── DashboardServlet.java
│   │   │       └── util/
│   │   └── webapp/
│   │       ├── WEB-INF/
│   │       │   └── web.xml
│   │       ├── assets/
│   │       ├── login.jsp
│   │       ├── admin-dashboard.jsp
│   │       ├── user-dashboard.jsp
│   │       └── index.jsp
├── database/
│   └── schema.sql                       # Database schema
├── data/
│   ├── water_products.json
│   └── water_products.csv
└── SistemPPA.py                         # Python scraper for data import
```

---

## 📋 Ciri-ciri Sistem

### Pentadbir
- ✅ Melihat dan menyemak permohonan
- ✅ Meluluskan atau menolak permohonan
- ✅ Menggantung akaun pengguna
- ✅ Mewujudkan akaun pentadbir baharu
- ✅ Melihat statistik sistem
- ✅ Audit log aktiviti

### Pemohon / Pengguna
- ✅ Membuat permohonan pendaftaran baharu
- ✅ Melihat profil dan status permohonan
- ✅ Mengemas kini maklumat akaun
- ✅ Tukar kata laluan
- ✅ Akses senarai produk berdaftar

---

## 🗄️ Pangkalan Data

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

## 🚀 Instalasi & Deployment

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

### Langkah 4: Import Data Produk Air (Opsyonal)
```bash
python SistemPPA.py
```

---

## � Lancarkan Sistem (Quick Start)

### **Cara Terpantas**
```powershell
# Buka PowerShell sebagai Administrator
cd p:\ProjectLI
.\ops-scripts\startup-system.ps1
```

**Apa yang dilakukan automatik:**
- Pastikan MySQL 8.0 berjalan
- Jalankan Tomcat
- Tunggu sistem siap
- Buka browser ke sistem

### **Akses Sistem**
- **Lokal (Komputer Server)**: `http://localhost:8081/sistemppa/`
- **Jaringan LAN**: `http://192.168.1.52:8081/sistemppa/`
- **Guna Pengguna**: Username/Password yang terdaftar

### **Tutup Sistem**
```powershell
.\ops-scripts\shutdown-system.ps1
```

**Dokumen Panjang:**
- 📖 **[PANDUAN_PENGGUNA.md](PANDUAN_PENGGUNA.md)** - Untuk pengguna akhir (login credentials, fitur, troubleshooting)
- 📖 **[LANCARKAN_SISTEM.md](LANCARKAN_SISTEM.md)** - Untuk admin (cara startup/shutdown, test system, akses jauh)

---

## �🔑 Akaun Default

| Peranan | Username | Kata Laluan | Nota |
|---------|----------|-------------|------|
| Pentadbir | admin | admin123 | Tukar selepas log masuk pertama |
| Pemohon | (Daftar sendiri) | - | Pengguna baharu boleh mendaftar |

> **Catatan**: Sistem berjalan di port **8081** (bukan port default 8080)

---

## 📱 Halaman Utama

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

## 🔐 Keselamatan

- ✅ Pengesahan kata laluan dengan SHA-256 hashing
- ✅ Sesi dengan timeout (30 minit)
- ✅ HTTP-only cookies untuk sesi
- ✅ Audit log untuk semua aktiviti penting
- ✅ Pengesahan input (SQL injection protection)
- ✅ Status pengguna (suspend/inactive)

---

## 📦 Data Impor

Data produk air dari Sabah Water Department telah dikumpul dan disimpan dalam:
- **JSON**: `data/water_products.json` (267 produk)
- **CSV**: `data/water_products.csv`

---

## 📁 Skrip & Dokumen Penting Dalam Repo

### Skrip Operasi - Sistem Startup/Shutdown
- `ops-scripts/startup-system.ps1` - **Lancarkan sistem** (MySQL + Tomcat + browser auto-open)
- `ops-scripts/shutdown-system.ps1` - **Tutup sistem** (Tomcat + optional MySQL)
- `ops-scripts/build-and-deploy.ps1` - Build WAR (`mvn clean package`) dan deploy ke Tomcat `webapps`
- `ops-scripts/smoke-test.ps1` - Ujian pantas endpoint utama sistem
- `SistemPPA.py` - Skrip pengambilan/kemas kini data produk air

### Dokumen Penting
- **[PANDUAN_PENGGUNA.md](PANDUAN_PENGGUNA.md)** - Panduan untuk pengguna akhir (login, fitur, troubleshooting)
- **[LANCARKAN_SISTEM.md](LANCARKAN_SISTEM.md)** - Panduan untuk admin (startup, shutdown, network access)
- `README.md` - Panduan setup, deployment, dan architecture
- `database/schema.sql` - Skema pangkalan data utama
- `docs/ERD-SPPA.md` - Dokumen ERD sistem
- `src/main/webapp/assets/forms/*.pdf` - Borang PPP1/PPP2 dan garis panduan rasmi

---

## 🛠️ Teknologi Digunakan

- **Backend**: Java Servlet + JSP
- **Framework**: Maven (Build)
- **Database**: MySQL 8.0
- **Server**: Apache Tomcat 9.0+
- **Frontend**: HTML5 + CSS3 + JavaScript
- **Connection Pool**: HikariCP
- **Logging**: SLF4J

---

## 📝 API Endpoints (Dilanjutkan)

Berikut adalah enkripsi REST API yang boleh ditambah:

```
POST   /api/auth/login          - Log masuk
POST   /api/auth/logout         - Log keluar
POST   /api/auth/register       - Pendaftaran pengguna baharu

GET    /api/applications         - Senarai permohonan (admin)
POST   /api/applications         - Hantar permohonan baharu (user)
GET    /api/applications/{id}    - Butir permohonan
PUT    /api/applications/{id}    - Kemas kini permohonan
PUT    /api/applications/{id}/approve - Luluskan permohonan (admin)
PUT    /api/applications/{id}/reject  - Tolak permohonan (admin)

GET    /api/products            - Senarai produk air
GET    /api/users               - Senarai pengguna (admin)
POST   /api/users               - Cipta pengguna pentadbir (admin)
PUT    /api/users/{id}          - Kemaskini profil pengguna
```

---

## 🐛 Troubleshooting

### Ralat Sambungan Database
```
Error: Access denied for user 'root'@'localhost'
Penyelesaian: Semak nama pengguna, kata laluan, dan port MySQL
```

### Halaman Blank Selepas Build
```
Penyelesaian: Pastikan web.xml berada di src/main/webapp/WEB-INF/
```

### Port 8080 Sudah Digunakan
```
Penyelesaian: Tukar port di server.xml Tomcat atau hentikan aplikasi lain
```

---

## 📧 Sokongan & Maklumbalas

Untuk sokongan teknis atau cadangan ciri, hubungi:
- Email: admin@sistemppa.gov.my
- Jabatan Air Negeri Sabah

---

## 📄 Lesen

Sistem ini dibangunkan untuk Jabatan Air Negeri Sabah.
Semua hak terpelihara © 2026.

---

**Versi**: 1.0.0  
**Tarikh**: 17 Mei 2026  
**Status**: Beta (Dalam pembangunan)
