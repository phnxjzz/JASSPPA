# 🚀 Google Cloud Platform (GCP) - Step-by-Step Deployment Guide

## ⏱️ Estimated Time: 30-45 minutes
## 💰 Cost: **$300 free credits** for 3 months, then ~$10-20/month

---

## 📋 GCP Architecture for SPPA

```
┌─────────────────────────────────────────────────────────┐
│                    SPPA on Google Cloud                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Cloud Load Balancer + Cloud Armor (DDoS)       │  │
│  │  + Cloud CDN (for static files)                  │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↓                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Cloud Run (Containerized Java app)              │  │
│  │  OR App Engine Flexible (Tomcat runtime)         │  │
│  │  - Automatic scaling                             │  │
│  │  - Built-in monitoring                           │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↓                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Cloud SQL (MySQL 8.0)                           │  │
│  │  - Automated backups daily                        │  │
│  │  - Read replicas for HA                           │  │
│  │  - Point-in-time recovery                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Monitoring: Cloud Logging, Cloud Monitoring           │
│  DNS: Cloud DNS (for sppa.gov)                         │
│  SSL: Google-managed certificates (FREE)              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 LANGKAH 1: Create Google Cloud Account & Setup Billing

### 1.1 Register / Login Google Cloud
```
1. Pergi ke: https://cloud.google.com/free
2. Klik "Get Started Free"
3. Sign in dengan Google account (atau buat baru)
4. Verify email
```

### 1.2 Setup Billing (Free $300 Credits)
```
1. Google Cloud Console → Billing
2. Link credit card (No charge for free tier)
3. Verify: $300 free credits sudah tertera
4. Free tier limits:
   - Compute Engine: 750 hours/month (f1-micro instance)
   - Cloud SQL: 1 shared-core instance (db-f1-micro)
   - Cloud Storage: 5GB
   - Cloud Pub/Sub: 10GB/month
   - All WITHIN free tier for testing!
```

---

## 🎯 LANGKAH 2: Create New GCP Project

### 2.1 Create Project
```
1. Google Cloud Console → Projects (top left dropdown)
2. Klik "Select a Project" → "NEW PROJECT"
3. Project Name: "SPPA" atau "Sistem Pendaftaran Produk Air"
4. Location: Global
5. Klik "CREATE"
6. Tunggu ~30 saat project tercipta
```

### 2.2 Enable Required APIs
```
Di Google Cloud Console:
1. APIs & Services → Enabled APIs
2. Enable these APIs:
   - Cloud Run API
   - Cloud Build API
   - Cloud SQL Admin API
   - Compute Engine API
   - Container Registry API
   - App Engine Admin API
   - Cloud DNS API
```

**Quick Enable (guna Cloud Shell):**
```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable appengine.googleapis.com
gcloud services enable dns.googleapis.com
```

---

## 🎯 LANGKAH 3: Setup Cloud SQL (MySQL Database)

### 3.1 Create Cloud SQL Instance
```
Google Cloud Console:
1. SQL → Create Instance
2. Pilih: MySQL
3. Instance ID: sistemppa-db
4. Password: Create strong root password (min 12 chars)
5. Database version: MySQL 8.0
6. Edition: Standard tier (cheaper, sufficient)
7. Region: IMPORTANT - Pilih yang SAMA dengan App Engine/Cloud Run region (e.g., asia-southeast1 = Malaysia)
8. Zonal availability: Multi-zone (untuk HA)
9. Machine type: db-f1-micro (dalam free tier!)
10. Klik "CREATE"
```

Tunggu 5-10 menit untuk Cloud SQL instance ready...

### 3.2 Create Database
```bash
# Option 1: Guna Google Cloud Console
1. Cloud SQL → Instance → sistemppa-db
2. Databases tab → Create Database
3. Name: sistemppa
4. Charset: utf8mb4
5. Collation: utf8mb4_unicode_ci
6. Klik "CREATE"

# Option 2: Guna Cloud Shell
gcloud sql databases create sistemppa \
  --instance=sistemppa-db \
  --charset=utf8mb4 \
  --collation=utf8mb4_unicode_ci
```

### 3.3 Import Database Schema
```bash
# Option 1: Guna Cloud Shell (EASIEST)
1. Upload schema.sql ke Cloud Shell
   gcloud compute scp database/schema.sql ~/
   
2. Import ke Cloud SQL
   gcloud sql import sql sistemppa-db \
     ~/schema.sql \
     --database=sistemppa

# Option 2: Guna MySQL Client
gcloud cloud-sql-proxy --instances=project-id:region:sistemppa-db &
mysql -u root -h 127.0.0.1 sistemppa < database/schema.sql

# Option 3: Guna Google Cloud Console (UI)
1. Cloud SQL → sistemppa-db → SQL Workbench
2. Copy-paste schema.sql content
3. Execute query
```

### 3.4 Create App User (Optional, for security)
```bash
# Instead of using root, buat app user
gcloud sql users create app_user \
  --instance=sistemppa-db \
  --password=your_app_password

# OR in Cloud Shell MySQL:
mysql -u root -h cloud_sql_instance
CREATE USER 'app_user'@'%' IDENTIFIED BY 'your_app_password';
GRANT ALL PRIVILEGES ON sistemppa.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

---

## 🎯 LANGKAH 4: Containerize Java Application

### 4.1 Create Dockerfile
```dockerfile
# Dockerfile (create in project root: p:\ProjectLI\Dockerfile)

FROM openjdk:21-jdk-slim

# Install Tomcat
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . /app
WORKDIR /app

# Build WAR
RUN mvn clean package -DskipTests

# Extract and run WAR in Tomcat-like mode
FROM openjdk:21-jdk-slim
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=0 /app/target/sistem-pendaftaran-produk-air-1.0.0.war /app.war

# Port (GCP Cloud Run will set PORT env var)
ENV PORT=8080
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/sistemppa/ || exit 1

# Run WAR with Spring Boot embedded Tomcat
CMD ["java", "-Xmx512m", "-Xms256m", "-jar", "/app.war", "--server.port=$PORT"]
```

### 4.2 Create .dockerignore
```
.git
.gitignore
.env
target/
*.log
node_modules/
project_env/
Scripts/
database/backups/
README.md
```

### 4.3 Build & Test Locally (Optional)
```bash
# Build Docker image locally
docker build -t gcr.io/your-project-id/sistemppa:1.0.0 .

# Test run
docker run -p 8080:8080 \
  -e DATABASE_URL="jdbc:mysql://host.docker.internal:3306/sistemppa" \
  -e DATABASE_USER="root" \
  -e DATABASE_PASSWORD="your-password" \
  gcr.io/your-project-id/sistemppa:1.0.0
```

---

## 🎯 LANGKAH 5: Deploy to Cloud Run (or App Engine)

### OPTION A: Cloud Run (Recommended - Simpler)

#### 5A.1: Push Docker Image to Container Registry
```bash
# In Cloud Shell / local with gcloud CLI:

# Configure Docker
gcloud auth configure-docker

# Build and push to Google Container Registry (GCR)
gcloud builds submit --tag gcr.io/YOUR-PROJECT-ID/sistemppa:1.0.0 .

# Wait for build to complete (5-10 minutes)
# Then verify image pushed:
gcloud container images list --repository=gcr.io/YOUR-PROJECT-ID
```

#### 5A.2: Deploy to Cloud Run
```bash
gcloud run deploy sistemppa \
  --image=gcr.io/YOUR-PROJECT-ID/sistemppa:1.0.0 \
  --platform=managed \
  --region=asia-southeast1 \
  --memory=512Mi \
  --cpu=1 \
  --timeout=900 \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=jdbc:mysql://CLOUD_SQL_IP:3306/sistemppa,DATABASE_USER=root,DATABASE_PASSWORD=<password>"
```

**Or guna Google Cloud Console:**
```
1. Cloud Run → Create Service
2. Container image: gcr.io/YOUR-PROJECT-ID/sistemppa:1.0.0
3. Service name: sistemppa
4. Region: asia-southeast1
5. Memory: 512MB
6. CPU: 1 (sufficient for WAR app)
7. Environment variables:
   - DATABASE_URL=jdbc:mysql://...
   - DATABASE_USER=root
   - DATABASE_PASSWORD=...
8. Klik "DEPLOY"
```

#### 5A.3: Connect Cloud SQL to Cloud Run
```
# Cloud Run service automatically get Cloud SQL proxy!
# Just ensure:
1. Cloud SQL instance has public IP (or use Cloud SQL Connector)
2. Environment variable DATABASE_URL points to Cloud SQL endpoint
3. Service account has Cloud SQL permission
```

---

### OPTION B: App Engine Flexible (Alternative)

#### 5B.1: Create app.yaml
```yaml
# app.yaml (create in project root)
runtime: java21
env: flex

env_variables:
  DATABASE_URL: "jdbc:mysql://CLOUD_SQL_CONNECTION:3306/sistemppa"
  DATABASE_USER: "root"
  DATABASE_PASSWORD: "your-password"

entrypoint: "java -Xmx512m -jar target/sistem-pendaftaran-produk-air-1.0.0.war"

automatic_scaling:
  min_instances: 1
  max_instances: 3
  cool_down_period_sec: 60
  cpu_utilization:
    target_utilization: 0.65

handlers:
  # Redirect HTTP to HTTPS
  - url: /.*
    secure: always
    redirect_http_response_code: 301
    script: auto
```

#### 5B.2: Deploy
```bash
gcloud app deploy app.yaml --region=asia-southeast1
```

---

## 🎯 LANGKAH 6: Setup Custom Domain & HTTPS

### 6.1 Register Domain (if not yet)
```
Domain: sppa.gov
Registrar options:
- Google Domains (if available in your region)
- Namecheap, GoDaddy, Domain.com
- Hostinger

Register sppa.gov and note down nameservers
```

### 6.2 Setup Cloud DNS
```
Google Cloud Console:
1. Cloud DNS → Create Zone
2. Zone name: sistemppa-dns
3. DNS name: sppa.gov
4. DNSSEC: Enable (optional, for security)
5. Klik "CREATE"
```

### 6.3 Update Domain Registrar Nameservers
```
Google Cloud DNS will give you 4 nameservers:
- ns-123.googledomains.com
- ns-456.googledomains.com
- ns-789.googledomains.com
- ns-999.googledomains.com

Di domain registrar (Namecheap, GoDaddy):
1. Go to Nameservers
2. Replace existing with Google Cloud nameservers
3. Save
4. Wait 24 hours for DNS propagation
```

### 6.4 Point Domain to Cloud Run/App Engine
```
Cloud Console:
1. Cloud Run → sistemppa → Manage Custom Domains
2. Or App Engine → Settings → Custom Domains
3. Klik "Add Mapping"
4. Domain: sppa.gov
5. Google will verify DNS ownership (easy - auto-recheck)
6. Google will auto-provision SSL certificate (FREE!)
```

**Or manual DNS record:**
```
In Cloud DNS → A Record:
- Name: sppa.gov
- Type: A
- TTL: 300
- IPv4: <Cloud Run/App Engine IP>
```

### 6.5 HTTPS Auto-Provisioned!
```
✅ Google Cloud auto-provisions HTTPS for:
- https://sistemppa-xxxxx.run.app (Cloud Run URL)
- https://sppa.gov (Custom domain)
- https://www.sppa.gov (if added)

No additional setup needed!
Certificate valid for 13 months, auto-renewed.
```

---

## 🎯 LANGKAH 7: Setup Monitoring & Alerts

### 7.1 Enable Cloud Logging
```
Google Cloud Console:
1. Cloud Logging → Log Sink
2. Create new sink for Cloud Run logs
3. Destination: Cloud Logging
4. Filter: 
   resource.type="cloud_run_revision"
   severity>=ERROR
```

### 7.2 Setup Alerts
```
1. Cloud Monitoring → Alerting Policies
2. Klik "Create Policy"
3. Condition: Cloud Run service error rate > 5%
4. Notification: Email to admin
5. Save
```

### 7.3 View Application Metrics
```
Cloud Monitoring dashboard akan show:
- Request count
- Error rate
- Latency
- Memory usage
- CPU usage
- Startup time
```

---

## 🎯 LANGKAH 8: Database Backups & Recovery

### 8.1 Enable Automated Backups
```
Cloud SQL → sistemppa-db → Backups:
1. Set backup window (e.g., 3 AM UTC)
2. Backup retention: 30 days
3. Automated backups: ON
4. Transaction log retention: 7 days
```

### 8.2 Manual Backup (Pre-demo)
```bash
gcloud sql backups create \
  --instance=sistemppa-db

# Or di Console:
Cloud SQL → sistemppa-db → Backups → Create Backup
```

### 8.3 Restore from Backup (if needed)
```bash
# List backups
gcloud sql backups list --instance=sistemppa-db

# Restore
gcloud sql backups restore BACKUP_ID \
  --backup-instance=sistemppa-db \
  --target-instance=sistemppa-db
```

---

## ✅ VERIFICATION CHECKLIST

Sistem berhasil deploy jika:

- [ ] Cloud SQL instance healthy (sistem monitoring show green)
- [ ] Database schema imported (show database dalam Cloud SQL)
- [ ] Cloud Run/App Engine service running (show "Running" status)
- [ ] Cloud Run URL accessible: `https://sistemppa-xxxxx.run.app`
- [ ] Custom domain resolving: `dig sppa.gov` shows GCP IP
- [ ] HTTPS working: Green padlock di `https://sppa.gov`
- [ ] Application loads (< 3 seconds)
- [ ] Login working (test admin/admin123)
- [ ] Database queries responsive
- [ ] Monitoring showing metrics
- [ ] Backups scheduled & running

---

## 🔧 TROUBLESHOOTING

### ❌ "502 Bad Gateway" atau "Service Unavailable"
```
Cause: Application can't connect to Cloud SQL
Fix:
1. Check Cloud SQL IP address (Cloud Console → SQL → Overview)
2. Verify DATABASE_URL environment variable is correct
3. Ensure Cloud Run service account has Cloud SQL permission:
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member=serviceAccount:SA_NAME@appspot.gserviceaccount.com \
     --role=roles/cloudsql.client
4. Restart service: Cloud Run → Revisions → Deploy new revision
```

### ❌ "Connection Refused"
```
Cause: Cloud Run cannot reach Cloud SQL
Fix:
1. Cloud SQL must have public IP enabled
2. OR use Cloud SQL Proxy socket connection
3. Test connection:
   gcloud cloud-sql-proxy --instances=PROJECT:REGION:INSTANCE
```

### ❌ "Domain not resolving"
```
Cause: DNS not updated
Fix:
1. Wait 24 hours for propagation (dapat kurang dari 1 jam)
2. Verify nameservers:
   nslookup sppa.gov (should show Google Cloud nameservers)
3. Flush local DNS:
   ipconfig /flushdns (Windows)
   sudo dscacheutil -flushcache (Mac)
4. Test with different DNS:
   nslookup sppa.gov 8.8.8.8 (Google DNS)
```

### ❌ "HTTPS Certificate Error"
```
Cause: SSL certificate not yet provisioned
Fix:
1. Google takes 10-30 min to provision cert
2. Check Cloud Run → Custom Domain Mapping
3. Status should show "Verified" and "Active"
4. If still no cert, delete mapping and re-add
```

### ❌ "Cloud Build Failed"
```
Troubleshoot:
1. Cloud Build → Build History
2. Click failed build → View logs
3. Common causes:
   - Maven build failed → Fix pom.xml
   - Docker syntax error → Fix Dockerfile
   - Out of memory → Increase Cloud Build machine type
4. Local test: docker build locally first
```

---

## 💰 Cost Estimation (After Free Credits)

| Service | Monthly Cost | Usageหมายเหตุ |
|---------|-------------|---------|
| Cloud Run | $0.20-1.00 | 1 vCPU, 512MB RAM, ~1000 req/month |
| Cloud SQL | $3.50-7.00 | db-f1-micro (in free tier after credits) |
| Cloud DNS | $0.40 | 4M queries/month  |
| Cloud Load Balancer | $16.00 | If using LB (optional for small app) |
| Cloud Storage (backups) | $0.02-0.20 | SQL backups retention |
| **TOTAL** | **~$5-10/month** | Well within budget! |

---

## 🚀 Scaling & Performance

### Auto-scaling Configuration
```yaml
# app.yaml atau Cloud Run settings:
min_instances: 1      # Always 1 instance running
max_instances: 3      # Scale up to 3 if high load
target_cpu: 65%       # Scale when CPU > 65%
```

### Cloud CDN (untuk static files)
```
Optional - untuk faster asset delivery:
Enable Cloud CDN di Load Balancer
Cache static files (CSS, JS, images) globally
Recommended: Enable for production
```

---

## 🔐 Security Best Practices for GCP

1. **Encrypt Secrets**
   ```bash
   gcloud secrets create db-password --data-file=-
   gcloud run deploy sistemppa --set-env-vars DATABASE_PASSWORD=projects/PROJECT_ID/secrets/db-password/latest/versions/1
   ```

2. **Cloud SQL Auth**
   - Use Cloud SQL Proxy (automatic in Cloud Run)
   - Enable SSL for Cloud SQL connections
   - Restrict access by IP (if needed)

3. **Cloud Armor** (DDoS protection)
   ```
   Cloud Load Balancer → Cloud Armor
   - Block common attacks
   - Rate limiting
   - GeoIP blocking (if needed)
   ```

4. **VPC Service Controls** (optional, for enterprise)
   ```
   Restrict Cloud SQL access to trusted VPC
   ```

---

## 📊 Next Steps After Deploy

1. ✅ Change admin password (admin123 → strong)
2. ✅ Create admin accounts for teampada
3. ✅ Setup email alerts
4. ✅ Test backup/restore procedure
5. ✅ Configure custom metrics/dashboards
6. ✅ Document deployment for team
7. ✅ Plan for scaling (if usage grows)
8. ✅ Market to users: https://sppa.gov

---

## 📚 GCP Documentation Links

- [Cloud Run Docs](https://cloud.google.com/run/docs)
- [Cloud SQL Docs](https://cloud.google.com/sql/docs)
- [Cloud DNS Docs](https://cloud.google.com/dns/docs)
- [Container Registry Docs](https://cloud.google.com/container-registry/docs)
- [Pricing Calculator](https://cloud.google.com/products/calculator)

---

## 💡 Tips & Tricks

1. **Use gcloud CLI** for faster deployment:
   ```bash
   gcloud run deploy sisemppa --source . --region=asia-southeast1
   ```

2. **Setup local development**:
   ```bash
   gcloud auth login
   gcloud config set project PROJECT_ID
   gcloud sql connect sistemppa-db --user=root
   ```

3. **View logs in real-time**:
   ```bash
   gcloud run logs read sistemppa --limit=100 --follow
   ```

4. **SSH into Cloud Run** (debug):
   ```bash
   gcloud run describe sistemppa --format='value(status.url)'
   # Then exec commands via container debugging
   ```

---

**Estimated Timeline**: 45 minutes → Sistem LIVE di https://sppa.gov dengan HTTPS!

**Rekomendasi**: Gunakan **Cloud Run** (simpler) bukan App Engine (lebih complex).

---

**Cost**: ~$10/month after free $300 credits (sufficient for 6 months!)

**Next**: Proceed dengan langkah-langkah di atas, atau tanya jika ada yang unclear.
