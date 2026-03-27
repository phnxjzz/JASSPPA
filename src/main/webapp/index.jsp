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
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

        :root {
            --brand-blue: #0a8ecf;
            --brand-navy: #062f48;
            --brand-sky: #dff4ff;
            --brand-gold: #ffd857;
            --surface: #ffffff;
            --surface-soft: #f3f9fd;
            --text: #143042;
            --muted: #5f788a;
            --ring: rgba(10, 142, 207, 0.22);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Plus Jakarta Sans', 'Segoe UI', Tahoma, sans-serif;
            line-height: 1.6;
            color: var(--text);
            background:
                radial-gradient(640px 320px at 105% -20%, rgba(255, 216, 87, 0.55), transparent 60%),
                radial-gradient(600px 280px at -10% 10%, rgba(10, 142, 207, 0.2), transparent 60%),
                linear-gradient(180deg, #f9fdff 0%, #f1f8fc 100%);
            min-height: 100vh;
        }

        .navbar {
            position: sticky;
            top: 0;
            z-index: 30;
            background: rgba(6, 47, 72, 0.9);
            backdrop-filter: blur(10px);
            color: white;
            padding: 14px 28px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(255, 255, 255, 0.16);
        }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logos { display: flex; align-items: center; gap: 10px; }
        .brand-logo { width: 48px; height: 48px; border-radius: 14px; object-fit: contain; padding: 3px; background: rgba(255,255,255,0.07); }
        .brand-text strong { display: block; font-size: 18px; line-height: 1.1; }
        .brand-text span { font-size: 12px; opacity: 0.88; }

        .nav-actions { display: flex; gap: 10px; }
        .nav-link {
            color: #eaf7ff;
            text-decoration: none;
            font-weight: 600;
            padding: 10px 14px;
            border-radius: 999px;
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
            max-width: 1200px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: 1.45fr 1fr;
            gap: 24px;
            align-items: center;
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

        .hero-side {
            background: rgba(255,255,255,0.17);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255,255,255,0.33);
            border-radius: 20px;
            padding: 18px;
            animation: riseIn .82s ease-out;
        }
        .hero-side h3 { font-size: 17px; margin-bottom: 10px; }
        .hero-side ul { list-style: none; }
        .hero-side li {
            padding: 8px 10px;
            margin-bottom: 8px;
            border-radius: 10px;
            background: rgba(6, 47, 72, 0.28);
            font-size: 14px;
        }

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
        .announcement-header img { width: 22px; height: 22px; object-fit: contain; }
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

        @keyframes riseIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @media (max-width: 980px) {
            .hero-inner { grid-template-columns: 1fr; }
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
                <img src="${pageContext.request.contextPath}/assets/images/logo-sabah-2025.png?v=3" class="brand-logo" alt="Logo Sabah">
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
        <img src="${pageContext.request.contextPath}/assets/images/jabatan-air-sabah-bg.png" class="hero-watermark" alt="" aria-hidden="true">
        <div class="hero-inner">
            <div>
                <div class="hero-badges">
                    <span class="hero-badge">Portal Rasmi SPPA</span>
                    <span class="hero-badge">Mesra Pengguna</span>
                    <span class="hero-badge">Akses Dalam Talian 24/7</span>
                </div>
                <h1>Selamat Datang ke Sistem Pendaftaran Produk Air Negeri Sabah</h1>
                <p>Urus permohonan produk air dengan lebih tersusun, pantas, dan telus melalui platform digital rasmi Jabatan Air Negeri Sabah.</p>
                <div class="hero-actions">
                    <a href="${pageContext.request.contextPath}/register" class="hero-btn accent">Daftar Akaun Pemohon</a>
                    <a href="${pageContext.request.contextPath}/login" class="hero-btn">Log Masuk Ke Sistem</a>
                </div>
            </div>
            <div class="hero-side" aria-label="Kelebihan portal SPPA">
                <h3>Kenapa Guna SPPA?</h3>
                <ul>
                    <li>Pendaftaran dan semakan permohonan di satu tempat.</li>
                    <li>Maklumat pengumuman rasmi dipaparkan secara terkini.</li>
                    <li>Reka bentuk responsif untuk desktop dan telefon.</li>
                </ul>
            </div>
        </div>
    </div>

    <div class="container">
        <h2 class="section-title">Kemudahan Utama Portal</h2>
        <p class="section-subtitle">Direka untuk memastikan urusan pemohon lebih lancar dari awal hingga keputusan semakan.</p>

        <div class="quick-grid" aria-label="Kemudahan utama sistem">
            <article class="quick-card">
                <h4>Pendaftaran Akaun Selamat</h4>
                <p>Cipta akaun pemohon dengan pengesahan maklumat asas secara mudah.</p>
            </article>
            <article class="quick-card">
                <h4>Semakan Status Permohonan</h4>
                <p>Pantau kemajuan semakan pentadbir tanpa perlu hadir ke kaunter.</p>
            </article>
            <article class="quick-card">
                <h4>Pengumuman Rasmi Terkini</h4>
                <p>Dapatkan notis penting, hebahan teknikal, dan makluman semasa dari jabatan.</p>
            </article>
        </div>

        <div class="announcement-section" aria-label="Pengumuman dan info semasa">
            <div class="announcement-header">
                <img src="${pageContext.request.contextPath}/assets/images/icon-announcement.png" alt="Pengumuman">
                <h3>Pengumuman / Info Terkini</h3>
            </div>
            <div class="announcement-list">
                <% if (homepageAnnouncements == null || homepageAnnouncements.isEmpty()) { %>
                    <div class="announcement-empty">Tiada pengumuman buat masa ini.</div>
                <% } else {
                    for (Map<String, Object> ann : homepageAnnouncements) {
                %>
                    <div class="announcement-item">
                        <h4><%= escapeHtml(String.valueOf(ann.get("title"))) %></h4>
                        <% if (ann.get("image_url") != null && !String.valueOf(ann.get("image_url")).isBlank()) { %>
                            <img src="${pageContext.request.contextPath}<%= ann.get("image_url") %>" alt="Gambar pengumuman">
                        <% } %>
                        <p><%= escapeHtml(String.valueOf(ann.get("content"))) %></p>
                    </div>
                <%  }
                } %>
            </div>
        </div>

        <div class="hero-contact" aria-label="Maklumat hubungan Jabatan Air Sabah">
            <h3><img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Hubungi" style="height:24px;width:auto;"></h3>
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
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/assets/images/icon-home.png" alt="Laman utama"></a>
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













