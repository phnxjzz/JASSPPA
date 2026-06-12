# ☁️ Cloud Deployment - Pre-Flight Checklist

##  Pre-Deployment (BEFORE going online)

### Code & Configuration
- [x] Database config supports environment variables (DatabaseConfig.java updated)
- [x] No hardcoded credentials in source code
- [x] All sensitive configs use env vars (database URL, passwords, API keys)
- [x] Logging configured for production (SLF4J + proper levels)
- [x] CORS headers configured for production domain
- [x] Error handling doesn't expose sensitive information
- [x] WAR file builds cleanly: `mvn clean package`
- [x] All dependencies updated and vulnerable packages patched
- [x] BCrypt password hashing implemented (org.mindrot.jbcrypt)
- [x] Rate limiting enforced on login endpoint (RateLimitFilter)
- [x] Input validation and sanitization via ValidationUtil
- [x] Excel formula injection prevention in AdminExportServlet
- [x] Email verification token flow implemented (EmailVerificationServlet)
- [x] Audit logging for admin actions
- [x] Email notifications for application status changes
- [x] Announcement image upload with size/format validation (max 10MB)
- [x] User avatar upload with image validation (ProfileServlet + UserAvatarServlet)
- [x] Certificate/Perakuan generation (CertificateServlet)
- [x] Application submission with DB transaction handling
- [ ] Load testing completed (optional but recommended)
- [ ] Security audit completed (optional)

### Database
- [x] MySQL database backed up locally
- [x] Schema file tested and working (database/schema.sql)
- [x] Default admin account credentials secure (will change post-deployment)
- [x] Database connection pool settings optimized
- [ ] Database failover/replica setup (optional for production)
- [ ] Automated backups scheduled

### Testing
- [x] All tests pass locally: `mvn clean test`
- [x] Web form validation working (JavaScript + server-side)
- [x] Login functionality tested with multiple users
- [x] Rate limiting tested (multiple failed logins trigger block)
- [x] Email verification flow tested (register → verify email → login)
- [x] Forgot password flow tested (request → email → reset → login)
- [x] Admin dashboard functionality verified
- [x] Export PDF and Export Excel (.xlsx) verified
- [x] Announcement image upload/display verified
- [x] User avatar upload verified
- [x] Certificate/Perakuan generation and print verified
- [x] Application submission transaction rollback tested
- [x] Mobile responsiveness checked
- [x] Smoke test passes: `ops-scripts\smoke-test.ps1`
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Load testing with 100+ concurrent users (optional)

### Documentation
- [x] README.md updated with deployment info
- [x] DEPLOYMENT_CLOUD.md created (AWS/GCP/Railway comparison)
- [x] DEPLOYMENT_RAILWAY.md created (step-by-step Railway guide)
- [x] PANDUAN_PENGGUNA.md updated (user guide in Malay — all new features)
- [x] LANCARKAN_SISTEM.md created (admin startup guide in Malay)
- [x] .env.example created (env vars template)
- [x] GitHub repo commits pushed
- [ ] API documentation (if REST endpoints exposed)
- [ ] Deployment runbook finalized

### Git & Versioning
- [x] All changes committed to branch `appmod/java-upgrade-20260318013609`
- [x] Latest commit pushed to GitHub
- [x] GitHub repo set to private (for security)
- [ ] Create release tag (v1.0.0-production)
- [ ] Create deployment branch protection rules

---

##  Deployment Steps (IN ORDER)

### Step 1: Choose Cloud Provider
- [ ] Decision: **Railway.app** (Recommended - easiest) OR **AWS** (Production-grade)
- [ ] Register account on chosen platform
- [ ] Verify email & setup billing

### Step 2: Prepare Repository
- [ ] GitHub repo is public or private?
- [ ] GitHub repo has latest commits
- [ ] No sensitive files (.env, passwords) in git history
- [ ] .gitignore properly configured

### Step 3: Setup Cloud Environment

**If Railway.app:**
- [ ] Create Railway project
- [ ] Connect GitHub repo
- [ ] Add MySQL plugin
- [ ] Set environment variables (DATABASE_URL, etc.)
- [ ] Deploy!

**If AWS:**
- [ ] Create EC2 instance (t2.micro)
- [ ] Setup RDS MySQL database
- [ ] Install Java & Tomcat
- [ ] Configure security groups
- [ ] Upload application WAR

**If Google Cloud:**
- [ ] Create App Engine project
- [ ] Setup Cloud SQL MySQL
- [ ] Configure App Engine settings
- [ ] Deploy WAR file

### Step 4: Database Setup
- [ ] Database created on cloud provider
- [ ] Schema imported (database/schema.sql)
- [ ] Test database connection from application
- [ ] Initial data loaded (if any)

### Step 5: Domain & DNS
- [ ] Domain registered (sppa.gov)
- [ ] DNS records configured (CNAME or A record)
- [ ] DNS propagation verified (dig sppa.gov)
- [ ] Subdomain working (www.sppa.gov, mail.sppa.gov, etc.)

### Step 6: HTTPS & SSL
- [ ] SSL certificate obtained (Let's Encrypt or cloud provider)
- [ ] HTTPS working on custom domain
- [ ] HTTP redirects to HTTPS
- [ ] HSTS header configured
- [ ] Security headers added (X-Frame-Options, CSP, etc.)

### Step 7: Launch & Testing
- [ ] Application accessible at https://sppa.gov
- [ ] Login page loads correctly (portal selection visible)
- [ ] Admin login works (admin/admin123 — **change immediately after**)
- [ ] User registration works with email verification
- [ ] Forgot password flow works end-to-end
- [ ] Database queries functional
- [ ] File uploads/downloads working (avatar, announcement images, documents)
- [ ] Admin dashboard loading correctly with statistics
- [ ] Products list displaying
- [ ] Export PDF and Export Excel working
- [ ] Certificate/Perakuan generation working
- [ ] Email notifications working (registration, status changes)
- [ ] Rate limiting active on login (test with repeated failures)
- [ ] Announcement image upload working

### Step 8: Monitoring & Logging
- [ ] Application logs accessible
- [ ] Error logs captured
- [ ] Database logs monitored
- [ ] Alerts configured for failures
- [ ] Performance metrics tracked
- [ ] Uptime monitoring enabled

### Step 9: Security Hardening
- [ ] Firewall rules configured
- [ ] DDoS protection enabled (Cloudflare/WAF)
- [x] Rate limiting configured (RateLimitFilter — built-in)
- [x] Input validation enabled (ValidationUtil — built-in)
- [x] SQL injection protection verified (PreparedStatements throughout)
- [x] XSS protection verified (output escaping in JSPs)
- [x] Password hashing with BCrypt (built-in)
- [x] Excel formula injection prevention (AdminExportServlet)
- [x] File upload type/size validation (built-in)
- [ ] CSRF tokens (verify or add for production)
- [ ] Change default admin credentials post-deployment

### Step 10: Post-Deployment
- [ ] **Change admin password immediately** (admin/admin123 → secure password)
- [ ] Create admin accounts for team members
- [ ] Configure SMTP settings for email notifications and verification
- [ ] Test email verification flow with real email address
- [ ] Announce system to users
- [ ] Monitor logs for errors (`catalina.out` and audit log)
- [ ] Backup schedule verified
- [ ] Support channel established (email/ticketing)

---

##  Rollback Plan

If critical issues occur during deployment:

**Option 1: Railway Redeploy**
```
Railway dashboard → Deployments → Select previous version → Redeploy
```

**Option 2: AWS Revert**
```
1. Stop current EC2 instance
2. Launch new instance with previous AMI/snapshot
3. Update Route 53 to point to new instance
4. Restore database from RDS backup
```

**Option 3: GitHub Branch Revert**
```bash
git reset --hard <previous-commit>
git push origin appmod/java-upgrade-20260318013609 --force
```

---

##  Support & Escalation

If deployment fails:

1. **Check logs first**
   - Railway: Dashboard → Logs tab
   - AWS: CloudWatch logs
   - GCP: Cloud Logging

2. **Common issues & fixes** - See DEPLOYMENT_RAILWAY.md or DEPLOYMENT_CLOUD.md

3. **Contact platform support**
   - Railway Support: support@railway.app
   - AWS Support: https://support.aws.amazon.com
   - GCP Support: https://cloud.google.com/support

4. **Rollback if necessary**
   - Don't panic, use rollback plan above
   - Restore from backup
   - Redeploy with fixes

---

##  Post-Launch Monitoring (First Week)

Monitor these metrics:

- [ ] Application error rate < 1%
- [ ] Average response time < 500ms
- [ ] Database connection pool utilization < 80%
- [ ] Server CPU usage < 50%
- [ ] Server memory usage < 60%
- [ ] No unusual login attempts (check logs)
- [ ] All endpoints responsive (smoke test daily)
- [ ] Backup runs successfully every day
- [ ] User feedback positive (no major complaints)

---

##  Success Criteria

System is successfully deployed if:

1.  Accessible at https://sppa.gov (or your domain)
2.  Login page loads instantly (< 2 sec)
3.  Admin can login and access dashboard
4.  Users can register and submit applications
5.  HTTPS certificate valid (no SSL warnings)
6.  Database performing well (< 100ms queries)
7.  Monitoring & logs working
8.  Backup system operational
9.  No critical errors in logs (24 hours of monitoring)
10.  Team/users can access and use system

** Once all above are green, system is PRODUCTION READY! 🎊**

---

##  Related Documentation

- [README.md](README.md) - Project overview
- [DEPLOYMENT_RAILWAY.md](DEPLOYMENT_RAILWAY.md) - Railway.app step-by-step (15 min)
- [DEPLOYMENT_GCP.md](DEPLOYMENT_GCP.md) - Google Cloud Platform step-by-step (45 min)
- [DEPLOYMENT_CLOUD.md](DEPLOYMENT_CLOUD.md) - Cloud provider comparison & AWS guide
- [PANDUAN_PENGGUNA.md](PANDUAN_PENGGUNA.md) - User guide (Malay)
- [LANCARKAN_SISTEM.md](LANCARKAN_SISTEM.md) - Local startup guide
- [.env.example](.env.example) - Environment variables template
- [Dockerfile](Dockerfile) - Container image for Cloud Run/App Engine

---

**Last Updated:** 2026-03-18  
**Status**: Ready for Production Deployment 
