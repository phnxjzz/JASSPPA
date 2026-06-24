<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
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
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Pentadbir - SPPA</title>
    <style>
        /* ── Design tokens ───────────────────────────── */
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-yellow: #fff212;
            --surface: #ffffff;
            --surface-soft: #f7fbff;
            --line: #d9e7f1;
            --text: #183244;
            --muted: #637d8d;
            --tr: 0.2s ease;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(180deg, #f4fbff 0%, #f9fcfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 76%, var(--brand-yellow) 190%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 52px; height: 52px; border-radius: 14px; object-fit: contain; padding: 4px; }
        .brand h1 { margin: 0; font-size: 19px; font-weight: 700; letter-spacing: -0.2px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.85; }
        .navbar a { color: white; text-decoration: none; margin-left: 14px; font-weight: 600; font-size: 13px; display: inline-flex; align-items: center; gap: 6px; opacity: 0.92; transition: opacity var(--tr); }
        .navbar a:hover { opacity: 1; }
        .navbar > div:last-child { display: flex; align-items: center; flex-wrap: wrap; justify-content: flex-end; gap: 8px; }
        .navbar > div:last-child span { font-size: 13px; font-weight: 600; margin-right: 6px; }
        .icon-inline { width: 14px; height: 14px; object-fit: contain; vertical-align: middle; }
        .icon-link { width: 32px; height: 32px; margin-left: 6px; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.4); display: inline-flex; align-items: center; justify-content: center; padding: 0; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; vertical-align: middle; }
        .panel-expand-btn { background: none; border: none; cursor: pointer; padding: 4px; display: inline-flex; align-items: center; }
        .panel-expand-btn img { width: 18px; height: 18px; object-fit: contain; }
        .container { max-width: 1320px; margin: 28px auto; padding: 0 20px 32px; }
        .left-panel, .right-panel { min-width: 0; }
        .hero { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 20px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; max-width: 760px; }
        .metric-strip { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .metric-chip { background: var(--surface-soft); border: 1px solid var(--line); padding: 10px 14px; border-radius: 999px; font-weight: 700; }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); padding: 14px; background: #f7fbff; }
        .contact-image strong { display: block; margin-bottom: 8px; color: var(--brand-navy); }
        .contact-image p { margin: 4px 0; color: var(--muted); font-size: 14px; }
        .stats { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 16px; margin-bottom: 20px; }
        .stat-card { background: var(--surface); padding: 18px; border-radius: 18px; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        .stat-card .number { font-size: 30px; font-weight: 800; color: var(--brand-navy); }
        .layout { display: grid; grid-template-columns: 1.9fr 1fr; gap: 20px; }
        .toolbar { display: grid; grid-template-columns: minmax(220px, 1.6fr) repeat(3, minmax(140px, 1fr)); gap: 12px; align-items: end; margin-bottom: 16px; }
        .export-control { min-width: 0; }
        .export-help { margin-top: 6px; font-size: 12px; color: var(--muted); }
        .field { min-width: 0; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); }
        .btn { padding: 11px 15px; border-radius: 12px; border: 1px solid #fff; text-decoration: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .btn-accent { background: #fff7b0; color: #6a5a00; }
        .section-stack { display: grid; gap: 18px; }
        .announcement-panel { border-top: 4px solid #0097d9; }
        .announcement-head { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
        .announcement-head img { width: 18px; height: 18px; object-fit: contain; }
        .announce-alert { margin-bottom: 12px; border-radius: 10px; padding: 10px 12px; font-size: 13px; }
        .announce-success { background: #e7f9ec; color: #166534; border: 1px solid #b8e7c6; }
        .announce-error { background: #fff1f2; color: #b91c1c; border: 1px solid #fecdd3; }
        .announcement-form { display: grid; gap: 10px; margin-bottom: 14px; }
        .announcement-form input[type="text"], .announcement-form textarea { width: 100%; border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px; font: inherit; }
        .announcement-form input[type="file"] { width: 100%; border: 1px dashed var(--line); border-radius: 10px; padding: 10px 12px; font: inherit; background: #f9fcff; }
        .announcement-form textarea { min-height: 96px; resize: vertical; }
        .announce-image-preview { margin-top: 8px; }
        .announce-image-preview img { width: 100%; max-width: 220px; height: auto; border: 1px solid var(--line); border-radius: 10px; }
        .announcement-form { display: grid; gap: 10px; margin-bottom: 14px; }
        .announcement-form input[type="text"],
        .announcement-form textarea {
            width: 100%; border: 1px solid var(--line); border-radius: 10px;
            padding: 10px 12px; font: inherit; font-size: 13px;
            background: var(--surface-soft);
            transition: border-color var(--tr), box-shadow var(--tr);
        }
        .announcement-form input[type="text"]:focus,
        .announcement-form textarea:focus {
            outline: none;
            border-color: var(--brand-navy);
            box-shadow: 0 0 0 3px rgba(15,107,174,0.1);
        }
        .announcement-form input[type="file"] {
            width: 100%; border: 1px dashed var(--line); border-radius: 10px;
            padding: 10px 12px; font: inherit; background: var(--surface-soft);
        }
        .announcement-form textarea { min-height: 96px; resize: vertical; }
        .announcement-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .announcement-table td { font-size: 13px; }
        .icon-btn { width: 13px; height: 13px; object-fit: contain; }
        .table-card-header { display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 14px; }
        .section-title { margin: 0; font-size: 17px; color: var(--brand-navy); }
        .table-wrapper { overflow-x: auto; max-width: 100%; border: 1px solid var(--line); border-radius: 14px; }
        table { width: 100%; border-collapse: collapse; min-width: 700px; background: white; }
        th, td { padding: 11px 10px; border-bottom: 1px solid #e7eef4; text-align: left; vertical-align: top; }
        th { font-size: 12px; text-transform: uppercase; letter-spacing: 0.03em; color: #4f6776; background: #f6fbff; }
        td { font-size: 13px; }
        .table-check { width: 16px; height: 16px; cursor: pointer; }
        .subtle { color: #607989; font-size: 12px; line-height: 1.4; }
        .empty { text-align: center; color: #6e8492; padding: 18px; }
        .status-pill { display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; font-size: 11px; font-weight: 700; padding: 4px 10px; }
        .status-new { background: #dbeafe; color: #1e40af; }
        .status-under_review { background: #e0f2fe; color: #0369a1; }
        .status-in_progress { background: #ede9fe; color: #7c3aed; }
        .status-approved { background: #dff5e7; color: #156b3c; }
        .status-rejected { background: #ffe1e4; color: #9f1f2b; }
        .status-suspended { background: #ececf2; color: #4a4a60; }
        .status-draft { background: #e8f0fb; color: #1b4f8f; }
        .status-archived { background: #eef1f4; color: #455867; }
        .bulk-toolbar { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin: 12px 0; }
        .bulk-count { margin-left: 6px; color: #5c7788; font-size: 13px; font-weight: 600; }
        .btn-danger { background: #fbe0e3; color: #9f1f2b; border-color: #f4c5cb; }
        .btn-archive { background: #eef3f7; color: #3f5461; border-color: #d1dce4; }
        .action-cell { display: flex; align-items: stretch; gap: 6px; flex-wrap: wrap; min-width: 0; }
        .action-cell .btn,
        .action-cell form { min-width: 104px; flex: 1 1 104px; }
        .action-cell .btn { width: 100%; min-height: 40px; white-space: nowrap; }
        .action-cell form { margin: 0; display: inline-flex; }
        .action-cell form .btn-archive {
            min-width: 40px;
            width: 40px;
            padding: 0;
            flex: 0 0 40px;
        }
        .action-cell form .btn-archive .icon-btn {
            width: 16px;
            height: 16px;
        }
        .archive-toast {
            position: fixed;
            right: 20px;
            bottom: 22px;
            z-index: 1500;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 14px;
            border-radius: 12px;
            background: #ffffff;
            border: 1px solid #d4e4ef;
            box-shadow: 0 14px 34px rgba(6, 52, 79, 0.20);
            transform: translateY(14px);
            opacity: 0;
            pointer-events: none;
            transition: opacity var(--tr), transform var(--tr);
        }
        .archive-toast.show {
            opacity: 1;
            transform: translateY(0);
        }
        .archive-toast img {
            width: 20px;
            height: 20px;
            object-fit: contain;
            animation: toastPulse 0.95s ease-in-out infinite;
        }
        .archive-toast span {
            font-size: 13px;
            font-weight: 700;
            color: #24495e;
        }
        @keyframes toastPulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.16); }
            100% { transform: scale(1); }
        }
        .export-summary { margin: 10px 0 14px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
        .export-metric { border: 1px solid var(--line); border-radius: 10px; background: #f9fcff; padding: 8px 10px; }
        .export-metric small { display: block; color: #617c8d; font-size: 11px; }
        .export-metric strong { display: block; color: #0a4a7b; font-size: 18px; margin-top: 2px; }
        .quick-actions { display: grid; grid-template-columns: 1fr; gap: 8px; }
        .notification-list, .activity-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }
        .notification-item, .activity-item { border: 1px solid var(--line); border-radius: 12px; padding: 10px; background: #f9fcff; }
        .notification-item strong, .activity-item strong { display: block; margin-bottom: 4px; font-size: 13px; color: #0d4f80; }
        .notification-item span, .activity-item span { color: #577082; font-size: 12px; }
        .notif-warning { border-left: 4px solid #f1b100; }
        .notif-recent { border-left: 4px solid #0f6bae; }
        .status-alert-panel { margin-bottom: 16px; border: 1px solid #ffe6a7; border-left: 5px solid #f4b400; background: #fff9e8; border-radius: 12px; padding: 12px 14px; }
        .status-alert-title { margin: 0 0 8px; color: #7d5500; font-size: 14px; }
        .status-alert-list { margin: 0; padding-left: 18px; color: #694d0f; font-size: 13px; }
        .title-wrap { display: flex; align-items: center; gap: 8px; min-width: 0; }
        .legend-label { display: inline-flex; align-items: center; gap: 8px; }
        .legend-value { font-weight: 700; color: #0f456f; }
        .legend-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
        .legend-dot.approved { background: #1b8f55; }
        .legend-dot.rejected { background: #cf4e4e; }
        .legend-dot.new { background: #3b82f6; }
        .jans-contact-section { margin-top: 16px; border: 1px solid var(--line); border-radius: 14px; background: #f9fcff; padding: 12px; }
        .contact-line { display: flex; gap: 8px; align-items: flex-start; margin: 8px 0; color: #4e6a7c; font-size: 13px; }
        .contact-icon { width: 16px; height: 16px; object-fit: contain; margin-top: 1px; flex: 0 0 16px; }
        .contact-address-link { color: #0f6bae; text-decoration: none; }
        .contact-address-link:hover { text-decoration: underline; }

        @media (max-width: 1200px) {
            .stats { grid-template-columns: repeat(3, minmax(0, 1fr)); }
            .layout { grid-template-columns: 1fr; }
            .toolbar { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .export-summary { grid-template-columns: 1fr; }
        }
        @media (max-width: 860px) {
            .navbar { padding: 12px 14px; flex-direction: column; align-items: flex-start; }
            .navbar > div:last-child { justify-content: flex-start; }
            .container { padding: 0 10px 20px; }
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .toolbar { grid-template-columns: 1fr; }
            .panel { padding: 14px; border-radius: 14px; }
            .brand-logo { width: 42px; height: 42px; }
            .brand h1 { font-size: 16px; }
            table { min-width: 620px; }
            .action-cell { flex-direction: column; }
            body.popup-open .table-card.popup-active,
            body.popup-open #announcementPanel.popup-active {
                width: calc(100vw - 10px);
                max-height: calc(100vh - 12px);
                border-radius: 12px;
            }
        }

        /* ── Misc ────────────────────────────────────── */
        .announce-with-gif { display: flex; align-items: center; gap: 10px; }
        .announce-title  { font-weight: 700; color: var(--brand-navy); }
        .announce-content { color: var(--muted); margin-top: 4px; white-space: pre-wrap; }
        .announce-status { display: inline-block; border-radius: 999px; padding: 3px 10px; font-size: 11px; font-weight: 700; }
        .announce-active   { background: #d1fae5; color: #065f46; }
        .announce-inactive { background: #e9edf2; color: #374151; }
        .analytics-chart {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-top: 8px;
            flex-wrap: wrap;
        }
        .pie-chart {
            width: 128px;
            height: 128px;
            border-radius: 50%;
            position: relative;
            flex: 0 0 auto;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.45), 0 6px 16px rgba(0,0,0,0.08);
        }
        .pie-chart[data-gradient] {
            background: var(--pie-gradient, conic-gradient(#1b8f55 0deg, #cf4e4e 120deg, #df8f1f 240deg));
        }
        .pie-chart::after {
            content: '';
            position: absolute;
            inset: 26%;
            border-radius: 50%;
            background: #ffffff;
            border: 1px solid #e4edf4;
        }
        .pie-center {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            z-index: 2;
            text-align: center;
        }
        .pie-center small {
            display: block;
            font-size: 11px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .pie-center strong {
            display: block;
            font-size: 16px;
            color: #0F6BAE;
            line-height: 1.1;
            font-weight: 800;
        }
        .analytics-legend {
            list-style: none;
            margin: 0;
            padding: 0;
            display: grid;
            gap: 8px;
            min-width: 0;
            flex: 1 1 180px;
        }
        .analytics-legend li {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 8px 10px;
            border-radius: 10px;
            background: #f7fbff;
            border: 1px solid #e2edf5;
            font-size: 13px;
        }
        .expand-overlay {
            position: fixed;
            inset: 0;
            background: rgba(3, 18, 32, 0.62);
            backdrop-filter: blur(2px);
            display: none;
            z-index: 1200;
        }
        body.popup-open { overflow: hidden; }
        body.popup-open .expand-overlay { display: block; }
        body.popup-open .table-card.popup-active,
        body.popup-open #announcementPanel.popup-active {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: min(1120px, calc(100vw - 24px));
            max-height: calc(100vh - 38px);
            overflow: auto;
            z-index: 1210;
            border-radius: 18px;
            box-shadow: 0 30px 90px rgba(2, 24, 43, 0.44);
            margin: 0;
        }
        .panel-expand-btn[aria-expanded="true"] img { transform: rotate(180deg); }
        .panel-expand-btn img { transition: transform var(--tr); }
        </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Dashboard Pentadbir</h1>
                <p>Pusat kawalan permohonan, produk, dan laporan SPPA</p>
            </div>
        </div>
        <div>
            <span>Selamat datang, <%= session.getAttribute("username") %></span>
            <a href="${pageContext.request.contextPath}/admin/users">Senarai Pengguna</a>
            <a href="${pageContext.request.contextPath}/products">Senarai Produk</a>
            <a href="${pageContext.request.contextPath}/profile">Kemaskini Profil</a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/assets/images/home.png" alt="Home"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
        </div>
    </div>

    <div class="container">
        <div class="stats">
            <div class="stat-card main">
                <h3>Jumlah Permohonan</h3>
                <div class="number"><%= request.getAttribute("total_applications") != null ? request.getAttribute("total_applications") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Menunggu</h3>
                <div class="number"><%= request.getAttribute("pending_count") != null ? request.getAttribute("pending_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Diluluskan</h3>
                <div class="number"><%= request.getAttribute("approved_count") != null ? request.getAttribute("approved_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Ditolak</h3>
                <div class="number"><%= request.getAttribute("rejected_count") != null ? request.getAttribute("rejected_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Produk Berdaftar</h3>
                <div class="number"><%= request.getAttribute("total_products") != null ? request.getAttribute("total_products") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Diarkib</h3>
                <div class="number"><%= request.getAttribute("archived_count") != null ? request.getAttribute("archived_count") : "0" %></div>
            </div>
        </div>

        <%
            int pendingCountAlert = request.getAttribute("pending_count") instanceof Number ? ((Number) request.getAttribute("pending_count")).intValue() : 0;
            int rejectedCountAlert = request.getAttribute("rejected_count") instanceof Number ? ((Number) request.getAttribute("rejected_count")).intValue() : 0;
            boolean showStatusAlert = pendingCountAlert > 7 || rejectedCountAlert > 10;
        %>
        <% if (showStatusAlert) { %>
        <div class="status-alert-panel">
            <h4 class="status-alert-title">Amaran Status Permohonan</h4>
            <ul class="status-alert-list">
                <% if (pendingCountAlert > 7) { %>
                <li>Jumlah permohonan menunggu semakan melebihi 7 rekod. Sila semak keutamaan proses.</li>
                <% } %>
                <% if (rejectedCountAlert > 10) { %>
                <li>Jumlah permohonan ditolak adalah tinggi. Sila semak punca utama penolakan.</li>
                <% } %>
            </ul>
        </div>
        <% } %>

        <%
            List<Map<String, Object>> applications = (List<Map<String, Object>>) request.getAttribute("pending_applications");
            boolean isAdminRole = "ADMIN".equals(String.valueOf(session.getAttribute("role")));
        %>

        <div class="layout">
            <div class="left-panel">
                <div class="panel table-card">
                    <div class="table-card-header">
                        <h3 class="section-title">Permohonan Terkini</h3>
                        <button type="button" class="panel-expand-btn" id="toggleLatestPanelBtn" aria-label="Besarkan panel permohonan" title="Expand / Collapse">
                            <img src="${pageContext.request.contextPath}/assets/images/expand.png" alt="Expand" onerror="this.style.display='none';">
                        </button>
                    </div>
                    <form method="get" action="${pageContext.request.contextPath}/dashboard" class="toolbar">
                    <div class="field">
                        <label for="q"><img src="${pageContext.request.contextPath}/assets/images/icon-search.png" class="icon-inline" alt="Ikon carian"> Carian</label>
                        <input id="q" name="q" type="text" value="<%= request.getAttribute("search_query") %>" placeholder="Cari syarikat, produk, pemohon atau email">
                    </div>
                    <div class="field">
                        <label for="status">Status</label>
                        <select id="status" name="status">
                            <option value="">Semua status</option>
                            <option value="NEW" <%= "NEW".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>NEW</option>
                            <option value="UNDER_REVIEW" <%= "UNDER_REVIEW".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>UNDER REVIEW</option>
                            <option value="IN_PROGRESS" <%= "IN_PROGRESS".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>IN PROGRESS</option>
                            <option value="APPROVED" <%= "APPROVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>APPROVED</option>
                            <option value="REJECTED" <%= "REJECTED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>REJECTED</option>
                            <option value="SUSPENDED" <%= "SUSPENDED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>SUSPENDED</option>
                            <option value="DRAFT" <%= "DRAFT".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DRAFT</option>
                            <option value="ARCHIVED" <%= "ARCHIVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>ARCHIVED</option>
                        </select>
                    </div>
                    <div class="field">
                        <label for="date_from">Tarikh Dari</label>
                        <input id="date_from" name="date_from" type="date" value="<%= request.getAttribute("date_from") != null ? request.getAttribute("date_from") : "" %>">
                    </div>
                    <div class="field">
                        <label for="date_to">Tarikh Hingga</label>
                        <input id="date_to" name="date_to" type="date" value="<%= request.getAttribute("date_to") != null ? request.getAttribute("date_to") : "" %>">
                    </div>
                    <button class="btn btn-primary" type="submit">Tapis</button>
                    <div class="field export-control">
                        <label for="exportOption">Eksport</label>
                        <select id="exportOption" name="exportOption">
                            <optgroup label="Ikut penapis semasa">
                                <option value="xlsx_current">Excel</option>
                                <option value="pdf_current">PDF</option>
                            </optgroup>
                            <optgroup label="Status khusus">
                                <option value="xlsx_approved">Excel - APPROVED</option>
                                <option value="xlsx_rejected">Excel - REJECTED</option>
                                <option value="pdf_approved">PDF - APPROVED</option>
                                <option value="pdf_rejected">PDF - REJECTED</option>
                            </optgroup>
                        </select>
                    </div>
                    <button class="btn btn-secondary" type="button" id="exportDownloadBtn" aria-label="Turun" title="Turun"><img src="${pageContext.request.contextPath}/assets/images/icon-download.png" class="icon-inline" alt="Ikon turun"></button>
                    </form>

                    <% if (isAdminRole) { %>
                    <form id="bulkActionForm" method="get" action="${pageContext.request.contextPath}/admin/application" data-announcement-action="true">
                        <input type="hidden" id="bulkActionType" name="bulk_action_type" value="">
                        <input type="hidden" id="bulkSelectedIds" name="selected_ids" value="">
                        <input type="hidden" id="bulkFirstId" name="id" value="">
                        <div class="bulk-toolbar">
                            <button class="btn btn-primary" id="bulkApproveBtn" type="button">Approve Selected</button>
                            <button class="btn btn-secondary" id="bulkRejectBtn" type="button">Reject Selected</button>
                            <button class="btn btn-accent" id="bulkExportBtn" type="button">Export Selected</button>
                            <span class="bulk-count" id="bulkSelectedCount">0 dipilih</span>
                        </div>
                    </form>
                    <% } %>

                    <div class="table-wrapper">
                    <table>
                    <thead>
                        <tr>
                            <% if (isAdminRole) { %>
                            <th style="width:42px;"></th>
                            <% } %>
                            <th>ID</th>
                            <th>Nama Syarikat</th>
                            <th>Maklumat Produk</th>
                            <th>Status</th>
                            <th>Tarikh Penghantaran</th>
                            <th>Tindakan</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (applications == null || applications.isEmpty()) { %>
                        <tr>
                            <td colspan="<%= isAdminRole ? "7" : "6" %>" class="empty">Tiada permohonan ditemui untuk penapis ini.</td>
                        </tr>
                        <% } else {
                            for (Map<String, Object> applicationRow : applications) {
                                Timestamp submittedAt = (Timestamp) applicationRow.get("submitted_at");
                                Timestamp archivedAt = (Timestamp) applicationRow.get("archived_at");
                                String archiveNotes = applicationRow.get("archive_notes") == null ? "" : String.valueOf(applicationRow.get("archive_notes"));
                                String status = String.valueOf(applicationRow.get("status")).toLowerCase();
                                int appIdNumeric = applicationRow.get("id") instanceof Number ? ((Number) applicationRow.get("id")).intValue() : 0;
                                int appIdDisplayNumeric = Math.max(0, appIdNumeric - 1);
                                String appIdDisplay = String.format("PPP%03d", appIdDisplayNumeric);
                                boolean isArchivedRow = "archived".equals(status);
                                boolean canArchiveRow = "approved".equals(status) || "rejected".equals(status) || "suspended".equals(status);
                                String archiveConfirmText = isArchivedRow ? "Buka semula arkib permohonan ini?" : "Arkibkan permohonan ini?";
                                String archiveButtonText = isArchivedRow ? "Buka Arkib" : "Arkib";
                                String archiveActionValue = isArchivedRow ? "unarchive" : "archive";
                                String archiveIconPath = isArchivedRow
                                    ? (request.getContextPath() + "/assets/images/icon-unarchive.png")
                                    : (request.getContextPath() + "/assets/images/icon-archive.png");
                        %>
                        <tr>
                            <% if (isAdminRole) { %>
                            <td><input type="checkbox" class="app-row-check table-check" value="<%= applicationRow.get("id") %>" aria-label="Pilih permohonan"></td>
                            <% } %>
                            <td><strong><%= appIdDisplay %></strong></td>
                            <td>
                                <strong><%= applicationRow.get("company_name") %></strong><br>
                                <span class="subtle">Pemohon: <%= applicationRow.get("full_name") %><br>Email: <%= applicationRow.get("user_email") %>
                                <% if (isArchivedRow && archivedAt != null) { %><br>Arkib: <%= archivedAt %><% } %>
                                </span>
                            </td>
                            <td>
                                <strong>Model:</strong> <%= applicationRow.get("product_name") %><br>
                                <span class="subtle"><strong>Siri:</strong> <%= applicationRow.get("product_category") %></span><br>
                                <span class="subtle"><strong>Deskripsi:</strong> <%= applicationRow.get("product_description") == null || String.valueOf(applicationRow.get("product_description")).trim().isEmpty() ? "-" : applicationRow.get("product_description") %></span>
                            </td>
                            <td><span class="status-pill status-<%= status %>"><%= applicationRow.get("status") %></span></td>
                            <td><%= submittedAt != null ? submittedAt.toString() : "Belum dihantar" %></td>
                            <td>
                                <div class="action-cell">
                                <a
                                    class="btn btn-primary js-open-app-modal"
                                    href="${pageContext.request.contextPath}/admin/application?id=<%= applicationRow.get("id") %>"
                                    data-app-id="<%= applicationRow.get("id") %>"
                                    data-company="<%= escapeHtml(applicationRow.get("company_name") == null ? "" : String.valueOf(applicationRow.get("company_name")) ) %>"
                                    data-category="<%= escapeHtml(applicationRow.get("product_category") == null ? "" : String.valueOf(applicationRow.get("product_category")) ) %>"
                                    data-product="<%= escapeHtml(applicationRow.get("product_name") == null ? "" : String.valueOf(applicationRow.get("product_name")) ) %>"
                                    data-description="<%= escapeHtml(applicationRow.get("product_description") == null ? "" : String.valueOf(applicationRow.get("product_description")) ) %>"
                                    data-status="<%= escapeHtml(applicationRow.get("status") == null ? "" : String.valueOf(applicationRow.get("status")) ) %>"
                                    data-submitted="<%= escapeHtml(submittedAt != null ? submittedAt.toString() : "Belum dihantar") %>"
                                    data-user="<%= escapeHtml(applicationRow.get("full_name") == null ? "" : String.valueOf(applicationRow.get("full_name")) ) %>"
                                    data-email="<%= escapeHtml(applicationRow.get("user_email") == null ? "" : String.valueOf(applicationRow.get("user_email")) ) %>"
                                    data-attachment-image="<%= escapeHtml(applicationRow.get("attachment_image_url") == null ? "" : String.valueOf(applicationRow.get("attachment_image_url")) ) %>"
                                    data-attachment-pdf="<%= escapeHtml(applicationRow.get("attachment_pdf_url") == null ? "" : String.valueOf(applicationRow.get("attachment_pdf_url")) ) %>">
                                    Semak
                                </a>
                                <% if (isArchivedRow || canArchiveRow) { %>
                                <button
                                    class="btn btn-archive js-archive-btn"
                                    type="button"
                                    title="<%= archiveButtonText %>"
                                    aria-label="<%= archiveButtonText %>"
                                    data-app-id="<%= escapeHtml(String.valueOf(applicationRow.get("id"))) %>"
                                    data-action="<%= escapeHtml(archiveActionValue) %>"
                                    data-confirm="<%= escapeHtml(archiveConfirmText) %>"
                                    data-csrf="${csrf_token}"
                                    data-ctx="${pageContext.request.contextPath}">
                                    <img src="<%= archiveIconPath %>" class="icon-btn" alt="Arkib">
                                </button>
                                <% } %>
                                </div>
                            </td>
                        </tr>
                        <%      }
                           }
                        %>
                    </tbody>
                    </table>
                    </div><!-- /table-wrapper -->
                </div>

                <div class="panel">
                    <h3 class="section-title">Analitik Status Permohonan</h3>
                    <%
                        int approvedChart = request.getAttribute("approved_count") instanceof Number ? ((Number) request.getAttribute("approved_count")).intValue() : 0;
                        int rejectedChart = request.getAttribute("rejected_count") instanceof Number ? ((Number) request.getAttribute("rejected_count")).intValue() : 0;
                        int pendingChart = request.getAttribute("pending_count") instanceof Number ? ((Number) request.getAttribute("pending_count")).intValue() : 0;
                        int totalChart = Math.max(1, approvedChart + rejectedChart + pendingChart);
                        int approvedDeg = (int) Math.round((approvedChart * 360.0) / totalChart);
                        int rejectedDeg = (int) Math.round((rejectedChart * 360.0) / totalChart);
                        int pendingDeg = 360 - approvedDeg - rejectedDeg;
                        int approvedEnd = approvedDeg;
                        int rejectedEnd = approvedDeg + rejectedDeg;
                        String pieGradient = "conic-gradient(#1b8f55 0deg " + approvedEnd + "deg, #cf4e4e " + approvedEnd + "deg " + rejectedEnd + "deg, #df8f1f " + rejectedEnd + "deg 360deg)";
                    %>
                    <div class="analytics-chart" aria-label="Carta status permohonan">
                        <div class="pie-chart" data-gradient="<%= pieGradient %>">
                            <div class="pie-center">
                                <small>Total</small>
                                <strong><%= approvedChart + rejectedChart + pendingChart %></strong>
                            </div>
                        </div>
                        <ul class="analytics-legend">
                            <li>
                                <span class="legend-label"><span class="legend-dot approved"></span>Diluluskan</span>
                                <span class="legend-value"><%= approvedChart %></span>
                            </li>
                            <li>
                                <span class="legend-label"><span class="legend-dot rejected"></span>Ditolak</span>
                                <span class="legend-value"><%= rejectedChart %></span>
                            </li>
                            <li>
                                <span class="legend-label"><span class="legend-dot new"></span>Baharu</span>
                                <span class="legend-value"><%= pendingChart %></span>
                            </li>
                        </ul>
                    </div>
                </div>

            </div>

            <div class="right-panel">
                <div class="panel">
                    <h3 class="section-title">Quick Actions</h3>
                    <div class="quick-actions">
                        <a class="btn btn-primary" href="#announcementPanel">Tambah Pengumuman</a>
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/users">Urus Pengguna</a>
                        <a class="btn btn-archive" href="${pageContext.request.contextPath}/dashboard?status=ARCHIVED">Lihat Arkib</a>
                        <button class="btn btn-accent" type="button" id="quickExportBtn">Eksport</button>
                    </div>
                </div>

                <div class="panel">
                    <h3 class="section-title">Pemberitahuan</h3>
                    <ul class="notification-list">
                        <li class="notification-item notif-warning">
                            <strong>Permohonan Menunggu</strong>
                            <span><%= request.getAttribute("pending_count") != null ? request.getAttribute("pending_count") : "0" %> permohonan perlu semakan.</span>
                        </li>
                        <li class="notification-item notif-warning">
                            <strong>Permohonan Ditolak</strong>
                            <span><%= request.getAttribute("rejected_count") != null ? request.getAttribute("rejected_count") : "0" %> rekod memerlukan tindakan susulan.</span>
                        </li>
                        <% if (applications != null && !applications.isEmpty()) {
                            int noticeShown = 0;
                            for (Map<String, Object> appNotice : applications) {
                                if (noticeShown >= 3) { break; }
                                noticeShown++;
                        %>
                        <li class="notification-item notif-recent">
                            <strong><%= escapeHtml(String.valueOf(appNotice.get("company_name"))) %></strong>
                            <span>Status: <%= escapeHtml(String.valueOf(appNotice.get("status"))) %></span>
                        </li>
                        <%      }
                           } %>
                    </ul>
                </div>

                <div class="panel">
                    <h3 class="section-title">Aktiviti Terkini</h3>
                    <ul class="activity-list">
                        <% if (applications != null && !applications.isEmpty()) {
                            int activityShown = 0;
                            for (Map<String, Object> activityRow : applications) {
                                if (activityShown >= 5) { break; }
                                activityShown++;
                                Timestamp activityTime = (Timestamp) activityRow.get("submitted_at");
                        %>
                        <li class="activity-item">
                            <strong><%= escapeHtml(String.valueOf(activityRow.get("full_name"))) %></strong> mengemaskini permohonan
                            <span class="muted"><%= activityTime != null ? escapeHtml(activityTime.toString()) : "Masa tidak tersedia" %></span>
                        </li>
                        <%      }
                           } else { %>
                        <li class="activity-item">Tiada aktiviti terkini buat masa ini.</li>
                        <% } %>
                    </ul>
                </div>

                <div class="panel announcement-panel" id="announcementPanel">
                    <div class="announcement-head">
                        <div class="title-wrap">
                            <img src="${pageContext.request.contextPath}/assets/images/icon-announcement.png" alt="Pengumuman">
                            <h3 class="section-title" style="margin:0;">Pengurusan Pengumuman</h3>
                        </div>
                        <button type="button" class="panel-expand-btn" id="toggleAnnouncementPanelBtn" aria-label="Besarkan panel pengumuman" title="Expand / Collapse">
                            <img src="${pageContext.request.contextPath}/assets/images/expand.png" alt="Expand" onerror="this.style.display='none';">
                        </button>
                    </div>

                    <% if (request.getAttribute("announcement_success") != null) { %>
                        <div class="announce-alert announce-success"><%= request.getAttribute("announcement_success") %></div>
                    <% } %>
                    <% if (request.getAttribute("announcement_error") != null) { %>
                        <div class="announce-alert announce-error"><%= request.getAttribute("announcement_error") %></div>
                    <% } %>

                    <%
                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> announcementList = (List<Map<String, Object>>) request.getAttribute("announcements");
                        if (announcementList == null) announcementList = java.util.Collections.emptyList();
                    %>
                    <% if (!announcementList.isEmpty()) { %>
                    <div style="overflow-x:auto; margin-bottom:18px;">
                        <table class="app-table announcement-table" style="width:100%;">
                            <thead>
                                <tr>
                                    <th style="width:36px;">#</th>
                                    <th>Tajuk</th>
                                    <th style="width:90px;">Status</th>
                                    <th style="width:140px;">Tarikh Cipta</th>
                                    <th style="width:110px;">Tindakan</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (int ai = 0; ai < announcementList.size(); ai++) {
                                Map<String, Object> ann = announcementList.get(ai);
                                boolean annActive = Boolean.TRUE.equals(ann.get("is_active"));
                                String annId = String.valueOf(ann.get("id"));
                                String annTitle = escapeHtml(String.valueOf(ann.get("title")));
                                Object annCreated = ann.get("created_at");
                                String annDate = annCreated == null ? "-" : String.valueOf(annCreated).substring(0, Math.min(10, String.valueOf(annCreated).length()));
                                String annStatusClass = annActive ? "announce-status announce-active" : "announce-status announce-inactive";
                                String annStatusText = annActive ? "Aktif" : "Tidak Aktif";
                            %>
                                <tr>
                                    <td><%= ai + 1 %></td>
                                    <td style="max-width:220px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<%= annTitle %>"><%= annTitle %></td>
                                    <td>
                                        <span class="<%= annStatusClass %>">
                                            <%= annStatusText %>
                                        </span>
                                    </td>
                                    <td style="font-size:12px; color:#666;"><%= annDate %></td>
                                    <td>
                                        <div style="display:flex; gap:6px; flex-wrap:wrap;">
                                            <a class="btn btn-secondary" style="padding:4px 10px; font-size:12px;"
                                               href="${pageContext.request.contextPath}/dashboard?announcement_id=<%= annId %>#announcementPanel">
                                                <img src="${pageContext.request.contextPath}/assets/images/icon-edit.png" class="icon-btn" alt="Edit" style="width:12px;height:12px;"> Edit
                                            </a>
                                            <% if (isAdminRole) { %>
                                            <form method="post" action="${pageContext.request.contextPath}/dashboard" style="margin:0;" onsubmit="return confirm('Padam pengumuman ini?');">
                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                <input type="hidden" name="announcement_action" value="delete_announcement">
                                                <input type="hidden" name="announcement_id" value="<%= annId %>">
                                                <button type="submit" class="btn btn-danger" style="padding:4px 10px; font-size:12px;">
                                                    <img src="${pageContext.request.contextPath}/assets/images/icon-delete.png" class="icon-btn" alt="Padam" style="width:12px;height:12px;" onerror="this.style.display='none'"> Padam
                                                </button>
                                            </form>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                        <p style="color:#888; font-size:13px; margin-bottom:14px;">Tiada pengumuman lagi. Tambah pengumuman pertama di bawah.</p>
                    <% } %>

                    <h4 style="margin: 0 0 10px; font-size:14px; color:#0b5e8f;">
                        <%= (request.getAttribute("announcement_editing") != null && !((Map<?,?>)request.getAttribute("announcement_editing")).isEmpty()) ? "&#9998; Kemaskini Pengumuman" : "&#43; Tambah Pengumuman Baharu" %>
                    </h4>

                    <%
                        Map<String, Object> announcementEditing = (Map<String, Object>) request.getAttribute("announcement_editing");
                        String announcementFormTitle = String.valueOf(request.getAttribute("announcement_form_title") == null ? "" : request.getAttribute("announcement_form_title"));
                        String announcementFormContent = String.valueOf(request.getAttribute("announcement_form_content") == null ? "" : request.getAttribute("announcement_form_content"));
                        Boolean announcementFormActive = (Boolean) request.getAttribute("announcement_form_active");
                        boolean formActive = announcementFormActive == null || announcementFormActive;

                        if (announcementEditing != null && !announcementEditing.isEmpty()) {
                            announcementFormTitle = String.valueOf(announcementEditing.get("title"));
                            announcementFormContent = String.valueOf(announcementEditing.get("content"));
                            formActive = Boolean.TRUE.equals(announcementEditing.get("is_active"));
                        }
                    %>

                    <form method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form" enctype="multipart/form-data" data-announcement-action="true">
                        <input type="hidden" name="_csrf" value="${csrf_token}">
                        <input type="hidden" name="announcement_action" value="<%= (announcementEditing != null && !announcementEditing.isEmpty()) ? "update_announcement" : "create_announcement" %>">
                        <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                            <input type="hidden" name="announcement_id" value="<%= announcementEditing.get("id") %>">
                        <% } %>
                        <%
                            String announcementImageUrl = String.valueOf(request.getAttribute("announcement_form_image_url") == null ? "" : request.getAttribute("announcement_form_image_url"));
                            if ((announcementImageUrl == null || announcementImageUrl.isBlank()) && announcementEditing != null && !announcementEditing.isEmpty()) {
                                announcementImageUrl = announcementEditing.get("image_url") == null ? "" : String.valueOf(announcementEditing.get("image_url"));
                            }
                            String announcementImageSrc = buildImageSrc(request.getContextPath(), announcementImageUrl);
                        %>
                        <input type="hidden" name="announcement_existing_image_url" value="<%= escapeHtml(announcementImageUrl) %>">

                        <div>
                            <label for="announcement_title"><strong>Tajuk</strong></label>
                            <input id="announcement_title" type="text" name="announcement_title" maxlength="180" required value="<%= escapeHtml(announcementFormTitle) %>">
                        </div>
                        <div>
                            <label for="announcement_content"><strong>Kandungan</strong></label>
                            <textarea id="announcement_content" name="announcement_content" required><%= escapeHtml(announcementFormContent) %></textarea>
                        </div>
                        <div>
                            <label for="announcement_image"><strong>Gambar (pilihan)</strong></label>
                            <input id="announcement_image" type="file" name="announcement_image" accept=".png,.jpg,.jpeg,.webp,image/png,image/jpeg,image/webp">
                            <% if (!announcementImageSrc.isBlank()) { %>
                                <div class="announce-image-preview">
                                    <img src="<%= escapeHtml(announcementImageSrc) %>" alt="Pratonton gambar pengumuman" onerror="this.style.display='none';">
                                </div>
                            <% } %>
                        </div>
                        <label style="display:flex;align-items:center;gap:8px;">
                            <input type="checkbox" name="announcement_active" <%= formActive ? "checked" : "" %>>
                            Aktifkan paparan di halaman utama
                        </label>
                        <div class="announcement-actions">
                            <button class="btn btn-primary" type="submit">
                                <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                                    <img src="${pageContext.request.contextPath}/assets/images/icon-edit.png" class="icon-btn" alt="Edit"> Kemas Kini
                                <% } else { %>
                                    <img src="${pageContext.request.contextPath}/assets/images/icon-add.png" class="icon-btn" alt="Tambah"> Tambah
                                <% } %>
                            </button>
                            <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard#announcementPanel" data-announcement-action="true">Batal</a>
                            <% } %>
                        </div>
                    </form>
                </div>
                </div>
            </div>
        </div>

        <div class="panel">
            <div class="jans-contact-section">
                <h3>Hubungi JANS</h3>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/address.png" alt="Alamat">
                    <span><strong>Alamat</strong><br>SABAH WATER DEPARTMENT / JABATAN AIR SABAH, Jalan Penampang, 88200 Kota Kinabalu, Sabah</span>
                </p>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/phone.png" alt="Telefon">
                    <span><strong>Telefon</strong><br>+60-88-232364 (HQ)</span>
                </p>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/fax.png" alt="Faks">
                    <span><strong>Faks</strong><br>+60-88-232396</span>
                </p>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/email.png" alt="E-mel">
                    <span><strong>E-mel</strong><br>jans.hq@sabah.gov.my</span>
                </p>
            </div>
        </div>
    </div>
    <div class="expand-overlay" id="expandOverlay" aria-hidden="true"></div>
    <div class="archive-toast" id="archiveToast" role="status" aria-live="polite">
        <img src="${pageContext.request.contextPath}/assets/images/icon-archive.png" alt="Notifikasi arkib" id="archiveToastIcon">
        <span id="archiveToastText">Berjaya.</span>
    </div>
<script>
    (function () {
        var pieChart = document.querySelector('.pie-chart[data-gradient]');
        if (pieChart && pieChart.dataset.gradient) {
            pieChart.style.background = pieChart.dataset.gradient;
        }
        
        var toolbarForm = document.querySelector('.toolbar');
        var exportButton = document.getElementById('exportDownloadBtn');
        var quickExportButton = document.getElementById('quickExportBtn');
        var exportOption = document.getElementById('exportOption');
        var searchInput = document.getElementById('q');
        var statusSelect = document.getElementById('status');
        var dateFromInput = document.getElementById('date_from');
        var dateToInput = document.getElementById('date_to');
        var selectAllApps = document.getElementById('selectAllApps');
        var appRowChecks = Array.prototype.slice.call(document.querySelectorAll('.app-row-check'));
        var bulkSelectedCount = document.getElementById('bulkSelectedCount');
        var bulkApproveBtn = document.getElementById('bulkApproveBtn');
        var bulkRejectBtn = document.getElementById('bulkRejectBtn');
        var bulkExportBtn = document.getElementById('bulkExportBtn');
        var bulkSelectedIds = document.getElementById('bulkSelectedIds');
        var bulkActionType = document.getElementById('bulkActionType');
        var bulkFirstId = document.getElementById('bulkFirstId');
        var bulkActionForm = document.getElementById('bulkActionForm');
        var layoutGrid = document.querySelector('.layout');
        var latestPanel = document.querySelector('.table-card');
        var toggleLatestPanelBtn = document.getElementById('toggleLatestPanelBtn');
        var announcementPanelCard = document.getElementById('announcementPanel');
        var toggleAnnouncementPanelBtn = document.getElementById('toggleAnnouncementPanelBtn');
        var expandOverlay = document.getElementById('expandOverlay');
        var archiveForms = Array.prototype.slice.call(document.querySelectorAll('.js-archive-form'));
        var archiveToast = document.getElementById('archiveToast');
        var archiveToastIcon = document.getElementById('archiveToastIcon');
        var archiveToastText = document.getElementById('archiveToastText');
        var toastTimer = null;

        var appDetailModal = document.getElementById('appDetailModal');
        var appModalCloseBtn = document.getElementById('appModalCloseBtn');
        var modalReviewLink = document.getElementById('modalReviewLink');
        var modalAttachmentViewer = document.getElementById('modalAttachmentViewer');
        var userRoleClient = '<%= String.valueOf(session.getAttribute("role")) %>';
        var isAdminRoleClient = userRoleClient === 'ADMIN';

        var contextPath = '<%= request.getContextPath() %>';

        function statusForSelection(optionValue) {
            if (optionValue === 'xlsx_approved' || optionValue === 'pdf_approved') {
                return 'APPROVED';
            }
            if (optionValue === 'xlsx_rejected' || optionValue === 'pdf_rejected') {
                return 'REJECTED';
            }
            return statusSelect.value || '';
        }

        function formatForSelection(optionValue) {
            return optionValue.indexOf('pdf_') === 0 ? 'pdf' : 'xlsx';
        }

        function runExport() {
            var optionValue = exportOption.value;
            var format = formatForSelection(optionValue);
            var status = statusForSelection(optionValue);
            var q = searchInput.value || '';
            var dateFrom = dateFromInput ? (dateFromInput.value || '') : '';
            var dateTo = dateToInput ? (dateToInput.value || '') : '';
            var url = contextPath + '/admin/export?format=' + encodeURIComponent(format)
                + '&q=' + encodeURIComponent(q)
                + '&status=' + encodeURIComponent(status)
                + '&date_from=' + encodeURIComponent(dateFrom)
                + '&date_to=' + encodeURIComponent(dateTo);
            window.location.href = url;
        }

        function setExpandState(button, expanded) {
            if (!button) {
                return;
            }
            button.setAttribute('aria-expanded', expanded ? 'true' : 'false');
            button.setAttribute('title', expanded ? 'Kecilkan panel' : 'Besarkan panel');
        }

        function showArchiveToast(message, iconUrl) {
            if (!archiveToast || !archiveToastText || !archiveToastIcon) {
                return;
            }
            archiveToastText.textContent = message;
            if (iconUrl) {
                archiveToastIcon.src = iconUrl;
            }
            archiveToast.classList.add('show');
            if (toastTimer) {
                clearTimeout(toastTimer);
            }
            toastTimer = setTimeout(function() {
                archiveToast.classList.remove('show');
            }, 2100);
        }

        function updateArchiveRowUi(form, actionValue) {
            if (!form) {
                return;
            }
            var row = form.closest('tr');
            if (!row) {
                return;
            }

            var statusCell = row.querySelector('.status-pill');
            var actionInput = form.querySelector('input[name="action"]');
            var button = form.querySelector('button.btn-archive');
            var icon = button ? button.querySelector('img') : null;

            if (actionValue === 'archive') {
                if (statusCell) {
                    statusCell.className = 'status-pill status-archived';
                    statusCell.textContent = 'ARCHIVED';
                }
                if (actionInput) {
                    actionInput.value = 'unarchive';
                }
                if (button) {
                    button.title = 'Buka Arkib';
                    button.setAttribute('aria-label', 'Buka Arkib');
                }
                if (icon) {
                    icon.src = contextPath + '/assets/images/icon-unarchive.png';
                }
                return;
            }

            // For unarchive, remove row from archived view (or fallback to reload if row cannot be removed safely)
            if (statusSelect && statusSelect.value === 'ARCHIVED') {
                row.remove();
                var remainingRows = toolbarForm ? document.querySelectorAll('tbody tr').length : 0;
                if (remainingRows === 0) {
                    window.location.reload();
                }
                return;
            }

            window.location.reload();
        }

        function closeExpandPopup() {
            if (latestPanel) {
                latestPanel.classList.remove('popup-active');
            }
            if (announcementPanelCard) {
                announcementPanelCard.classList.remove('popup-active');
            }
            document.body.classList.remove('popup-open');
            setExpandState(toggleLatestPanelBtn, false);
            setExpandState(toggleAnnouncementPanelBtn, false);
        }

        function openExpandPopup(panelElement) {
            if (!panelElement) {
                return;
            }
            if (latestPanel && panelElement !== latestPanel) {
                latestPanel.classList.remove('popup-active');
            }
            if (announcementPanelCard && panelElement !== announcementPanelCard) {
                announcementPanelCard.classList.remove('popup-active');
            }

            panelElement.classList.add('popup-active');
            document.body.classList.add('popup-open');
            setExpandState(toggleLatestPanelBtn, panelElement === latestPanel);
            setExpandState(toggleAnnouncementPanelBtn, panelElement === announcementPanelCard);
        }

        if (toggleLatestPanelBtn && layoutGrid && latestPanel) {
            setExpandState(toggleLatestPanelBtn, false);
            toggleLatestPanelBtn.addEventListener('click', function() {
                var isOpen = latestPanel.classList.contains('popup-active') && document.body.classList.contains('popup-open');
                if (isOpen) {
                    closeExpandPopup();
                    return;
                }
                openExpandPopup(latestPanel);
            });
        }

        if (toggleAnnouncementPanelBtn && layoutGrid && announcementPanelCard) {
            setExpandState(toggleAnnouncementPanelBtn, false);
            toggleAnnouncementPanelBtn.addEventListener('click', function() {
                var isOpen = announcementPanelCard.classList.contains('popup-active') && document.body.classList.contains('popup-open');
                if (isOpen) {
                    closeExpandPopup();
                    return;
                }
                openExpandPopup(announcementPanelCard);
            });
        }

        if (expandOverlay) {
            expandOverlay.addEventListener('click', function() {
                closeExpandPopup();
            });
        }

        document.addEventListener('click', function (event) {
            var archiveBtn = event.target.closest('.js-archive-btn');
            if (!archiveBtn) {
                return;
            }

            doArchive(
                archiveBtn.dataset.appId || '',
                archiveBtn.dataset.action || '',
                archiveBtn.dataset.confirm || 'Teruskan?',
                archiveBtn.dataset.csrf || '',
                archiveBtn.dataset.ctx || ''
            );
        });

        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape' && document.body.classList.contains('popup-open')) {
                closeExpandPopup();
            }
        });

        if (exportButton) {
            exportButton.addEventListener('click', function(e) {
                e.preventDefault();
                runExport();
            });
        }

        if (quickExportButton) {
            quickExportButton.addEventListener('click', function(e) {
                e.preventDefault();
                runExport();
            });
        }
    })();

    function doArchive(appId, actionValue, confirmText, csrfToken, ctxPath) {
        if (!window.confirm(confirmText)) { return; }
        var body = 'id=' + encodeURIComponent(appId) +
                   '&action=' + encodeURIComponent(actionValue) +
                   '&ajax=1' +
                   '&_csrf=' + encodeURIComponent(csrfToken);
        fetch(ctxPath + '/admin/application', {
            method: 'POST',
            credentials: 'same-origin',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-Token': csrfToken
            },
            body: body
        }).then(function(resp) {
            if (resp.ok) {
                window.location.reload();
            } else {
                resp.text().then(function(t) { alert('Gagal: ' + resp.status + ' ' + t.substring(0, 200)); });
            }
        }).catch(function(err) { alert('Ralat rangkaian: ' + err); });
    }
</script>
</body>
</html>
