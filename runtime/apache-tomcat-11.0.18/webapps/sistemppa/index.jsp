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
    boolean maintenanceMode = Boolean.TRUE.equals(application.getAttribute("maintenanceMode"));
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
    <title>Sistem Pendaftaran Pembekal dan Produk Air (SPPPA)</title>
    <meta name="description" content="Portal rasmi Sistem Pendaftaran Pembekal dan Produk Air Jabatan Air Negeri Sabah untuk pendaftaran produk air, pengumuman, dan semakan status permohonan.">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');

        :root {
            --brand-blue: #1e88e5;
            --brand-navy: #0F6BAE;
            --brand-sky: #edf4fb;
            --surface: #ffffff;
            --surface-soft: #f3f8fc;
            --text: #1a3040;
            --muted: #5d7484;
            --ring: rgba(15, 107, 174, 0.22);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif;
            line-height: 1.6;
            color: var(--text);
            background: #eef5fb;
            min-height: 100vh;
        }

        .navbar {
            position: sticky;
            top: 0;
            z-index: 30;
            background: #0f6bae;
            color: white;
            padding: 14px 26px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid #65aeea;
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
            background: #1e88e5;
            border-color: rgba(255,255,255,0.35);
            color: #ffffff;
        }

        .hero {
            position: relative;
            height: auto;
            min-height: 260px;
            overflow: hidden;
            display: flex;
            align-items: center;
            padding: 72px 28px 72px 12px;
            background: #1579cc;
            color: white;
            border-bottom-left-radius: 28px;
            border-bottom-right-radius: 28px;
            box-shadow: 0 16px 42px rgba(6, 47, 72, 0.22);
        }
        /* Shared blob base */
        .hero::before,
        .hero::after {
            content: "";
            position: absolute;
            border-radius: 50%;
            filter: blur(120px);
            opacity: 0.7;
            z-index: 1;
        }
        /* Left big soft blob */
        .hero::before {
            width: 500px;
            height: 500px;
            background: #4ca6f2;
            top: 50px;
            left: -100px;
        }
        /* Right glow */
        .hero::after {
            width: 600px;
            height: 600px;
            background: #1e88e5;
            top: 0;
            right: -150px;
        }
        .hero-circle {
            position: absolute;
            border-radius: 50%;
            background: rgba(255,255,255,0.2);
            backdrop-filter: blur(5px);
            z-index: 2;
        }
        .hero-circle.small  { width: 40px;  height: 40px;  }
        .hero-circle.medium { width: 80px;  height: 80px;  }
        .hero-circle1 { top: 80px;    left: 200px;  }
        .hero-circle2 { top: 150px;   right: 300px; }
        .hero-circle3 { bottom: 60px; left: 300px;  }
        .hero-watermark {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            object-fit: contain;
            object-position: center;
            opacity: 0.16;
            pointer-events: none;
            z-index: 0;
            padding: 44px;
            filter: brightness(1.12);
        }
        .hero-inner {
            max-width: 1020px;
            margin: 0;
            position: relative;
            z-index: 10;
            width: 100%;
            text-align: left;
        }
        .hero h1 {
            position: relative;
            z-index: 11;
            font-size: clamp(30px, 4vw, 52px);
            line-height: 1.14;
            margin-bottom: 14px;
            max-width: 760px;
            letter-spacing: -0.02em;
            animation: riseIn .55s ease-out;
        }
        .hero p { font-size: 17px; margin-bottom: 20px; max-width: 720px; color: rgba(255,255,255,0.95); animation: riseIn .72s ease-out; }
        .hero-badges { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 16px; justify-content: flex-start; }
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

        .role-choice-wrap {
            max-width: 1020px;
            margin: -28px auto 26px;
            padding: 0 20px;
            position: relative;
            z-index: 2;
        }
        .role-choice-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
        }
        .role-card {
            background: rgba(255, 255, 255, 0.76);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.65);
            border-radius: 20px;
            box-shadow: 0 16px 30px rgba(6, 47, 72, 0.14);
            padding: 18px;
            min-height: 190px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease, background-color 0.2s ease;
        }
        .role-card:hover,
        .role-card:focus-within {
            transform: translateY(-5px);
            box-shadow: 0 22px 40px rgba(6, 47, 72, 0.2);
            border-color: rgba(15, 107, 174, 0.45);
            background: rgba(255, 255, 255, 0.9);
        }
        .role-card h3 {
            margin: 0 0 6px;
            font-size: 22px;
            color: #0d4568;
        }
        .role-card-head {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .role-card-icon {
            width: 46px;
            height: 46px;
            object-fit: contain;
            flex: 0 0 46px;
            margin-top: 2px;
        }
        .role-card p {
            margin: 0;
            color: #2d556d;
            font-size: 15px;
        }
        .role-card .role-login-btn {
            margin-top: 14px;
            align-self: center;
            width: min(260px, 100%);
            text-align: center;
            text-decoration: none;
            padding: 10px 16px;
            border-radius: 999px;
            font-weight: 800;
            color: #ffffff;
            border: 1px solid rgba(255, 255, 255, 0.85);
            background: #1e88e5;
            transition: transform 0.18s ease, box-shadow 0.18s ease, filter 0.18s ease;
            box-shadow: 0 10px 20px rgba(6, 47, 72, 0.18);
        }
        .role-card .role-login-btn:hover,
        .role-card .role-login-btn:focus {
            transform: translateY(-2px);
            box-shadow: 0 14px 24px rgba(6, 47, 72, 0.24);
            filter: brightness(1.03);
        }
        .first-signin-wrap {
            margin-top: 14px;
            display: flex;
            justify-content: center;
        }
        .first-signin-btn {
            text-decoration: none;
            display: inline-block;
            padding: 11px 24px;
            border-radius: 999px;
            border: 1px solid #d4e7f4;
            background: rgba(255, 255, 255, 0.88);
            color: #0f5d88;
            font-weight: 800;
            box-shadow: 0 8px 18px rgba(6, 47, 72, 0.12);
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
        .maintenance-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(5, 29, 45, 0.35);
            display: flex;
            align-items: flex-start;
            justify-content: center;
            padding: 14px 12px;
            z-index: 1300;
            pointer-events: none;
        }
        .maintenance-banner {
            width: min(980px, calc(100vw - 24px));
            margin: 0;
            padding: 12px 16px;
            border: 1px solid #f2c18b;
            border-radius: 14px;
            background: #ffffff;
            box-shadow: 0 10px 24px rgba(93, 60, 7, 0.14);
            display: flex;
            align-items: center;
            gap: 12px;
            pointer-events: auto;
        }
        .admin-access-card { position: relative; z-index: 1310; }
        .admin-access-card .role-login-btn { position: relative; z-index: 1311; }
        .maintenance-banner img {
            width: 88px;
            height: 60px;
            object-fit: contain;
            flex: 0 0 auto;
        }
        .maintenance-banner strong {
            display: block;
            margin-bottom: 3px;
            color: #7b3f00;
            font-size: 18px;
        }
        .maintenance-banner p {
            margin: 0;
            color: #7a4e1f;
            font-size: 14px;
            line-height: 1.45;
        }
        .announcement-header {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 16px 18px;
            background: #eaf4ff;
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
            border-radius: 14px;
            border: 1px solid #d6e5ef;
            background: #f8fcff;
            padding: 12px;
            box-shadow: 0 8px 24px rgba(6, 47, 72, 0.07);
            margin-top: 10px;
        }
        .hero-contact h3 { margin: 0 0 10px; font-size: 16px; color: #0f6bae; font-weight: 700; letter-spacing: 0; }
        .hero-contact p { margin: 7px 0; font-size: 13px; color: #4e6a7c; line-height: 1.45; }
        .contact-line {
            display: flex;
            align-items: flex-start;
            gap: 8px;
        }
        .contact-line .contact-icon {
            display: inline-block;
            width: 10px;
            height: 10px;
            background: #0f6bae;
            border-radius: 2px;
            flex-shrink: 0;
            margin-top: 2px;
        }
        .hero-contact .contact-line span { line-height: 1.45; }

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
            .role-choice-grid { grid-template-columns: 1fr; }
            .role-choice-wrap { margin-top: -18px; }
            .role-card-icon { width: 42px; height: 42px; flex-basis: 42px; }
        }
        </style>
</head>
<body>
    <% if (maintenanceMode) { %>
    <div class="maintenance-overlay" aria-hidden="true">
        <div class="maintenance-banner" role="status" aria-live="polite" aria-atomic="true">
            <img src="${pageContext.request.contextPath}/icon/under-maintenance.gif" alt="Sistem dalam penyelenggaraan">
            <div>
                <strong>Sistem Sedang Dalam Penyelenggaraan</strong>
                <p>Sila cuba semula selepas penyelenggaraan selesai.</p>
            </div>
        </div>
    </div>
    <% } %>
    <div class="navbar">
        <div class="brand">
            <div class="brand-logos">
                <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
                <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            </div>
            <div class="brand-text">
                <strong>Sistem Pendaftaran Pembekal dan Produk Air</strong>
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
        <div class="hero-circle small  hero-circle1" aria-hidden="true"></div>
        <div class="hero-circle medium hero-circle2" aria-hidden="true"></div>
        <div class="hero-circle small  hero-circle3" aria-hidden="true"></div>
        <div class="hero-inner">
            <div>
                <h1>Selamat Datang ke Sistem Pendaftaran Pembekal dan Produk Air</h1>
            </div>
        </div>
    </div>

    <section class="role-choice-wrap" aria-label="Pilih peranan log masuk">
        <div class="role-choice-grid">
            <article class="role-card admin-access-card">
                <div class="role-card-head">
                    <img class="role-card-icon" src="${pageContext.request.contextPath}/assets/images/admin.png" alt="Ikon portal pentadbir">
                    <div>
                        <h3>Portal Pentadbir</h3>
                        <p>Untuk pengurusan aplikasi, semakan pengguna, dan pemantauan Sistem Pendaftaran Pembekal dan Produk Air.</p>
                    </div>
                </div>
                <a class="role-login-btn" href="${pageContext.request.contextPath}/login?role=ADMIN">Log Masuk Sebagai Admin</a>
            </article>
            <article class="role-card">
                <div class="role-card-head">
                    <img class="role-card-icon" src="${pageContext.request.contextPath}/assets/images/users.png" alt="Ikon portal pemohon">
                    <div>
                        <h3>Portal Pemohon</h3>
                        <p>Untuk pendaftaran produk air, kemas kini maklumat, dan semakan status permohonan.</p>
                    </div>
                </div>
                <a class="role-login-btn" href="${pageContext.request.contextPath}/login?role=USER">Log Masuk Sebagai Pemohon</a>
            </article>
        </div>
        <div class="first-signin-wrap">
            <a class="first-signin-btn" href="${pageContext.request.contextPath}/register">Daftar akaun baharu</a>
        </div>
    </section>

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

        <div class="container" style="padding-top:0;">
            <div class="jans-contact-section">
                <h3>Hubungi JANS</h3>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><span>Tel: +60-88-232364 (HQ) , Fax: +60-88-232396</span></p>
                <p class="contact-line"><span>Email: jans.hq@sabah.gov.my</span></p></div>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Sistem Pendaftaran Pembekal dan Produk Air (SPPPA). Semua hak terpelihara.</p>
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
    if (homeBtn) return;

    var navContainer =document.querySelector('.nav-action > div:last-child');
    if (!navContainer) navContainer = document.querySelector('.nav-actions');
    if (!navContainer) return;

    if (homeBtn.parentElement !== navContainer) {
        navContainer.appendChild(homeBtn);
    }
})();
</script>
</body>
</html>

