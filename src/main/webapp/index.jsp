<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Collections" %>
<%@ page import="com.sistemppa.config.DatabaseConfig" %>
<%@ page import="com.sistemppa.service.DashboardDataService" %>
<%@ page import="java.sql.Connection" %>
<%!
    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String buildImageSrc(String contextPath, Object imageUrlValue) {
        if (imageUrlValue == null) {
            return "";
        }

        String raw = String.valueOf(imageUrlValue).trim().replace('\\', '/');
        if (raw.isEmpty()) {
            return "";
        }

        int assetsIndex = raw.indexOf("/assets/");
        if (assetsIndex > 0) {
            raw = raw.substring(assetsIndex);
        } else {
            int assetsRelativeIndex = raw.indexOf("assets/");
            if (assetsRelativeIndex > 0) {
                raw = "/" + raw.substring(assetsRelativeIndex);
            }
        }

        while (raw.contains("//") && !raw.startsWith("//")) {
            raw = raw.replace("//", "/");
        }

        int managedAnnouncementIndex = raw.indexOf("/announcement-images/");
        if (managedAnnouncementIndex >= 0) {
            raw = raw.substring(managedAnnouncementIndex);
        }

        int uploadManagedIndex = raw.toLowerCase(java.util.Locale.ROOT).indexOf("/uploads/sistemppa/announcements/");
        if (uploadManagedIndex >= 0) {
            String fileName = raw.substring(uploadManagedIndex + "/uploads/sistemppa/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                raw = "/announcement-images/" + fileName;
            }
        }

        int uploadRelativeIndex = raw.toLowerCase(java.util.Locale.ROOT).indexOf("uploads/sistemppa/announcements/");
        if (uploadRelativeIndex >= 0) {
            String fileName = raw.substring(uploadRelativeIndex + "uploads/sistemppa/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                raw = "/announcement-images/" + fileName;
            }
        }

        int legacyAnnouncementIndex = raw.indexOf("/assets/images/announcements/");
        if (legacyAnnouncementIndex >= 0) {
            String fileName = raw.substring(legacyAnnouncementIndex + "/assets/images/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                raw = "/announcement-images/" + fileName;
            }
        }

        String lower = raw.toLowerCase(java.util.Locale.ROOT);
        if (lower.startsWith("http://") || lower.startsWith("https://") || lower.startsWith("data:") || raw.startsWith("//")) {
            return raw;
        }

        String safeContextPath = contextPath == null ? "" : contextPath.trim();
        if (safeContextPath.isEmpty() || "/".equals(safeContextPath)) {
            safeContextPath = "";
        }

        if (raw.startsWith("/")) {
            if (!safeContextPath.isEmpty() && raw.startsWith(safeContextPath + "/")) {
                return raw;
            }
            return safeContextPath + raw;
        }

        return safeContextPath + "/" + raw;
    }
%>
<%
    List<Map<String, Object>> homepageAnnouncements = Collections.emptyList();
    try (Connection conn = DatabaseConfig.getConnection()) {
        homepageAnnouncements = DashboardDataService.loadActiveAnnouncements(conn, 5);
    } catch (Exception ignored) {
        homepageAnnouncements = Collections.emptyList();
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistem Pendaftaran Produk Air (SPPA)</title>
    <meta name="description" content="Portal rasmi SPPA Jabatan Air Negeri Sabah untuk pendaftaran produk air, pengumuman, dan semakan status permohonan.">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');

        :root {
            --brand-blue: #0d5c8f;
            --brand-navy: #08334d;
            --brand-sky: #edf4fb;
            --brand-gold: #e7bf56;
            --surface: #ffffff;
            --surface-soft: #f3f8fc;
            --text: #1a3040;
            --muted: #5d7484;
            --ring: rgba(13, 92, 143, 0.22);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif;
            line-height: 1.6;
            color: var(--text);
            background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%);
            min-height: 100vh;
        }

        .navbar {
            position: sticky;
            top: 0;
            z-index: 30;
            background: linear-gradient(180deg, var(--brand-navy) 0%, #0c4569 100%);
            color: white;
            padding: 14px 26px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid var(--brand-gold);
            box-shadow: 0 12px 28px rgba(8, 51, 77, 0.2);
        }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logos { display: flex; align-items: center; gap: 10px; }
        .brand-logo { width: 48px; height: 48px; object-fit: contain; }
        .brand-text strong { display: block; font-size: 18px; line-height: 1.1; }
        .brand-text span { font-size: 12px; opacity: 0.88; }

        .nav-actions { display: flex; gap: 10px; }
        .nav-link {
            color: #ffffff;
            text-decoration: none;
            font-weight: 700;
            padding: 9px 13px;
            border-radius: 8px;
            border: 1px solid rgba(255,255,255,0.2);
            transition: 0.2s ease;
        }
        .nav-link:hover, .nav-link:focus { background: rgba(255, 255, 255, 0.12); }
        .nav-link.primary {
            background: linear-gradient(135deg, #2ba5e0 0%, #0a8ecf 100%);
            border-color: rgba(255,255,255,0.35);
            color: #ffffff;
        }

        .hero {
            position: relative;
            overflow: hidden;
            background: linear-gradient(128deg, #05283e 0%, #0a8ecf 63%, #ffd857 180%);
            color: white;
            padding: 72px 28px;
            border-bottom-left-radius: 28px;
            border-bottom-right-radius: 28px;
            box-shadow: 0 16px 42px rgba(6, 47, 72, 0.22);
        }
        .hero::after {
            content: "";
            position: absolute;
            right: -70px;
            top: -80px;
            width: 300px;
            height: 300px;
            border-radius: 50%;
            background: rgba(255, 216, 87, 0.25);
        }
        .hero-watermark {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            object-fit: contain;
            object-position: center;
            opacity: 0.09;
            pointer-events: none;
            z-index: 0;
            padding: 44px;
        }
        .hero-inner {
            max-width: 1020px;
            margin: 0 auto;
            position: relative;
            z-index: 1;
        }
        .hero h1 {
            font-size: clamp(30px, 4vw, 52px);
            line-height: 1.14;
            margin-bottom: 14px;
            max-width: 760px;
            letter-spacing: -0.02em;
            animation: riseIn .55s ease-out;
        }
        .hero p { font-size: 17px; margin-bottom: 20px; max-width: 720px; color: rgba(255,255,255,0.95); animation: riseIn .72s ease-out; }
        .hero-badges { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 16px; }
        .hero-badge {
            display: inline-flex;
            align-items: center;
            padding: 8px 12px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            border: 1px solid rgba(255,255,255,0.38);
            background: rgba(255,255,255,0.12);
        }
        .hero-actions { display: flex; flex-wrap: wrap; gap: 12px; }
        .hero-btn {
            display: inline-block;
            padding: 12px 24px;
            color: #fff;
            text-decoration: none;
            border-radius: 999px;
            font-weight: 800;
            border: 1px solid rgba(255,255,255,0.55);
            background: rgba(255, 255, 255, 0.1);
            transition: transform 0.18s ease, background-color 0.2s ease;
            box-shadow: 0 12px 22px rgba(6, 47, 72, 0.2);
        }
        .hero-btn:hover, .hero-btn:focus { transform: translateY(-1px); background: rgba(255, 255, 255, 0.22); }
        .hero-btn.accent { background: #ffffff; color: #0a5f8b; border-color: #ffffff; }
        .hero-btn.accent:hover, .hero-btn.accent:focus { background: #f0f9ff; }

        .container { max-width: 1200px; margin: 0 auto; padding: 42px 20px 56px; }

        .quick-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 26px;
        }
        .quick-card {
            background: var(--surface);
            border: 1px solid #dbeaf4;
            border-radius: 18px;
            padding: 16px;
            box-shadow: 0 10px 24px rgba(6, 47, 72, 0.07);
        }
        .quick-card h4 { margin-bottom: 6px; font-size: 16px; color: var(--brand-navy); }
        .quick-card p { margin: 0; color: var(--muted); font-size: 14px; }

        .section-title { margin-bottom: 10px; font-size: 24px; letter-spacing: -0.01em; }
        .section-subtitle { margin-bottom: 16px; color: var(--muted); }

        .announcement-section {
            margin-bottom: 24px;
            border: 1px solid #d9e7f1;
            border-radius: 20px;
            background: var(--surface);
            box-shadow: 0 14px 30px rgba(6, 47, 72, 0.08);
            overflow: hidden;
        }
        .announcement-header {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 16px 18px;
            background: linear-gradient(135deg, #f5fbff 0%, #e8f4fb 100%);
            border-bottom: 1px solid #d9e7f1;
        }
        .icon-badge {
            width: 24px;
            height: 24px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: var(--brand-blue);
        }
        .icon-badge svg {
            width: 22px;
            height: 22px;
            display: block;
        }
        .icon-badge img {
            width: 22px;
            height: 22px;
            display: block;
            object-fit: contain;
        }
        .announcement-header h3 { margin: 0; font-size: 16px; color: var(--brand-navy); }
        .announcement-list { padding: 0 18px 10px; }
        .announcement-item { padding: 14px 0; border-bottom: 1px dashed #dce9f2; }
        .announcement-item:last-child { border-bottom: 0; }
        .announcement-item h4 { margin: 0 0 6px; font-size: 17px; color: var(--brand-navy); }
        .announcement-item img { width: 100%; max-width: 360px; height: auto; border: 1px solid #dce8f2; border-radius: 10px; margin: 6px 0 8px; }
        .announcement-item p { margin: 0; color: var(--text); white-space: pre-wrap; }
        .announcement-empty { padding: 14px 0; color: var(--muted); }

        .hero-contact {
            width: 100%;
            border-radius: 18px;
            border: 1px solid #d7e8f3;
            background: var(--surface);
            padding: 16px;
            box-shadow: 0 8px 24px rgba(6, 47, 72, 0.07);
        }
        .hero-contact h3 { margin: 0 0 10px; font-size: 16px; color: var(--brand-navy); }
        .hero-contact p { margin: 6px 0; font-size: 14px; color: #27485a; }

        footer {
            background: #072d43;
            color: white;
            text-align: center;
            padding: 30px;
            border-top-left-radius: 20px;
            border-top-right-radius: 20px;
        }
        footer .footer-links {
            margin-top: 8px;
            font-size: 13px;
            color: rgba(255,255,255,0.85);
        }
        footer .footer-links a {
            color: #d3efff;
            text-decoration: none;
            margin: 0 8px;
        }

        .floating-home-btn {
            position: static;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            margin-left: 12px;
            border-radius: 999px;
            border: 1px solid #fff;
            background: rgba(255, 255, 255, 0.12);
            text-decoration: none;
            vertical-align: middle;
        }
        .floating-home-btn img {
            width: 16px;
            height: 16px;
            object-fit: contain;
        }
        .floating-home-btn svg {
            width: 16px;
            height: 16px;
            display: block;
            color: #ffffff;
        }

        @keyframes riseIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @media (max-width: 980px) {
            .quick-grid { grid-template-columns: 1fr; }
            .navbar { flex-direction: column; align-items: flex-start; gap: 12px; }
            .nav-actions { width: 100%; }
            .nav-link { flex: 1; text-align: center; }
        }
        </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <div class="brand-logos">
                <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
                <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            </div>
            <div class="brand-text">
                <strong>SPPA</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div class="nav-actions">
            <a class="nav-link" href="${pageContext.request.contextPath}/login">Log Masuk</a>
            <a class="nav-link primary" href="${pageContext.request.contextPath}/register">Daftar Pemohon</a>
        </div>
    </div>

    <div class="hero">
        <img src="${pageContext.request.contextPath}/assets/images/Logo JAS.png" class="hero-watermark" alt="" aria-hidden="true">
        <div class="hero-inner">
            <div>
                <div class="hero-badges">
                    <span class="hero-badge">Portal Rasmi SPPA</span>
                    <span class="hero-badge">Mesra Pengguna</span>
                    <span class="hero-badge">Akses Dalam Talian 24/7</span>
                </div>
                <h1>Selamat Datang ke Sistem Pendaftaran Produk Air Negeri Sabah</h1>
                <div class="hero-actions">
                    <a href="${pageContext.request.contextPath}/register" class="hero-btn accent">Daftar Akaun Pemohon</a>
                    <a href="${pageContext.request.contextPath}/login" class="hero-btn">Log Masuk Ke Sistem</a>
                </div>
            </div>
        </div>
    </div>

        <div class="announcement-section" aria-label="Pengumuman dan info semasa">
            <div class="announcement-header">
                <span class="icon-badge" aria-hidden="true">
                    <img src="${pageContext.request.contextPath}/assets/images/icon-announcement.png" alt="Ikon pengumuman">
                </span>
                <h3>Pengumuman / Info Terkini</h3>
            </div>
            <div class="announcement-list">
                <% if (homepageAnnouncements == null || homepageAnnouncements.isEmpty()) { %>
                    <div class="announcement-empty">Tiada pengumuman buat masa ini.</div>
                <% } else {
                    for (Map<String, Object> ann : homepageAnnouncements) {
                        String announcementImageSrc = buildImageSrc(request.getContextPath(), ann.get("image_url"));
                %>
                    <div class="announcement-item">
                        <h4><%= escapeHtml(String.valueOf(ann.get("title"))) %></h4>
                        <% if (!announcementImageSrc.isBlank()) { %>
                            <img src="<%= escapeHtml(announcementImageSrc) %>" alt="Gambar pengumuman" onerror="this.style.display='none';">
                        <% } %>
                        <p><%= escapeHtml(String.valueOf(ann.get("content"))) %></p>
                    </div>
                <%  }
                } %>
            </div>
        </div>

        <div class="hero-contact" aria-label="Maklumat hubungan Jabatan Air Sabah">
            <h3>
                <span class="icon-badge" aria-hidden="true" style="vertical-align:middle; margin-right:6px;">
                    <img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Ikon hubungi">
                </span>
                Hubungi JANS
            </h3>
            <p>SABAH WATER DEPARTMENT</p>
            <p>Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</p>
            <p>Kota Kinabalu, Sabah, Malaysia</p>
            <p>Tel: +60-88-232364 (HQ), Fax: +60-88-232396</p>
            <p>Email: jans.hq@sabah.gov.my</p>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Sistem Pendaftaran Produk Air (SPPA). Semua hak terpelihara.</p>
        <p>Jabatan Air Negeri Sabah</p>
        <p class="footer-links">
            <a href="${pageContext.request.contextPath}/privacy-policy">Dasar Privasi</a>
            |
            <a href="${pageContext.request.contextPath}/terms">Terma Penggunaan</a>
        </p>
    </footer>
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama">
        <img src="${pageContext.request.contextPath}/assets/images/icon-home.png" alt="Laman utama" style="width:18px;height:18px;object-fit:contain;">
    </a>
<script>
(function() {
    var homeBtn = document.querySelector('.floating-home-btn');
    if (!homeBtn) return;

    var navContainer = document.querySelector('.navbar > div:last-child');
    if (!navContainer) navContainer = document.querySelector('.navbar');
    if (!navContainer) return;

    if (homeBtn.parentElement !== navContainer) {
        navContainer.appendChild(homeBtn);
    }
})();
</script>
</body>
</html>
