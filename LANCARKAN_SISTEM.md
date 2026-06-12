# Lancarkan Sistem SPPA

##  Cara (Bagi Pentadbir)

### **Pilihan 1: Guna Script PowerShell (Recommended)**
```powershell
# Buka PowerShell sebagai Administrator
cd p:\ProjectLI
.\ops-scripts\startup-system.ps1
```

### **Pilihan 2: Manual Startup**
```powershell
# 1. Buka PowerShell sebagai Administrator

# 2. Pastikan MySQL sedang berjalan
Get-Service MySQL80 | Start-Service

# 3. Tunggu 3 saat
Start-Sleep -Seconds 3

# 4. Jalankan Tomcat
 $env:JAVA_HOME = "C:\Program Files\Java\jdk-21.0.10"
>> $env:CATALINA_HOME = "p:\ProjectLI\runtime\apache-tomcat-11.0.18"
>> $env:CATALINA_BASE = "p:\ProjectLI\runtime\apache-tomcat-11.0.18"
>> & "p:\ProjectLI\runtime\apache-tomcat-11.0.18\bin\startup.bat"

# 5. Tunggu 10 saat untuk Tomcat startup
Start-Sleep -Seconds 10

# 6. Buka Browser dan pergi ke:
Start-Process "http://192.168.1.52:8081/sistemppa/"
```

### **Pilihan 3: Batch File (Klik 2x)**
```batch
@echo off
REM startup-system.bat
REM Letakkan file ini di p:\ProjectLI\
echo Memulakan Sistem SPPA...
p:\ProjectLI\runtime\apache-tomcat-11.0.18\bin\startup.bat
echo Sistem sedang dimulakan. Tunggu 10 saat...
timeout /t 10
start http://192.168.1.52:8081/sistemppa/
```

---

##  Sahkan Sistem Berjalan

```powershell
# Cek Tomcat
Get-Process | Where-Object { $_.ProcessName -eq "java" }

# Cek MySQL
Get-Service MySQL80 | Select-Object Name, Status

# Test URL
Invoke-WebRequest -Uri "http://localhost:8081/sistemppa/" -UseBasicParsing
```

---

##  Tutup Sistem (Maintenance)

```powershell
# Tutup Tomcat
p:\ProjectLI\runtime\apache-tomcat-11.0.18\bin\shutdown.bat

# Tutup MySQL (optional)
Stop-Service MySQL80
```

---

##  Akses dari Perangkat Lain

**UDP Network:**
- Guest/Pengguna: `http://192.168.1.52:8081/sistemppa/`
- Admin: `http://192.168.1.52:8081/sistemppa/admin-dashboard.jsp`

**Pautan QR Code (untuk mudah berkongsi):**
```
https://qr.net/?q=http%3A%2F%2F192.168.1.52%3A8081%2Fsistemppa%2F
```

---

**Catatan Penting:**
- Pastikan firewall membenarkan port 8081
- Server mesti sentiasa hidup untuk akses jauh
- Lakukan backup data secara berkala
