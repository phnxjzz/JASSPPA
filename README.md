# Sistem Pendaftaran Produk Air (SPPPA)

Sistem ini ialah aplikasi web untuk pengurusan permohonan pendaftaran produk air di Jabatan Air Sabah.

## Ringkasan

SPPPA digunakan untuk:

- Pendaftaran permohonan produk air oleh pemohon
- Semakan dan keputusan permohonan oleh pentadbir
- Pengurusan data produk berdaftar
- Jejak audit aktiviti sistem

## Teknologi

- Java (WAR web application)
- Jakarta Servlet
- MySQL
- HikariCP
- Maven
- Apache Tomcat

## Ciri Utama

### Pentadbir

- Semak permohonan
- Lulus/tolak permohonan
- Urus akaun pengguna
- Lihat statistik dan log audit

### Pemohon

- Hantar permohonan baharu
- Lihat status permohonan
- Kemas kini profil akaun

## Struktur Projek

```text
src/main/java         Kod backend (servlet, config, util)
src/main/webapp       JSP, aset frontend, WEB-INF
database/schema.sql   Struktur pangkalan data
data/                 Data produk air (CSV/JSON)
ops-scripts/          Skrip operasi (startup, shutdown, deploy, smoke test)
runtime/              Runtime Tomcat
```

## Prasyarat

- Java JDK
- Maven
- MySQL
- Windows PowerShell

## Setup Pangkalan Data

```powershell
mysql -u root -p < database/schema.sql
```

Kemudian tetapkan sambungan DB dalam konfigurasi aplikasi:

- src/main/java/com/sistemppa/config/DatabaseConfig.java

## Build

```powershell
mvn clean package
```

Artefak hasil build ialah fail WAR bernama sistemppa.war.

## Jalankan Sistem

Cara paling mudah:

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\startup-system.ps1" -NoBrowser
```

Akses aplikasi:

- http://localhost:8081/sistemppa/

## Deploy dan Ujian Asas

Untuk build + deploy:

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\build-and-deploy.ps1"
```

Untuk semakan ringkas selepas deploy:

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\smoke-test.ps1"
```

## Henti Sistem

```powershell
powershell -ExecutionPolicy Bypass -File "p:\ProjectLI\ops-scripts\shutdown-system.ps1"
```
