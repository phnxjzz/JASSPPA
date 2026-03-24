#  Railway.app - Quick Deployment Guide (15 menit)

##  Estimated Time: 15 minutes
##  Cost: Gratis + $5/bulan (Free tier)

---

##  LANGKAH 1: Daftar Railway.app (2 menit)

1. Pergi ke: **https://railway.app**
2. Klik **"Login"** → Login dengan **GitHub**
3. Authorize Railway untuk akses GitHub repos
4. Accept terms and setup complete 

---

##  LANGKAH 2: Create New Project (1 menit)

Di Railway dashboard:
1. Klik **"New Project"**
2. Pilih **"Deploy from GitHub"**
3. Cari **"phnxjzz/JASSPPA"** repository
4. Klik **"Select Repository"**
5. **DEPLOY** button akan muncul di main branch (`appmod/java-upgrade-20260318013609`)

---

##  LANGKAH 3: Railway Auto-Detect & Build (5-8 menit)

Rails will automatically detect:

```
✓ Java Maven project (detected dari pom.xml)
✓ Build command: mvn clean package
✓ Generates: target/sistem-pendaftaran-produk-air-1.0.0.war
✓ Starts: java -jar (WAR runs as embedded Tomcat)
```

**Dashboard akan show:**
```
Building... 🔨
✓ Build completed in 3-5 min
✓ Deploying...
✓ Service running on https://sistemppa-xxxxx.up.railway.app
```

---

##  LANGKAH 4: Setup Environment Variables (2 menit)

Aplikasi perlu 3 environment variables untuk production MySQL:

**Di Railway Dashboard:**
1. Klik **project name** → **Variables**
2. Tambah 3 variables baru:

```
DATABASE_URL    = jdbc:mysql://mysql-container:3306/sistemppa
DATABASE_USER   = root
DATABASE_PASSWORD = your_mysql_root_password
```

**Atau jika gunakan Railway MySQL Plugin:**
Railway akan auto-provide sebagai:
```
DATABASE_PUBLIC_URL (sudah include username:password@host)
```

---

##  LANGKAH 5: Add MySQL Database (2 menit)

**Option A: Railway MySQL Plugin (Recommended)**

1. Di Railway project → **Add** button (+)
2. Cari **"MySQL"** dari plugin list
3. Railway setup ✓:
   - Automatic database initialization
   - Password dijana oleh platform
   - Environment variable: `DATABASE_PUBLIC_URL`

**Option B: External MySQL (Cloud)**
Jika sudah punya MySQL cloud (AWS RDS, Google Cloud SQL):
1. Set variables:
   ```
   DATABASE_URL = jdbc:mysql://your-rds-endpoint:3306/sistemppa
   DATABASE_USER = admin
   DATABASE_PASSWORD = your_password
   ```

---

##  LANGKAH 6: Deploy Database Schema (2 menit)

**Option 1: Railway CLI**
```bash
# Login
railway login

# Connect ke Railway MySQL
railway run mysql -u root -p < database/schema.sql
```

**Option 2: Manual SSH**
```bash
# SSH ke Railway container
railway shell

# Run SQL import
mysql -u root -p sistemppa < /app/database/schema.sql
```

**Option 3: Web-based (Easiest)**
Railway dashboard → MySQL panel → SQL Editor → Paste schema.sql content

---

##  LANGKAH 7: Custom Domain Setup (2 menit)

**Di Railway Dashboard:**

1. Klik **Project** → **Settings**
2. Scroll to **"Custom Domain"**
3. Masukkan: **sppa.gov**
4. Railway show CNAME record:
   ```
   CNAME: sistemppa.railway.internal.up.railway.app
   ```

**Update DNS (Di domain registrar):**
1. Pergi ke registrar (Namecheap, GoDaddy, dll)
2. DNS Settings → Add CNAME Record:
   ```
   Name: @ (or leave blank for root)
   Type: CNAME
   Value: sistemppa.railway.internal.up.railway.app
   ```
3. Wait 5-10 minutes untuk DNS propagate

**Test Domain:**
```powershell
ping sppa.gov
# Should resolve ke Railway IP
```

---

##  LANGKAH 8: HTTPS (Automatic!)

Railway automatically provides HTTPS for:
- `https://sistemppa-xxxxx.up.railway.app` (Railway subdomain)
- `https://sppa.gov` (Custom domain) - HTTPS auto-enable

**No additional setup needed!** 

---

##  VERIFICATION CHECKLIST

Aplikasi sudah online jika:

- [ ] Dashboard show "Service running"
- [ ] Akses `https://sistemppa-xxxxx.up.railway.app` → Dapat login page
- [ ] Database sudah initialize (test login dengan admin/admin123)
- [ ] Custom domain `https://sppa.gov` → Resolve correctly
- [ ] HTTPS certificate valid (green padlock in browser)
- [ ] MySQL connection testing:
  ```bash
  # In Railway shell:
  # mysql -u root -p
  # use sistemppa;
  # show tables;
  ```

---

##  TROUBLESHOOTING

###  "502 Bad Gateway"
- **Cause**: Database connection failed
- **Fix**: 
  ```
  1. Check DATABASE_URL variable syntax
  2. Ensure MySQL container is running
  3. Check app logs: Railway → Logs tab
  4. Restart service: Railway → Redeploy
  ```

###  "Connection refused"
- **Cause**: Tomcat port misconfigured
- **Fix**:
  ```
  Railway automatically uses PORT env var
  Check: echo $PORT in Railway shell
  Should be 3000 or 8080
  ```

###  "Custom domain not resolving"
- **Cause**: DNS not updated yet
- **Fix**:
  ```
  1. Verify CNAME in registrar DNS
  2. Wait 24 hours for propagation
  3. Test: nslookup sppa.gov
  4. Flush DNS: ipconfig /flushdns (Windows)
  ```

###  "Database schema import failed"
- **Cause**: SQL syntax error or table exists
- **Fix**:
  ```
  1. Edit schema.sql: Add DROP TABLE IF EXISTS
  2. Or: Clear database in Railway, re-import
  3. Or: Use Railway SQL Editor for manual setup
  ```

---

##  Monitoring & Logs

**Di Railway Dashboard:**

1. **Deployments** tab
   - Show deployment history
   - Rollback jika needed
   - View logs dari setiap deployment

2. **Logs** tab
   - Real-time application logs
   - Database connection logs
   - Error messages

3. **Metrics** tab
   - CPU, Memory usage
   - Request count
   - Response time

---

##  Billing & Optimization

**Railway Pricing Model:**
- **Free Tier**: $5/month Credits
- **After**: Pay-as-you-go (usually $1-5/month per service)

**To reduce costs:**
1. Scale down services during off-peak
2. Use Railway's free tier for dev/test
3. Only scale Tomcat memory if needed (default 1GB OK)
4. Use Railway MySQL (cheaper than external)

---

##  Post-Deployment Security

Selepas sistem online:

1. **Change Default Admin Password**
   - Login: `https://sppa.gov/login`
   - Username: `admin`
   - Password: `admin123` → CHANGE IMMEDIATELY
   - Go to Profile → Update Password

2. **Enable 2FA** (future enhancement)
   - Add TOTP/email verification

3. **Setup Monitoring**
   - Railway Alerts for deployment failures
   - Email notifications for errors

4. **Regular Backups**
   - Enable Railway automated backups
   - Download monthly backup to safe location

---

##  Next Steps

1.  Login to Railway.app
2.  Deploy from GitHub
3.  Setup MySQL
4.  Add custom domain
5.  Test aplikasi online
6.  **Announce to users**: `https://sppa.gov/login`

**Estimated Total Time**: 15-20 menit dari sekarang sistem sudah online!

---

**Documentation**: See [DEPLOYMENT_CLOUD.md](DEPLOYMENT_CLOUD.md) for AWS/GCP alternatives  
**Support**: [Railway.app Docs](https://docs.railway.app)
