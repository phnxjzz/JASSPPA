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
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Pentadbir - SPPA</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');
        :root {
            --brand-blue: #0d5c8f;
            --brand-navy: #08334d;
            --brand-gold: #e7bf56;
            --surface: #ffffff;
            --surface-soft: #f3f8fc;
            --line: #d4e1ec;
            --text: #1a3040;
            --muted: #5d7484;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif; background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(180deg, var(--brand-navy) 0%, #0c4569 100%); border-bottom: 3px solid var(--brand-gold); color: white; padding: 14px 26px; display: flex; justify-content: space-between; align-items: center; gap: 20px; box-shadow: 0 12px 28px rgba(8, 51, 77, 0.2); }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 52px; height: 52px; object-fit: contain; }
        .brand h1 { margin: 0; font-size: 21px; letter-spacing: 0.02em; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; }
        .navbar a { color: white; text-decoration: none; margin-left: 10px; font-weight: 700; display: inline-flex; align-items: center; gap: 6px; padding: 8px 11px; border-radius: 8px; transition: background 0.18s ease; }
        .navbar a:hover { background: rgba(255,255,255,0.14); }
        .icon-inline { width: 16px; height: 16px; object-fit: contain; vertical-align: middle; }
        .nav-dropdown { position: relative; display: inline-flex; align-items: center; margin-left: 10px; }
        .nav-dropdown-btn { background: transparent; border: none !important; box-shadow: none !important; color: white; font-weight: 700; font-family: inherit; font-size: 1em; cursor: pointer; padding: 8px 11px; border-radius: 8px; display: flex; align-items: center; gap: 4px; }
        .nav-dropdown-btn:hover { background: rgba(255,255,255,0.14); }
        .nav-dropdown-menu { display: none; position: absolute; top: 100%; right: 0; background: white; border-radius: 10px; box-shadow: 0 12px 28px rgba(6,52,79,0.18); min-width: 190px; z-index: 100; overflow: hidden; margin-top: 4px; }
        .nav-dropdown-menu a { display: block; padding: 10px 16px; color: #06344f !important; text-decoration: none; font-weight: 700; margin-left: 0 !important; border-bottom: 1px solid #e4edf4; }
        .nav-dropdown-menu a:last-child { border-bottom: none; }
        .nav-dropdown-menu a:hover { background: #eef5fb; }
        .nav-dropdown:hover .nav-dropdown-menu,
        .nav-dropdown:focus-within .nav-dropdown-menu { display: block; }
        .container { max-width: 1320px; margin: 28px auto; padding: 0 20px 32px; }
        .hero { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 14px; box-shadow: 0 8px 26px rgba(9, 53, 79, 0.07); padding: 20px; }
        .hero h2 { margin-top: 0; font-size: 28px; color: #103d58; }
        .hero p { color: var(--muted); line-height: 1.7; max-width: 760px; }
        .metric-strip { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .metric-chip { background: var(--surface-soft); border: 1px solid #cbd9e4; padding: 9px 13px; border-radius: 999px; font-weight: 700; color: #17425f; }
        .stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 14px; margin-bottom: 20px; }
        .stat-card { background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%); padding: 18px; border-radius: 14px; border: 1px solid #d3e1ed; box-shadow: 0 8px 22px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: #557286; }
        .stat-card .number { font-size: 30px; font-weight: 800; color: var(--brand-navy); }
        .stat-bar { margin-top: 10px; height: 6px; border-radius: 999px; background: #dde8f0; overflow: hidden; }
        .stat-bar-fill { height: 100%; border-radius: 999px; }
        .layout { display: grid; grid-template-columns: 1.9fr 1fr; gap: 20px; }
        .toolbar { display: grid; grid-template-columns: minmax(200px, 2fr) minmax(140px, 1fr) minmax(130px, 1fr) minmax(130px, 1fr) auto minmax(240px, 1.5fr) auto; gap: 10px; align-items: end; margin-bottom: 16px; }
        .export-control { min-width: 0; }
        .export-help { margin-top: 6px; font-size: 12px; color: var(--muted); }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); }
        .btn { padding: 11px 15px; border-radius: 10px; border: 1px solid #fff; text-decoration: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: transform 0.16s ease, box-shadow 0.16s ease; }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(9,53,79,0.16); }
        .btn-primary { background: linear-gradient(180deg, #0f6fa8 0%, #0d5c8f 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
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
        th, td { padding: 12px 12px; border-bottom: 1px solid #e2ebf2; text-align: left; vertical-align: top; }
        th { background: #f1f6fb; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: #547288; }
        tr:hover { background: #f5f9fc; }
        .status-pill { display: inline-block; padding: 5px 12px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .status-pending { background: #fff3cd; color: #9a6700; }
        .status-approved { background: #dcfce7; color: #166534; }
        .status-rejected { background: #fee2e2; color: #b91c1c; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .status-draft { background: #e2e8f0; color: #334155; }
        .status-archived { background: #ede9fe; color: #5b21b6; }
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
        </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
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
            <div class="nav-dropdown">
                <button class="nav-dropdown-btn">Kemas Kini Profil &#9662;</button>
                <div class="nav-dropdown-menu">
                    <a href="#tetapan-admin">Tetapan</a>
                    <a href="${pageContext.request.contextPath}/profile">Kemas Kini Portal</a>
                </div>
            </div>
            <a href="${pageContext.request.contextPath}/logout" aria-label="Keluar" title="Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" class="icon-inline" alt="Ikon keluar"></a>
        </div>
    </div>

    <div class="container">
        <div class="stats">
            <%
                int totApp = request.getAttribute("total_applications") != null ? (int) request.getAttribute("total_applications") : 0;
                int pendCount = request.getAttribute("pending_count") != null ? (int) request.getAttribute("pending_count") : 0;
                int appCount = request.getAttribute("approved_count") != null ? (int) request.getAttribute("approved_count") : 0;
                int rejCount = request.getAttribute("rejected_count") != null ? (int) request.getAttribute("rejected_count") : 0;
                int suspCount = request.getAttribute("suspended_count") != null ? (int) request.getAttribute("suspended_count") : 0;
                int draftCount = request.getAttribute("draft_count") != null ? (int) request.getAttribute("draft_count") : 0;
                int archCount = request.getAttribute("archived_count") != null ? (int) request.getAttribute("archived_count") : 0;
                int activeUsers = request.getAttribute("active_users") != null ? (int) request.getAttribute("active_users") : 0;
                int denom = totApp > 0 ? totApp : 1;
            %>
            <div class="stat-card">
                <h3>Jumlah Permohonan</h3>
                <div class="number"><%= totApp %></div>
            </div>
            <div class="stat-card">
                <h3>Menunggu</h3>
                <div class="number" style="color:#9a6700;"><%= pendCount %></div>
                <div class="stat-bar"><div class="stat-bar-fill" style="width:<%= pendCount*100/denom %>%;background:#e9a21b;"></div></div>
            </div>
            <div class="stat-card">
                <h3>Diluluskan</h3>
                <div class="number" style="color:#166534;"><%= appCount %></div>
                <div class="stat-bar"><div class="stat-bar-fill" style="width:<%= appCount*100/denom %>%;background:#22c55e;"></div></div>
            </div>
            <div class="stat-card">
                <h3>Ditolak</h3>
                <div class="number" style="color:#b91c1c;"><%= rejCount %></div>
                <div class="stat-bar"><div class="stat-bar-fill" style="width:<%= rejCount*100/denom %>%;background:#ef4444;"></div></div>
            </div>
            <div class="stat-card">
                <h3>Digantung</h3>
                <div class="number" style="color:#9a3412;"><%= suspCount %></div>
                <div class="stat-bar"><div class="stat-bar-fill" style="width:<%= suspCount*100/denom %>%;background:#f97316;"></div></div>
            </div>
            <div class="stat-card">
                <h3>Draf</h3>
                <div class="number" style="color:#475569;"><%= draftCount %></div>
                <div class="stat-bar"><div class="stat-bar-fill" style="width:<%= draftCount*100/denom %>%;background:#94a3b8;"></div></div>
            </div>
            <div class="stat-card">
                <h3>Diarkib</h3>
                <div class="number" style="color:#5b21b6;"><%= archCount %></div>
            </div>
            <div class="stat-card">
                <h3>Pengguna Aktif</h3>
                <div class="number" style="color:#0369a1;"><%= activeUsers %></div>
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
                            <option value="ARCHIVED" <%= "ARCHIVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>ARCHIVED</option>
                        </select>
                    </div>
                    <div class="field">
                        <label for="date_from">Dari Tarikh</label>
                        <input id="date_from" name="date_from" type="date" value="<%= request.getAttribute("date_from") != null ? request.getAttribute("date_from") : "" %>">
                    </div>
                    <div class="field">
                        <label for="date_to">Hingga Tarikh</label>
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
                            <td><strong>#<%= applicationRow.get("id") %></strong></td>
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
                                    <span class="subtle"><%= product.get("brand") == null ? "-" : product.get("brand") %> | <%= product.get("classification") %></span>
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

                <div class="panel announcement-panel">
                    <div class="announcement-head">
                        <img src="${pageContext.request.contextPath}/assets/images/icon-announcement.png" alt="Pengumuman">
                        <h3 class="section-title" style="margin:0;">Pengurusan Pengumuman / Info</h3>
                    </div>

                    <% if (request.getAttribute("announcement_success") != null) { %>
                        <div class="announce-alert announce-success"><%= request.getAttribute("announcement_success") %></div>
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

                    <form method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form" enctype="multipart/form-data">
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
                                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard">Batal</a>
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
                                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard?announcement_id=<%= ann.get("id") %>">
                                            <img src="${pageContext.request.contextPath}/assets/images/icon-edit.png" class="icon-btn" alt="Edit"> Edit
                                        </a>
                                        <form method="post" action="${pageContext.request.contextPath}/dashboard" onsubmit="return confirm('Hapus pengumuman ini?');" style="margin:0;">
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

                <div class="panel" id="tetapan-admin">
                    <h3 class="section-title">Tetapan Pentadbir</h3>
                    <p class="subtle">Akses permohonan yang diarkibkan dan urus semula rekod apabila perlu.</p>
                    <div style="display:flex;gap:10px;flex-wrap:wrap; margin-top:10px;">
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard?status=ARCHIVED">Lihat Permohonan Diarkib</a>
                    </div>
                    <p class="subtle" style="margin-top:10px;">Tip: Buka rekod melalui butang Semak, kemudian klik Keluarkan Dari Arkib untuk unarchive.</p>
                    <div style="margin-top:14px;padding-top:12px;border-top:1px solid #e4edf4;">
                        <strong style="display:block;margin-bottom:8px;color:#06344f;"><img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Hubungi" style="width:16px;height:16px;object-fit:contain;vertical-align:middle;margin-right:6px;">Hubungi JANS</strong>
                        <div class="subtle">Telefon: +60-88-232364 (HQ)</div>
                        <div class="subtle">Fax: +60-88-232396</div>
                        <div class="subtle">Email: jans.hq@sabah.gov.my</div>
                    </div>
                </div>
                </div>
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

(function () {
    var idleLimitMs = 10 * 60 * 1000;
    var logoutUrl = '${pageContext.request.contextPath}/logout?timeout=1';
    var timerId;

    function triggerAutoLogout() {
        window.location.href = logoutUrl;
    }

    function resetTimer() {
        window.clearTimeout(timerId);
        timerId = window.setTimeout(triggerAutoLogout, idleLimitMs);
    }

    ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart', 'click'].forEach(function (eventName) {
        document.addEventListener(eventName, resetTimer, { passive: true });
    });

    resetTimer();
})();
</script>
</body>
</html>
