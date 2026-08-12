<%-- NOTA ALIRAN KOD: Fail index.jsp. Halaman ini biasa dipanggil terus melalui UI atau navigation ke /index.jsp. Tujuan nota ni supaya orang seterusnya terus nampak konteks fail ni. --%>
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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Sistem Pendaftaran Pembekal dan Produk Bekalan Air (SPPPBA)</title>
    <meta name="description" content="Portal rasmi Sistem Pendaftaran Pembekal, Produk dan Bekalan Air Jabatan Air Negeri Sabah untuk pendaftaran produk air, pengumuman, dan semakan status permohonan.">
    <style>
:root {
            --brand-green: #114b3a;
            --brand-green-deep: #0b382b;
            --brand-yellow-pastel: #f6ecb1;
            --surface: #ffffff;
            --surface-soft: #f8f8f0;
            --text: #111111;
            --muted: #2b2b2b;
            --ring: rgba(17, 75, 58, 0.22);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: inherit;
            line-height: 1.6;
            color: var(--text);
            background:
                radial-gradient(circle at 8% -8%, rgba(17, 75, 58, 0.1), transparent 44%),
                radial-gradient(circle at 94% 12%, rgba(246, 236, 177, 0.45), transparent 38%),
                #f4f4ed;
            min-height: 100vh;
        }

        .navbar {
            position: sticky;
            top: 0;
            z-index: 30;
            background: linear-gradient(90deg, rgba(246, 236, 177, 0.98), rgba(250, 243, 197, 0.94));
            backdrop-filter: blur(8px);
            color: #111111;
            padding: 14px 26px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(17, 75, 58, 0.2);
            box-shadow: 0 8px 20px rgba(17, 75, 58, 0.15);
        }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logos { display: flex; align-items: center; gap: 10px; }
        .brand-logo { width: 68px; height: 68px; object-fit: contain; }
        .brand-text strong { display: block; font-size: 18px; line-height: 1.1; }
        .brand-text span { font-size: 12px; opacity: 0.9; letter-spacing: 0.02em; }

        .nav-actions { display: flex; gap: 10px; }
        .nav-link {
            color: #111111;
            text-decoration: none;
            font-weight: 700;
            padding: 9px 13px;
            border-radius: 999px;
            border: 1px solid rgba(17, 75, 58, 0.28);
            background: rgba(255, 255, 255, 0.58);
            transition: 0.2s ease;
        }
        .nav-link:hover, .nav-link:focus { background: rgba(255, 255, 255, 0.86); transform: translateY(-1px); }
        .nav-link.primary {
            background: linear-gradient(120deg, #f1e39a, #ead575);
            border-color: rgba(17, 75, 58, 0.36);
            color: #111111;
        }

        .hero {
            position: relative;
            height: auto;
            min-height: clamp(420px, 58vh, 680px);
            overflow: hidden;
            display: flex;
            align-items: center;
            padding: 96px 34px 150px 22px;
            background: #1579cc url('${pageContext.request.contextPath}/icon/Idxbg.gif?v=20260720') center/cover no-repeat;
            color: white;
            border-bottom-left-radius: 28px;
            border-bottom-right-radius: 28px;
            box-shadow: 0 20px 46px rgba(6, 47, 72, 0.28);
        }
        /* Shared blob base */
        .hero::before,
        .hero::after {
            content: "";
            position: absolute;
            border-radius: 50%;
            filter: blur(140px);
            opacity: 0.62;
            z-index: 1;
        }
        /* Left big soft blob */
        .hero::before {
            width: 620px;
            height: 620px;
            background: #4ad5f9;
            top: 30px;
            left: -140px;
        }
        /* Right glow */
        .hero::after {
            width: 650px;
            height: 650px;
            background: #1578cc;
            top: -20px;
            right: -170px;
        }

        .hero::selection {
            background: rgba(255, 255, 255, 0.25);
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
            font-size: clamp(36px, 4.8vw, 64px);
            color: #ffffff;
            line-height: 1.08;
            margin-bottom: 10px;
            max-width: 760px;
            letter-spacing: -0.028em;
            text-wrap: balance;
            text-shadow: 0 8px 24px rgba(6, 33, 51, 0.28);
            animation: riseIn .55s ease-out;
        }
        .hero .welcome-subtitle {
            max-width: 760px;
            color: rgba(246, 252, 255, 0.95);
            font-size: clamp(15px, 1.9vw, 20px);
            letter-spacing: 0.01em;
            font-weight: 500;
            text-shadow: 0 3px 16px rgba(6, 33, 51, 0.24);
            animation: riseIn .75s ease-out;
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
        .hero .welcome-title {
            font-size: clamp(42px, 5.4vw, 68px) !important;
            line-height: 1.08 !important;
        }
        .hero-btn:hover, .hero-btn:focus { transform: translateY(-1px); background: rgba(255, 255, 255, 0.22); }
        .hero-btn.accent { background: #ffffff; color: #0a5f8b; border-color: #ffffff; }
        .hero-btn.accent:hover, .hero-btn.accent:focus { background: #f0f9ff; }

        .role-choice-wrap {
            max-width: 1020px;
            margin: -66px auto 20px;
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
            background: linear-gradient(150deg, #114b3a, #0b382b);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(246, 236, 177, 0.2);
            border-radius: 22px;
            box-shadow: 0 18px 36px rgba(9, 35, 27, 0.28);
            padding: 18px;
            min-height: 190px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease, background-color 0.2s ease;
        }
        .role-card:hover,
        .role-card:focus-within {
            transform: translateY(-6px);
            box-shadow: 0 24px 44px rgba(9, 35, 27, 0.36);
            border-color: rgba(246, 236, 177, 0.42);
            background: linear-gradient(150deg, #165a46, #114636);
        }
        .role-card h3 {
            margin: 0 0 6px;
            font-size: 23px;
            color: #f9f4dc;
            letter-spacing: -0.01em;
        }
        .role-card-head {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .role-card-icon {
            width: 46px;
            height: 46px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 36px;
            line-height: 1;
            flex: 0 0 46px;
            margin-top: 2px;
            color: #f9f4dc;
        }
        .role-card p {
            margin: 0;
            color: #eef4ef;
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
            color: #111111;
            border: 1px solid rgba(246, 236, 177, 0.88);
            background: linear-gradient(125deg, #f6ecb1, #edd778);
            transition: transform 0.18s ease, box-shadow 0.18s ease, filter 0.18s ease;
            box-shadow: 0 10px 20px rgba(9, 35, 27, 0.2);
        }
        .role-card .role-login-btn:hover,
        .role-card .role-login-btn:focus {
            transform: translateY(-2px);
            box-shadow: 0 14px 24px rgba(9, 35, 27, 0.28);
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
            border: 1px solid rgba(17, 75, 58, 0.26);
            background: rgba(255, 255, 255, 0.95);
            color: #111111;
            font-weight: 800;
            box-shadow: 0 10px 20px rgba(9, 35, 27, 0.14);
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
        .quick-card h4 { margin-bottom: 6px; font-size: 16px; color: #111111; }
        .quick-card p { margin: 0; color: #111111; font-size: 14px; }

        .section-title { margin-bottom: 10px; font-size: 24px; letter-spacing: -0.01em; }
        .section-subtitle { margin-bottom: 16px; color: var(--muted); }

        .announcement-section {
            margin-bottom: 24px;
            border: 1px solid rgba(255, 255, 255, 0.18);
            border-radius: 22px;
            background: linear-gradient(155deg, #114b3a, #0b382b);
            box-shadow: 0 16px 34px rgba(9, 35, 27, 0.22);
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
        .maintenance-banner .maintenance-icon {
            width: 88px;
            height: 60px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            line-height: 1;
            color: #7b3f00;
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
            background: rgba(0, 0, 0, 0.18);
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
        }
        .icon-badge {
            width: 24px;
            height: 24px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: var(--brand-green);
        }
        .icon-badge svg {
            width: 22px;
            height: 22px;
            display: block;
        }
        .icon-badge .icon-glyph {
            width: 22px;
            height: 22px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            line-height: 1;
        }
        .announcement-header h3 { margin: 0; font-size: 16px; color: #ffffff; }
        .announcement-list { padding: 0 18px 10px; }
        .announcement-item { padding: 14px 0; border-bottom: 1px dashed rgba(255, 255, 255, 0.28); }
        .announcement-item:last-child { border-bottom: 0; }
        .announcement-item h4 { margin: 0 0 6px; font-size: 17px; color: #ffffff; }
        .announcement-item img { width: 100%; max-width: 360px; height: auto; border: 1px solid rgba(255, 255, 255, 0.38); border-radius: 10px; margin: 6px 0 8px; }
        .announcement-item p { margin: 0; color: #f4f7f5; white-space: pre-wrap; }
        .announcement-empty { padding: 14px 0; color: #f4f7f5; }

        .hero-contact {
            width: 100%;
            border-radius: 14px;
            border: 1px solid #d6e5ef;
            background: #f8fcff;
            padding: 12px;
            box-shadow: 0 8px 24px rgba(6, 47, 72, 0.07);
            margin-top: 10px;
        }
        .hero-contact h3 { margin: 0 0 10px; font-size: 16px; color: #111111; font-weight: 700; letter-spacing: 0; }
        .hero-contact p { margin: 7px 0; font-size: 13px; color: #111111; line-height: 1.45; }
        .contact-line {
            display: flex;
            align-items: flex-start;
            gap: 8px;
        }
        .jans-contact-section h3 {
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .jans-contact-section h3 .contact-icon {
            width: 14px;
            height: 14px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            line-height: 1;
            flex-shrink: 0;
        }
        .contact-line .contact-icon {
            width: 12px;
            height: 12px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            line-height: 1;
            flex-shrink: 0;
            margin-top: 2px;
        }
        .hero-contact .contact-line span { line-height: 1.45; }
        .contact-line-hanging {
            margin-left: 20px;
            display: block;
        }
        .hero-contact .contact-line span { line-height: 1.45; }

        footer {
            background: #f3f0db;
            color: #111111;
            text-align: center;
            padding: 30px;
            border-top-left-radius: 20px;
            border-top-right-radius: 20px;
            border-top: 1px solid rgba(17, 75, 58, 0.18);
        }
        footer .footer-links {
            margin-top: 8px;
            font-size: 13px;
            color: #111111;
        }
        footer .footer-links a {
            color: #111111;
            text-decoration: none;
            margin: 0 8px;
        }

        .floating-home-btn {
            position: static;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 54px;
            height: 54px;
            margin-left: 12px;
            border-radius: 999px;
            border: 2px solid #0b3f72;
            background: #0f4f8f;
            text-decoration: none;
            vertical-align: middle;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22);
            transition: background 0.18s ease;
        }
        .floating-home-btn:hover {
            background: #1263b5;
        }
        .floating-home-btn .icon-glyph {
            width: 30px;
            height: 30px;
            font-size: 30px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
        }
        .floating-home-btn svg {
            width: 28px;
            height: 28px;
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
            .role-choice-wrap { margin-top: -38px; }
            .role-card-icon { width: 42px; height: 42px; flex-basis: 42px; }
        }
        </style>
</head>
<body>
    <% if (maintenanceMode) { %>
    <div class="maintenance-overlay" aria-hidden="true">
        <div class="maintenance-banner" role="status" aria-live="polite" aria-atomic="true">
            <span class="maintenance-icon" aria-hidden="true">&#9888;</span>
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
                <strong>Sistem Pendaftaran Pembekal dan Produk Bekalan Air</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div class="nav-actions">
            <a class="nav-link" href="${pageContext.request.contextPath}/login">Log Masuk</a>
            <a class="nav-link primary" href="${pageContext.request.contextPath}/register">Daftar Pemohon</a>
        </div>
    </div>
    <div class="hero">
        <div class="hero-inner">
            <div>
                <h1 class="welcome-title">Selamat Datang ke Sistem Pendaftaran Pembekal dan Produk Bekalan Air</h1>
            </div>
        </div>
    </div>

    <section class="role-choice-wrap" aria-label="Pilih peranan log masuk">
        <div class="role-choice-grid">
            <article class="role-card admin-access-card">
                <div class="role-card-head">
                    <span class="role-card-icon" aria-hidden="true">&#128295;</span>
                    <div>
                        <h3>Portal Pentadbir</h3>
                        <p>Untuk pengurusan aplikasi, semakan pengguna, dan pemantauan Sistem Pendaftaran Pembekal dan Produk Bekalan Air.</p>
                    </div>
                </div>
                <a class="role-login-btn" href="${pageContext.request.contextPath}/login?role=ADMIN">Log Masuk Sebagai Admin</a>
            </article>
            <article class="role-card">
                <div class="role-card-head">
                    <span class="role-card-icon" aria-hidden="true">&#128101;</span>
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
                <span class="icon-badge" aria-hidden="true"><span class="icon-glyph">&#128227;</span></span>
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
                <h3><span class="contact-icon" aria-hidden="true">&#9743;</span> Hubungi JAS</h3>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#128205;</span><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#9742;</span><span>Tel: +60-88-232364 (HQ)</span></p>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#128224;</span><span>Fax: +60-88-232396</span></p>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#9993;</span><span>Email: jans.hq@sabah.gov.my</span></p></div>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Sistem Pendaftaran Pembekal dan Produk Bekalan Air (SPPPBA). Semua hak terpelihara.</p>
        <p>Jabatan Air  Sabah</p>
        <p class="footer-links">
            <a href="${pageContext.request.contextPath}/privacy-policy">Dasar Privasi</a>
            |
            <a href="${pageContext.request.contextPath}/terms">Terma Penggunaan</a>
        </p>
    </footer>
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama">
        <svg class="icon-glyph" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M3 10.5L12 3l9 7.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M5.5 9.5V21h13V9.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
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



