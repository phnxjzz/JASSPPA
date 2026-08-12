# Sistem Pendaftaran Pembekal dan Produk Bekalan Air (SPPPBA)

SPPPBA ialah aplikasi web untuk pengurusan permohonan pendaftaran produk air Jabatan Air Sabah.

## Ringkasan

Sistem ini menyokong:

- pendaftaran permohonan oleh pemohon
- semakan, kelulusan, dan penolakan oleh pentadbir
- pengurusan data produk berdaftar
- jejak audit aktiviti sistem

## Teknologi Utama

- Java 21
- Jakarta Servlet 6.1 + JSP
- Maven (packaging WAR)
- Apache Tomcat 11.0.18
- MySQL 8 + HikariCP
- PowerShell untuk operasi startup/deploy/shutdown

## Struktur Penting Projek

```text
src/main/             Kod aplikasi Java + JSP
database/schema.sql   Skema pangkalan data utama
database/migrations/  Skrip migrasi tambahan
data/                 Dataset produk air (CSV/JSON)
ops-scripts/          Skrip operasi sistem
runtime/              Runtime Tomcat tempatan
target/               Output build WAR
```

## Prasyarat

- Windows + PowerShell
- Java JDK 21
- MySQL 8 (servis: MySQL80)

Nota:

- Projek menggunakan Maven wrapper tempatan di `tools/apache-maven-3.9.14/bin/mvn.cmd` melalui skrip deploy.
- Skrip `startup-system.ps1` dan `shutdown-system.ps1` memerlukan PowerShell dijalankan sebagai Administrator.

## Setup Pangkalan Data

```powershell
mysql -u root -p < database/schema.sql
```

Jika ada perubahan schema baharu, jalankan skrip dalam `database/migrations/` mengikut turutan tarikh.

Konfigurasi sambungan DB dalam kod aplikasi (contoh fail):

- `src/main/java/com/sistemppa/config/DatabaseConfig.java`

## Build Dan Deploy

Kaedah disyorkan (guna skrip projek):

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\build-and-deploy.ps1"
```

Skrip ini akan:

1. jalankan `clean package`
2. hasilkan `target/sistemppa.war`
3. deploy WAR ke `runtime/apache-tomcat-11.0.18/webapps/`

## Jalankan Sistem

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\startup-system.ps1"
```

Akses aplikasi:

- http://localhost:8081/sistemppa/

## Ujian Ringkas (Smoke Test)

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\smoke-test.ps1"
```

Endpoint asas yang diuji:

- `/`
- `/login`
- `/register`
- `/forgot-password`
- `/products`

## Henti Sistem

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\shutdown-system.ps1"
```

## VS Code Tasks

Task yang tersedia dalam workspace ini:

- `Build and Deploy (SPPPBA)`
- `Startup System (SPPPBA)`
- `Smoke Test (SPPPBA)`
- `Shutdown System (SPPPBA)`

## Data Produk

Fail data utama:

- `data/water_products.csv`
- `data/water_products.json`

Skrip berkaitan data:

- `SistemPPA.py`

## Akaun Pentadbir Lalai

Berdasarkan maklumat pada skrip startup:

- username: `Administrator`
- kata laluan: `Administrator@001`

Sila tukar kata laluan selepas log masuk pertama.

## Troubleshooting Ringkas

1. MySQL tidak dapat diakses:
   - pastikan servis `MySQL80` wujud dan berjalan.
2. Tomcat tidak bermula:
   - semak laluan `runtime/apache-tomcat-11.0.18`.
3. Endpoint gagal selepas deploy:
   - jalankan `smoke-test.ps1` dan semak output status setiap URL.

## Dokumen Berkaitan

- `docs/ERD-SPPA.md`
- `docs/reverse-proxy-setup.md`
- `database/schema.sql`

## Maklumat Versi

- Versi: `1.0.0`
- Tarikh kemas kini README: `2026-08-12`
