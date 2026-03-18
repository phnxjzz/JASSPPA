# startup-system.ps1
# Script untuk memulakan Sistem Pendaftaran Produk Air (SPPA)
# Uso: powershell -ExecutionPolicy Bypass -File startup-system.ps1

param(
    [string]$ProjectRoot = "p:\ProjectLI",
    [string]$TomcatHome = "$ProjectRoot\runtime\apache-tomcat-11.0.18",
    [int]$WaitSeconds = 10
)

# Fungsi untuk log mesej
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Type) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

# Periksa jika running as Administrator
$admin = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Error: Script ini mesti dijalankan sebagai Administrator" "ERROR"
    exit 1
}

Write-Log "========================================" "INFO"
Write-Log "Sistem SPPA Startup Script" "INFO"
Write-Log "========================================" "INFO"

# 1. Periksa MySQL
Write-Log "Memeriksa MySQL 8.0..." "INFO"
try {
    $mysqlService = Get-Service MySQL80 -ErrorAction SilentlyContinue
    if ($mysqlService) {
        if ($mysqlService.Status -eq "Running") {
            Write-Log "MySQL 8.0 sudah berjalan" "SUCCESS"
        } else {
            Write-Log "Memulakan MySQL 8.0..." "INFO"
            Start-Service MySQL80 -ErrorAction Stop
            Start-Sleep -Seconds 3
            Write-Log "MySQL 8.0 berjalan" "SUCCESS"
        }
    } else {
        Write-Log "Warning: MySQL 8.0 tidak ditemui. Database mungkin tidak tersedia." "WARN"
    }
} catch {
    Write-Log "Error memulakan MySQL: $_" "ERROR"
}

# 2. Periksa Tomcat
Write-Log "Memeriksa Tomcat..." "INFO"
$startupScript = "$TomcatHome\bin\startup.bat"
if (-not (Test-Path $startupScript)) {
    Write-Log "Error: Tomcat tidak ditemui di $TomcatHome" "ERROR"
    exit 1
}

# 3. Periksa jika Tomcat sudah berjalan
$javaProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcess) {
    Write-Log "Tomcat sudah berjalan (PID: $($javaProcess.Id))" "SUCCESS"
} else {
    Write-Log "Memulakan Tomcat..." "INFO"
    & $startupScript
    Write-Log "Tomcat dimulakan. Menunggu $WaitSeconds saat untuk startup..." "INFO"
    Start-Sleep -Seconds $WaitSeconds
}

# 4. Test koneksian
Write-Log "Menguji koneksian sistem..." "INFO"
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/sistemppa/" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Log "✅ Sistem boleh diakses: HTTP 200" "SUCCESS"
        Write-Log "" "INFO"
        Write-Log "========== AKSES SISTEM ==========" "INFO"
        Write-Log "URL Lokal: http://localhost:8081/sistemppa/" "INFO"
        Write-Log "URL Jaringan: http://192.168.1.52:8081/sistemppa/" "INFO"
        Write-Log "Admin Login: admin / admin123" "INFO"
        Write-Log "=================================" "INFO"
    } else {
        Write-Log "Warning: Sistem merespons dengan status $($response.StatusCode)" "WARN"
    }
} catch {
    Write-Log "Warning: Tidak boleh menguji koneksian: $_" "WARN"
    Write-Log "Tomcat mungkin masih startup. Cuba 10 saat lagi." "INFO"
}

# 5. Buka browser
Write-Log "" "INFO"
Write-Log "Membuka sistem di browser..." "INFO"
Start-Process "http://192.168.1.52:8081/sistemppa/" -ErrorAction SilentlyContinue

Write-Log "✅ Sistem siap digunakan!" "SUCCESS"
