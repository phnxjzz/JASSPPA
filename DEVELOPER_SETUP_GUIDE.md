# Developer Setup Guide (Windows)

This guide is for developers who want to run and deploy SPPA on their own computer.

## 1) Clone Project

```powershell
git clone https://github.com/phnxjzz/JASSPPA.git
cd JASSPPA
```

## 2) Prerequisites

Install these first:
- Java JDK 21
- MySQL 8.x (service name usually `MySQL80`)
- Git
- PowerShell 5.1+

## 3) Setup Database

```powershell
mysql -u root -p < database/schema.sql
```

## 4) Build and Deploy WAR

```powershell
powershell -ExecutionPolicy Bypass -File ".\\ops-scripts\\build-and-deploy.ps1" -ProjectRoot "$PWD"
```

## 5) Start System

```powershell
powershell -ExecutionPolicy Bypass -File ".\\ops-scripts\\startup-system.ps1" -ProjectRoot "$PWD" -TomcatHome "$PWD\\runtime\\apache-tomcat-11.0.18" -NoBrowser
```

## 6) Verify

Open:
- http://localhost:8081/sistemppa/

Optional command check:

```powershell
Invoke-WebRequest -Uri "http://localhost:8081/sistemppa/" -UseBasicParsing | Select-Object StatusCode
```

Expected: `StatusCode = 200`

## 7) Key Documents

- Main overview: [README.md](README.md)
- Startup and operations: [LANCARKAN_SISTEM.md](LANCARKAN_SISTEM.md)
- Script execution order: [ops-scripts/EXECUTION_ORDER.md](ops-scripts/EXECUTION_ORDER.md)
- Database schema: [database/schema.sql](database/schema.sql)

## 8) Share Full Project To Remote (Including Ignored Folders)

This repository currently ignores `runtime/` and `tools/` in `.gitignore`.
If you must include those folders in remote, use force-add:

```powershell
git add .
git add -f runtime tools
git commit -m "Share full project for team onboarding"
git push origin HEAD
```

If push fails due to large files, use Git LFS:

```powershell
git lfs install
git lfs track "runtime/**" "tools/**"
git add .gitattributes
git add -f runtime tools
git commit -m "Track runtime/tools with Git LFS"
git push origin HEAD
```

## 9) Recommended Team Workflow

- Keep source changes in `src/` and `database/`.
- Prefer not committing runtime binaries unless required for offline setup.
- For normal daily work, run startup script and deploy from source.
