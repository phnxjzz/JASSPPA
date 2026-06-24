param(
    [string]$DbHost = "localhost",
    [int]$Port = 3306,
    [string]$Database = "sistemppa",
    [string]$User = "root",
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

function ConvertTo-PlainText {
    param(
        [Parameter(Mandatory = $true)]
        [Security.SecureString]$SecureValue
    )

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Invoke-MySqlQuery {
    param(
        [string]$Query
    )

    $mysqlCommand = Get-Command mysql -ErrorAction SilentlyContinue
    $mysqlExePath = $null

    if ($mysqlCommand) {
        $mysqlExePath = $mysqlCommand.Source
    }
    else {
        $candidatePaths = @(
            "C:\\Program Files\\MySQL",
            "C:\\Program Files (x86)\\MySQL",
            "C:\\Program Files\\MariaDB",
            "C:\\xampp\\mysql\\bin"
        )

        foreach ($basePath in $candidatePaths) {
            if (-not (Test-Path $basePath)) {
                continue
            }

            $mysqlCandidates = Get-ChildItem -Path $basePath -Filter "mysql.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
            if ($mysqlCandidates -and $mysqlCandidates.Count -gt 0) {
                $mysqlExePath = $mysqlCandidates[0]
                break
            }
        }
    }

    if (-not $mysqlExePath) {
        throw "MySQL CLI (mysql) tidak dijumpai dalam PATH atau lokasi biasa. Sila pasang MySQL Client atau tambah mysql.exe ke PATH."
    }

    $arguments = @(
        "-h", $DbHost,
        "-P", "$Port",
        "-u", $User,
        "--batch",
        "--raw",
        "--silent",
        "-e", $Query
    )

    if (-not [string]::IsNullOrEmpty($Password)) {
        $arguments = @("--password=$Password") + $arguments
    }

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $result = (& $mysqlExePath @arguments 2>&1)
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }

    if ($LASTEXITCODE -ne 0) {
        $joinedMessage = ($result | ForEach-Object { "$_" }) -join [Environment]::NewLine
        throw "Gagal menjalankan query MySQL. Semak host/user/password. Butiran: $joinedMessage"
    }

    return $result
}

Write-Host "[INFO] Menyambung ke MySQL $DbHost`:$Port (DB: $Database, User: $User)..."

$query = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$Database' ORDER BY TABLE_NAME;"
$results = $null

try {
    $results = Invoke-MySqlQuery -Query $query
}
catch {
    $errorMessage = $_.Exception.Message
    $needsPasswordRetry = [string]::IsNullOrEmpty($Password) -and ($errorMessage -match "ERROR 1045" -or $errorMessage -match "using password: NO")

    if ($needsPasswordRetry) {
        Write-Host "[WARN] Akaun '$User' memerlukan kata laluan MySQL."
        $securePassword = Read-Host "Masukkan kata laluan MySQL untuk '$User'" -AsSecureString
        $Password = ConvertTo-PlainText -SecureValue $securePassword

        if ([string]::IsNullOrWhiteSpace($Password)) {
            throw "Kata laluan kosong. Sila jalankan semula dan masukkan kata laluan MySQL yang betul."
        }

        Write-Host "[INFO] Cuba semula sambungan dengan kata laluan..."
        $results = Invoke-MySqlQuery -Query $query
    }
    else {
        throw
    }
}

if (-not $results -or $results.Count -eq 0) {
    Write-Host "[WARN] Tiada jadual ditemui untuk database '$Database'."
    exit 0
}

 $results = @($results | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and ($_ -notmatch '^mysql:\s*\[Warning\]')
})

if (-not $results -or $results.Count -eq 0) {
    Write-Host "[WARN] Tiada jadual ditemui untuk database '$Database'."
    exit 0
}

Write-Host "[SUCCESS] Senarai jadual dalam '$Database':"
foreach ($tableName in $results) {
    Write-Host " - $tableName"
}
