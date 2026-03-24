# ☁️ Panduan Deployment SPPA ke Cloud (Online)

**Status**: Sistem sudah siap untuk production deployment  
**Domain Target**: sppa.gov  
**Budget**: < $5/bulan  
**Database Backup**:  sistemppa_backup_20260318_132007.sql

---

##  Perbandingan Pilihan Cloud Hosting

| Kriteria | AWS Free Tier | Google Cloud | Railway.app | Heroku |
|----------|---------------|--------------|-------------|--------|
| **Setup Complexity** | Sederhana | Sederhana |  PALING MUDAH | Mudah |
| **Cost** | Gratis 1 tahun | Gratis $300 / 3 bulan |  Gratis + $5/bulan | $7+/bulan |
| **Tomcat Support** |  EC2 |  GCP |  Over Railway | Limited |
| **Database MySQL** |  RDS (gratis tier) |  Cloud SQL |  Gratis tier |  Paid |
| **HTTPS/SSL** |  AWS Certificate Manager |  Gratis |  Otomatis |  Gratis |
| **Custom Domain** |  Route 53 |  Cloud DNS |  |  |
| **Recommended For** | Production, Long-term | Enterprise |  **RECOMMENDED** | Small scale |

---

##  PILIHAN 1: Railway.app (Recommended - Paling Mudah)

### **Kelebihan:**
-  Setup 10 menit (drag-drop GitHub repo)
-  Free tier dengan $5/bulan credits
-  MySQL database included
-  HTTPS otomatis
-  Preview environment per branch
-  Unlimited deployments

### **Langkah-langkah Setup:**

####  Daftar Railway.app
```
1. Pergi ke: https://railway.app
2. Login dengan GitHub
3. New Project → GitHub Repo → Cari "JASSPPA"
4. Railway akan auto-detect Java project (dari pom.xml)
```

####  Setup Environment Variables
Di Railway dashboard → Variables tab, tambah:
```
JAR_ARGS=--server.port=$PORT
DATABASE_URL=postgres://user:pass@host:port/db
JAVA_OPTS=-Xmx512m
```

####  Deploy
```
Railway akan auto-build Maven project → WAR → deploy ke container
Logs: Railway dashboard akan show real-time logs
```

####  Setup Custom Domain
```
Di Railway dashboard:
Settings → Custom Domain
Masukkan: sppa.gov
Konfigurasi DNS sesuai instruksi Railway
```

---

##  PILIHAN 2: AWS Free Tier (Production-Grade)

### **Setup Overview:**
1. **EC2** - Virtual machine untuk Tomcat (gratis 1 tahun)
2. **RDS MySQL** - Managed database (gratis micro tier)
3. **Route 53** - DNS management
4. **Certificate Manager** - HTTPS SSL/TLS gratis

### **Langkah-langkah Setup:**

####  Buat AWS Account
```
Pergi ke: https://aws.amazon.com/free
Daftar dengan email
Verify dengan credit card (gratis 1 tahun, tidak ada charge)
```

####  Launch EC2 Instance
```powershell
# Di AWS Console:
1. Services → EC2
2. Launch Instance
3. Pilih: Amazon Linux 2 (gratis tier eligible)
4. Instance Type: t2.micro (gratis)
5. Storage: 30GB EBS (gratis)
6. Security Group:
   - Port 22 (SSH) - your IP
   - Port 80 (HTTP) - 0.0.0.0/0
   - Port 443 (HTTPS) - 0.0.0.0/0
   - Port 8081 (Tomcat, optional) - 0.0.0.0/0
7. Key Pair: Download .pem file (untuk SSH)
8. Launch!
```

####  SSH ke EC2 Instance
```powershell
# Windows PowerShell (gunakan WSL atau PuTTY):
ssh -i "path/to/your-key.pem" ec2-user@your-ec2-public-ip

# Di server, install dependencies:
sudo yum update -y
sudo yum install java-21-amazon-corretto -y
sudo yum install mysql -y
```

####  Deploy Aplikasi
```bash
# Clone repo or upload WAR file
cd /opt
wget https://github.com/phnxjzz/JASSPPA/releases/download/v1.0.0/sistemppa.war

# Atau upload via SCP:
# scp -i key.pem sistemppa.war ec2-user@ip:/tmp/

# Install Tomcat
wget https://archive.apache.org/dist/tomcat/tomcat-11/v11.0.18/bin/apache-tomcat-11.0.18.tar.gz
tar -xzf apache-tomcat-11.0.18.tar.gz
sudo mv apache-tomcat-11.0.18 /opt/tomcat

# Copy WAR ke Tomcat
cp sistemppa.war /opt/tomcat/webapps/

# Start Tomcat
/opt/tomcat/bin/startup.sh
```

####  Setup RDS MySQL
```
AWS Console → RDS → Create Database
- Engine: MySQL 8.0
- Template: Free tier
- DB Instance: db.t3.micro (gratis)
- Database Name: sistemppa
- Master username: admin
- Password: (strong password)
- Public access: No (soal keselamatan, gunakan VPC)
```

####  Update Database Config
```java
// src/main/java/com/sistemppa/config/DatabaseConfig.java
config.setJdbcUrl("jdbc:mysql://your-rds-endpoint:3306/sistemppa");
config.setUsername("admin");
config.setPassword("your-rds-password");
```

####  Setup HTTPS dengan Let's Encrypt
```bash
# Install Certbot
sudo yum install certbot python3-certbot-apache -y

# Generate certificate (pastikan domain sudah point ke EC2 IP)
sudo certbot certonly --standalone -d sppa.gov

# Tomcat + HTTPS setup (install mod_proxy)
# Atau update Tomcat server.xml dengan SSL connector
```

####  Setup DNS (Route 53)
```
1. AWS Console → Route 53
2. Create Hosted Zone: sppa.gov
3. Create Record Set:
   - Type: A
   - Value: EC2 Public IP
   - TTL: 300
4. Update domain registrar nameservers ke Route 53 nameservers
```

---

##  PILIHAN 3: Google Cloud (Enterprise)

Mirip AWS, tapi dengan $300 free credit untuk 3 bulan.

**Langkah singkat:**
```
1. Daftar: https://cloud.google.com/free
2. Create Project
3. App Engine → Deploy WAR
4. Cloud SQL → MySQL database
5. Cloud Load Balancing → HTTPS
6. Cloud DNS → Custom domain
```

---

##  Pre-Deployment Checklist

- [ ] Database backup sudah tersimpan  (sistemppa_backup_20260318_132007.sql)
- [ ] Hardcoded credentials sudah move ke environment variables
- [ ] CORS settings sudah dikonfigurasi untuk production
- [ ] Logging sudah di-setup (CloudWatch / Stackdriver)
- [ ] Database connection pool settings optimal
- [ ] Security headers sudah set (X-Frame-Options, CSP, dll)

### **Update DatabaseConfig.java untuk Cloud:**

```java
public class DatabaseConfig {
    private static HikariDataSource dataSource;
    
    public static DataSource getDataSource() {
        if (dataSource == null) {
            HikariConfig config = new HikariConfig();
            
            // Baca dari environment variables (BUKAN hardcoded)
            String dbUrl = System.getenv("DATABASE_URL");
            String dbUser = System.getenv("DATABASE_USER");
            String dbPass = System.getenv("DATABASE_PASSWORD");
            
            // Fallback ke default jika development
            if (dbUrl == null) {
                dbUrl = "jdbc:mysql://localhost:3306/sistemppa";
                dbUser = "root";
                dbPass = "root";
            }
            
            config.setJdbcUrl(dbUrl);
            config.setUsername(dbUser);
            config.setPassword(dbPass);
            config.setMaximumPoolSize(10);
            config.setMinimumIdle(2);
            config.setConnectionTimeout(30000);
            config.setIdleTimeout(600000);
            
            dataSource = new HikariDataSource(config);
        }
        return dataSource;
    }
}
```

---

##  Deployment Timeline

| Langkah | Waktu | Kesuksesan |
|---------|-------|-----------|
| Daftar Railway / AWS | 5 menit | 99% |
| Connect GitHub repo | 2 menit | 99% |
| Setup database | 10 menit | 90% |
| Auto-build + deploy | 5-10 menit | 85% |
| Configure custom domain | 10-30 menit | 95% |
| Setup HTTPS | 5 menit (auto) | 99% |
| **TOTAL** | **40-65 menit** | ** SIAP ONLINE** |

---

##  Seterusnya Selepas Deploy Online

1. **Luncurkan bersiraji:**
   - Beri akses kepada pengguna: `https://sppa.gov/login`
   - Admin login: `admin / admin123` (tukar immediately in production!)

2. **Monitoring:**
   - Setup alerts untuk deployment failures
   - Monitor database performance
   - Track user logins & errors via logs

3. **Backup & Recovery:**
   - Setup automatic daily database backups (AWS Backup / Google Cloud)
   - Test restore procedure sebulan sekali

4. **Performance Optimization:**
   - Enable caching (Redis, Memcached)
   - Setup CDN untuk static assets (CloudFront, Cloudflare)
   - Monitor& scale jika traffic tinggi

5. **Security Hardening:**
   - Setup WAF (Web Application Firewall)
   - DDoS protection (AWS Shield, Cloudflare)
   - Regular security audits
   - Update dependencies regularly

---

##  Help & Support

**Jika ada masalah:**
1. Railway Dashboard → Deployment Logs
2. AWS Console → CloudWatch Logs
3. Email: devops@sistemppa.gov

**Komunikasi dengan DevOps team:**
- Jangan hardcode sensitive info
- Use environment variables
- Document setiap deployment
- Keep change log updated

---

**Rekomendasi Final:**  **Mulai dengan Railway.app** — easiest, fastest, gratis tier cukup untuk testing. Lepas stable, baru migrate ke AWS untuk production.
