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
        :root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
            --surface: #ffffff;
            --surface-soft: #f7fbff;
            --line: #d9e7f1;
            --text: #183244;
            --muted: #637d8d;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(180deg, #f4fbff 0%, #f9fcfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-yellow) 100%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 54px; height: 54px; border-radius: 16px; object-fit: contain; padding: 4px; }
        .brand h1 { margin: 0; font-size: 20px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px; }
        .icon-inline { width: 14px; height: 14px; object-fit: contain; vertical-align: middle; }
        .container { max-width: 1320px; margin: 28px auto; padding: 0 20px 32px; }
        .hero { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 20px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; max-width: 760px; }
        .metric-strip { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .metric-chip { background: var(--surface-soft); border: 1px solid var(--line); padding: 10px 14px; border-radius: 999px; font-weight: 700; }
        .jans-contact-section { background: linear-gradient(135deg,rgba(240,248,255,0.5) 0%,rgba(220,240,255,0.35) 100%); border: 1px solid rgba(42,157,143,0.24); border-radius: 16px; padding: 24px 28px; margin-top: 28px; }
        .jans-contact-section h3 { color: #0F6BAE; font-size: 16px; font-weight: 700; margin: 0 0 14px; letter-spacing: 0.3px; }
        .contact-line { display: flex; align-items: flex-start; gap: 10px; margin: 8px 0; font-size: 14px; color: #334155; }
        .contact-icon { width: 18px; height: 18px; object-fit: contain; flex-shrink: 0; margin-top: 2px; }
        .contact-address-link { color: #0F6BAE; text-decoration: underline; text-underline-offset: 3px; font-weight: 600; }
        .contact-address-link:hover { color: #0d4f77; }
        .stats { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 16px; margin-bottom: 20px; }
        .stat-card { background: var(--surface); padding: 18px; border-radius: 18px; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        .stat-card .number { font-size: 30px; font-weight: 800; color: var(--brand-navy); }
        .layout { display: grid; grid-template-columns: 1.9fr 1fr; gap: 20px; }
        .toolbar { display: grid; grid-template-columns: minmax(240px, 2fr) minmax(160px, 1fr) auto minmax(280px, 1.6fr) auto; gap: 12px; align-items: end; margin-bottom: 16px; }
        .export-control { min-width: 0; }
        .export-help { margin-top: 6px; font-size: 12px; color: var(--muted); }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); }
        .btn { padding: 11px 15px; border-radius: 12px; border: 1px solid #fff; text-decoration: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .btn-accent { background: #fff7b0; color: #6a5a00; }
        .section-stack { display: grid; gap: 18px; }
        .announcement-panel { border-top: 4px solid var(--brand-blue); }
        .announcement-head { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
        .announcement-head img { width: 18px; height: 18px; object-fit: contain; }
        .announce-alert { margin-bottom: 12px; border-radius: 10px; padding: 10px 12px; font-size: 13px; }
        .announce-success { background: #e7f9ec; color: #166534; border: 1px solid #b8e7c6; }
        .announce-error { background: #fff1f2; color: #b91c1c; border: 1px solid #fecdd3; }
        .announce-with-gif { display: flex; align-items: center; gap: 10px; }
        .success-popup {
            position: fixed;
            top: 50%;
            left: 50%;
            z-index: 1300;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 16px;
            min-width: 280px;
            max-width: min(94vw, 420px);
            padding: 28px 24px;
            border-radius: 16px;
            border: 1px solid #b8e7c6;
            background: #ffffff;
            color: #166534;
            font-size: 16px;
            line-height: 1.35;
            box-shadow: 0 16px 32px rgba(10, 64, 38, 0.2);
            transform: translate(-50%, -58%) scale(0.97);
            opacity: 0;
            pointer-events: none;
            transition: transform 0.22s ease, opacity 0.22s ease;
        }
        .success-popup.show {
            transform: translate(-50%, -50%) scale(1);
            opacity: 1;
            pointer-events: auto;
        }
        .success-popup-content { display: flex; flex-direction: column; gap: 8px; align-items: center; }
        .success-title { font-size: 22px; line-height: 1.1; font-weight: 800; color: #0f5132; letter-spacing: 0.02em; text-transform: none; text-align: center; }
        .success-text { display: none; }
        .success-ok { align-self: center; margin-top: 4px; border: 1px solid #0f5132 !important; background: #166534; color: #fff; border-radius: 10px; padding: 10px 24px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .success-gif {
            width: 84px;
            height: 84px;
            padding: 0;
            object-fit: contain;
            flex-shrink: 0;
            background: transparent;
            border-radius: 0;
            border: none;
            mix-blend-mode: normal;
            filter: drop-shadow(0 3px 8px rgba(22, 101, 52, 0.22)) saturate(1.05);
            transform-origin: center;
            animation: successGifPop 420ms ease-out 1, successGifPulse 1.9s ease-in-out infinite 520ms;
        }
        @keyframes successGifPop {
            0% { transform: scale(0.72) translateY(3px); opacity: 0.65; }
            70% { transform: scale(1.14) translateY(-1px); opacity: 1; }
            100% { transform: scale(1); opacity: 1; }
        }
        @keyframes successGifPulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.06); }
        }
        .announcement-form { display: grid; gap: 10px; margin-bottom: 14px; }
        .announcement-form input[type="text"], .announcement-form textarea { width: 100%; border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px; font: inherit; }
        .announcement-form input[type="file"] { width: 100%; border: 1px dashed var(--line); border-radius: 10px; padding: 10px 12px; font: inherit; background: #f9fcff; }
        .announcement-form textarea { min-height: 96px; resize: vertical; }
        .announce-image-preview { margin-top: 8px; }
        .announce-image-preview img { width: 100%; max-width: 220px; height: auto; border: 1px solid var(--line); border-radius: 10px; }
        .announcement-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .announcement-table td { font-size: 13px; }
        .announce-title { font-weight: 700; color: var(--brand-navy); }
        .announce-content { color: var(--muted); margin-top: 4px; white-space: pre-wrap; }
        .announce-status { display: inline-block; border-radius: 999px; padding: 4px 10px; font-size: 11px; font-weight: 700; }
        .announce-active { background: #dcfce7; color: #166534; }
        .announce-inactive { background: #e2e8f0; color: #334155; }
        .icon-btn { width: 14px; height: 14px; object-fit: contain; }
        .table-card h3 { margin-top: 0; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 13px 12px; border-bottom: 1px solid #e4edf4; text-align: left; vertical-align: top; }
        th { background: #f8fcff; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        tr:hover { background: #f7fcff; }
        .status-pill { display: inline-block; padding: 5px 12px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .status-pending { background: #fff3cd; color: #9a6700; }
        .status-approved { background: #dcfce7; color: #166534; }
        .status-rejected { background: #fee2e2; color: #b91c1c; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .status-draft { background: #e2e8f0; color: #334155; }
        .subtle { color: var(--muted); font-size: 13px; }
        .empty { text-align: center; color: var(--muted); padding: 26px 0; }
        .section-title { margin-top: 0; margin-bottom: 14px; }
        @media (max-width: 1100px) { .hero, .layout, .stats, .toolbar { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; } .navbar a { margin-left: 0; margin-right: 16px; } }
                    /* Enforce visible white border on all clickable buttons */
        button,
        input[type="submit"],
        input[type="button"],
        .btn,
        .login-btn,
        .modal-close,
        .btn-attachment,
        .attachment-list button,
        a.btn {
            border: 1px solid #fff !important;
            box-shadow: inset 0 0 0 1px #fff, 0 1px 2px rgba(0, 0, 0, 0.18) !important;
        }

        button:hover,
        input[type="submit"]:hover,
        input[type="button"]:hover,
        .btn:hover,
        .login-btn:hover,
        .modal-close:hover,
        .btn-attachment:hover,
        .attachment-list button:hover,
        a.btn:hover,
        button:focus,
        input[type="submit"]:focus,
        input[type="button"]:focus,
        .btn:focus,
        .login-btn:focus,
        .modal-close:focus,
        .btn-attachment:focus,
        .attachment-list button:focus,
        a.btn:focus {
            border: 1px solid #fff !important;
            box-shadow: inset 0 0 0 1px #fff, 0 0 0 2px rgba(255, 255, 255, 0.35), 0 1px 2px rgba(0, 0, 0, 0.18) !important;
        }
        .icon-link { width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.38); transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 4px; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: rgba(255,255,255,0.26); }
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
            <div class="stat-card">
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
        </div>

        <div class="layout">
            <div class="panel table-card">
                <h3 class="section-title">Permohonan Terkini</h3>
                <form method="get" action="${pageContext.request.contextPath}/dashboard" class="toolbar">
                    <div class="field">
                        <label for="q"><img src="${pageContext.request.contextPath}/assets/images/icon-search.png" class="icon-inline" alt="Ikon carian"> Carian</label>
                        <input id="q" name="q" type="text" value="<%= request.getAttribute("search_query") %>" placeholder="Cari syarikat, produk, pemohon atau email">
                    </div>
                    <div class="field">
                        <label for="status">Status</label>
                        <select id="status" name="status">
                            <option value="">Semua status</option>
                            <option value="PENDING" <%= "PENDING".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>PENDING</option>
                            <option value="APPROVED" <%= "APPROVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>APPROVED</option>
                            <option value="REJECTED" <%= "REJECTED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>REJECTED</option>
                            <option value="SUSPENDED" <%= "SUSPENDED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>SUSPENDED</option>
                            <option value="DRAFT" <%= "DRAFT".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DRAFT</option>
                        </select>
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

                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nama Syarikat</th>
                            <th>Kategori Produk</th>
                            <th>Status</th>
                            <th>Tarikh Penghantaran</th>
                            <th>Tindakan</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            List<Map<String, Object>> applications = (List<Map<String, Object>>) request.getAttribute("pending_applications");
                            if (applications == null || applications.isEmpty()) {
                        %>
                        <tr>
                            <td colspan="6" class="empty">Tiada permohonan ditemui untuk penapis ini.</td>
                        </tr>
                        <% } else {
                            for (Map<String, Object> applicationRow : applications) {
                                Timestamp submittedAt = (Timestamp) applicationRow.get("submitted_at");
                                String status = String.valueOf(applicationRow.get("status")).toLowerCase();
                        %>
                        <tr>
                            <td><strong><%= String.format("PPP%03d", ((Number)applicationRow.get("id")).intValue()) %></strong></td>
                            <td>
                                <strong><%= applicationRow.get("company_name") %></strong><br>
                                <span class="subtle">Pemohon: <%= applicationRow.get("full_name") %><br>Email: <%= applicationRow.get("user_email") %></span>
                            </td>
                            <td>
                                <strong><%= applicationRow.get("product_category") %></strong><br>
                                <span class="subtle"><%= applicationRow.get("product_name") %></span>
                            </td>
                            <td><span class="status-pill status-<%= status %>"><%= applicationRow.get("status") %></span></td>
                            <td><%= submittedAt != null ? submittedAt.toString() : "Belum dihantar" %></td>
                            <td>
                                <a class="btn btn-primary" href="${pageContext.request.contextPath}/admin/application?id=<%= applicationRow.get("id") %>">Semak</a>
                            </td>
                        </tr>
                        <%      }
                           }
                        %>
                    </tbody>
                </table>
            </div>

            <div>
                <div class="section-stack">
                <div class="panel">
                    <h3 class="section-title">Pratonton Produk MySQL</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>No.</th>
                                <th>Produk</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> products = (List<Map<String, Object>>) request.getAttribute("product_catalog");
                                if (products == null || products.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="2" class="empty">Tiada produk ditemui.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> product : products) {
                            %>
                            <tr>
                                <td><%= product.get("no") %></td>
                                <td>
                                    <strong><%= product.get("product_materials") %></strong><br>
                                    <span class="subtle"><%= product.get("brand") == null ? "-" : product.get("brand") %> • <%= product.get("classification") %></span>
                                </td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                    <div style="margin-top:16px;">
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/products">Buka Senarai Produk Penuh</a>
                    </div>
                </div>

                <div class="panel announcement-panel" id="announcementPanel">
                    <div class="announcement-head">
                        <img src="${pageContext.request.contextPath}/assets/images/icon-announcement.png" alt="Pengumuman">
                        <h3 class="section-title" style="margin:0;">Pengurusan Pengumuman / Info</h3>
                    </div>

                    <% if (request.getAttribute("announcement_success") != null) { %>
                        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
                            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
                            <div class="success-popup-content">
                                <div class="success-title">Berjaya!</div>
                                <div class="success-text"></div>
                                <button type="button" class="success-ok" data-close-success-popup>OK</button>
                            </div>
                        </div>
                    <% } %>
                    <% if (request.getAttribute("announcement_error") != null) { %>
                        <div class="announce-alert announce-error"><%= request.getAttribute("announcement_error") %></div>
                    <% } %>

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

                    <table class="announcement-table">
                        <thead>
                            <tr>
                                <th>Pengumuman</th>
                                <th>Status</th>
                                <th>Tindakan</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> announcements = (List<Map<String, Object>>) request.getAttribute("announcements");
                                if (announcements == null || announcements.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="3" class="empty">Belum ada pengumuman direkodkan.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> ann : announcements) {
                                    String listAnnouncementImageSrc = buildImageSrc(request.getContextPath(), ann.get("image_url"));
                            %>
                            <tr>
                                <td>
                                    <div class="announce-title"><%= escapeHtml(String.valueOf(ann.get("title"))) %></div>
                                    <% if (!listAnnouncementImageSrc.isBlank()) { %>
                                        <div class="announce-image-preview" style="margin-top:6px;margin-bottom:6px;">
                                            <img src="<%= escapeHtml(listAnnouncementImageSrc) %>" alt="Gambar pengumuman" onerror="this.style.display='none';">
                                        </div>
                                    <% } %>
                                    <div class="announce-content"><%= escapeHtml(String.valueOf(ann.get("content"))) %></div>
                                </td>
                                <td>
                                    <span class="announce-status <%= Boolean.TRUE.equals(ann.get("is_active")) ? "announce-active" : "announce-inactive" %>">
                                        <%= Boolean.TRUE.equals(ann.get("is_active")) ? "AKTIF" : "TIDAK AKTIF" %>
                                    </span>
                                </td>
                                <td>
                                    <div class="announcement-actions">
                                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard?announcement_id=<%= ann.get("id") %>#announcementPanel" data-announcement-action="true">
                                            <img src="${pageContext.request.contextPath}/assets/images/icon-edit.png" class="icon-btn" alt="Edit"> Edit
                                        </a>
                                        <form method="post" action="${pageContext.request.contextPath}/dashboard" onsubmit="return confirm('Hapus pengumuman ini?');" style="margin:0;" data-announcement-action="true">
                                            <input type="hidden" name="_csrf" value="${csrf_token}">
                                            <input type="hidden" name="announcement_action" value="delete_announcement">
                                            <input type="hidden" name="announcement_id" value="<%= ann.get("id") %>">
                                            <button class="btn btn-accent" type="submit">
                                                <img src="${pageContext.request.contextPath}/assets/images/icon-delete.png" class="icon-btn" alt="Hapus"> Hapus
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                </div>

                <div class="panel">
                    <h3 class="section-title">Senarai Pengguna Berdaftar</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Nama</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Tarikh Daftar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> registeredUsers = (List<Map<String, Object>>) request.getAttribute("registered_users_list");
                                if (registeredUsers == null || registeredUsers.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="4" class="empty">Tiada pengguna berdaftar.</td>
                            </tr>
                            <% } else {
                                int shown = 0;
                                for (Map<String, Object> userRow : registeredUsers) {
                                    if (shown >= 8) {
                                        break;
                                    }
                                    shown++;
                            %>
                            <tr>
                                <td>
                                    <strong><%= escapeHtml(String.valueOf(userRow.get("full_name"))) %></strong><br>
                                    <span class="subtle">@<%= escapeHtml(String.valueOf(userRow.get("username"))) %></span>
                                </td>
                                <td><%= escapeHtml(String.valueOf(userRow.get("email"))) %></td>
                                <td><span class="status-pill status-<%= String.valueOf(userRow.get("status")).toLowerCase() %>"><%= escapeHtml(String.valueOf(userRow.get("status"))) %></span></td>
                                <td><%= userRow.get("created_at") == null ? "-" : escapeHtml(String.valueOf(userRow.get("created_at"))) %></td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                    <div style="margin-top:12px;display:flex;gap:8px;flex-wrap:wrap;">
                        <a class="btn btn-primary" href="${pageContext.request.contextPath}/admin/users">Urus Pengguna</a>
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/export?format=xlsx&scope=users">Eksport Excel</a>
                        <a class="btn btn-accent" href="${pageContext.request.contextPath}/admin/export?format=pdf&scope=users">Eksport PDF</a>
                    </div>
                </div>

                <div class="panel">
                    <h3 class="section-title">Pengguna Baharu (30 Hari)</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Nama</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Tarikh Daftar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> newUsers = (List<Map<String, Object>>) request.getAttribute("new_registered_users_list");
                                if (newUsers == null || newUsers.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="4" class="empty">Tiada pengguna baharu dalam tempoh 30 hari.</td>
                            </tr>
                            <% } else {
                                int shownRecent = 0;
                                for (Map<String, Object> userRow : newUsers) {
                                    if (shownRecent >= 8) {
                                        break;
                                    }
                                    shownRecent++;
                            %>
                            <tr>
                                <td>
                                    <strong><%= escapeHtml(String.valueOf(userRow.get("full_name"))) %></strong><br>
                                    <span class="subtle">@<%= escapeHtml(String.valueOf(userRow.get("username"))) %></span>
                                </td>
                                <td><%= escapeHtml(String.valueOf(userRow.get("email"))) %></td>
                                <td><span class="status-pill status-<%= String.valueOf(userRow.get("status")).toLowerCase() %>"><%= escapeHtml(String.valueOf(userRow.get("status"))) %></span></td>
                                <td><%= userRow.get("created_at") == null ? "-" : escapeHtml(String.valueOf(userRow.get("created_at"))) %></td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                    <div style="margin-top:12px;display:flex;gap:8px;flex-wrap:wrap;">
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/export?format=xlsx&scope=users&recent=1">Eksport Excel (30 Hari)</a>
                        <a class="btn btn-accent" href="${pageContext.request.contextPath}/admin/export?format=pdf&scope=users&recent=1">Eksport PDF (30 Hari)</a>
                    </div>
                </div>
                </div>
            </div>
        </div>

        <div class="panel">
            <div class="jans-contact-section">
                <h3>&#128222; Hubungi JANS</h3>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/address.png" alt="Alamat">
                    <a class="contact-address-link" href="https://www.bing.com/maps/directions?FORM=HDRSC6&style=r&rtp=%7Epos.5.981967926025391_116.12310028076172_Kota%2520Kinabalu%252C%2520Sabah%252088825_Kota%2520Kinabalu%252C%2520Sabah%252088825_&cp=5.981892%7E116.123260&lvl=20.8" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT / JABATAN AIR SABAH, Jalan Penampang, 88200 Kota Kinabalu, Sabah</a>
                </p>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/phone.png" alt="Telefon">
                    <span>+60-88-232364 (HQ)</span>
                </p>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/fax.png" alt="Faks">
                    <span>+60-88-232396</span>
                </p>
                <p class="contact-line">
                    <img class="contact-icon" src="${pageContext.request.contextPath}/assets/images/email.png" alt="E-mel">
                    <span>jans.hq@sabah.gov.my</span>
                </p>
            </div>
        </div>
    </div>
<script>
    (function () {
        var toolbarForm = document.querySelector('.toolbar');
        var exportButton = document.getElementById('exportDownloadBtn');
        var exportOption = document.getElementById('exportOption');
        var searchInput = document.getElementById('q');
        var statusSelect = document.getElementById('status');

        if (!toolbarForm || !exportButton || !exportOption || !searchInput || !statusSelect) {
            return;
        }

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

        exportButton.addEventListener('click', function () {
            var optionValue = exportOption.value;
            var format = formatForSelection(optionValue);
            var status = statusForSelection(optionValue);
            var q = searchInput.value || '';
            var url = contextPath + '/admin/export?format=' + encodeURIComponent(format)
                + '&q=' + encodeURIComponent(q)
                + '&status=' + encodeURIComponent(status);
            window.location.href = url;
        });
    })();
</script>
<script>
(function() {
    var announcementPanel = document.getElementById('announcementPanel');
    if (announcementPanel) {
        var scrollStateKey = 'adminDashboardAnnouncementFocus';

        function markAnnouncementFocus() {
            try {
                sessionStorage.setItem(scrollStateKey, '1');
            } catch (e) {
                // Ignore storage errors and continue normal flow.
            }
        }

        if (window.location.hash === '#announcementPanel') {
            announcementPanel.scrollIntoView({ behavior: 'auto', block: 'start' });
        }

        try {
            if (sessionStorage.getItem(scrollStateKey) === '1') {
                announcementPanel.scrollIntoView({ behavior: 'auto', block: 'start' });
                sessionStorage.removeItem(scrollStateKey);
            }
        } catch (e) {
            // Ignore storage errors and continue normal flow.
        }

        var announcementTriggers = announcementPanel.querySelectorAll('[data-announcement-action="true"]');
        announcementTriggers.forEach(function(trigger) {
            if (trigger.tagName === 'FORM') {
                trigger.addEventListener('submit', markAnnouncementFocus);
            } else {
                trigger.addEventListener('click', markAnnouncementFocus);
            }
        });
    }

    var popup = document.getElementById('successPopup');
    if (!popup) return;
    function closePopup() {
        popup.classList.remove('show');
        window.setTimeout(function() {
            if (popup && popup.parentNode) popup.parentNode.removeChild(popup);
        }, 260);
    }
    var closeBtn = popup.querySelector('[data-close-success-popup]');
    if (closeBtn) closeBtn.addEventListener('click', closePopup);
})();
</script>

</body>
</html>
