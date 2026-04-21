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
        .icon-inline { width: 14px; height: 14px; object-fit: contain; vertical-align: middle; }
        .container { max-width: 1320px; margin: 28px auto; padding: 0 20px 32px; }
        .hero { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 20px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; max-width: 760px; }
        .metric-strip { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .metric-chip { background: var(--surface-soft); border: 1px solid var(--line); padding: 10px 14px; border-radius: 999px; font-weight: 700; }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); padding: 14px; background: #f7fbff; }
        .contact-image strong { display: block; margin-bottom: 8px; color: var(--brand-navy); }
        .contact-image p { margin: 4px 0; color: var(--muted); font-size: 14px; }
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
                            <option value="PENDING" <%= "PENDING".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>PENDING</option>
                            <option value="APPROVED" <%= "APPROVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>APPROVED</option>
                            <option value="REJECTED" <%= "REJECTED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>REJECTED</option>
                            <option value="SUSPENDED" <%= "SUSPENDED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>SUSPENDED</option>
                            <option value="DRAFT" <%= "DRAFT".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DRAFT</option>
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

                    <div class="export-summary">
                        <div class="export-metric">
                            <small>Diluluskan</small>
                            <strong><%= request.getAttribute("approved_count") != null ? request.getAttribute("approved_count") : "0" %></strong>
                        </div>
                        <div class="export-metric">
                            <small>Ditolak</small>
                            <strong><%= request.getAttribute("rejected_count") != null ? request.getAttribute("rejected_count") : "0" %></strong>
                        </div>
                        <div class="export-metric">
                            <small>Menunggu</small>
                            <strong><%= request.getAttribute("pending_count") != null ? request.getAttribute("pending_count") : "0" %></strong>
                        </div>
                    </div>

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
                            <th style="width:42px;"><input type="checkbox" id="selectAllApps" class="table-check" aria-label="Pilih semua"></th>
                            <% } %>
                            <th>ID</th>
                            <th>Nama Syarikat</th>
                            <th>Kategori Produk</th>
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
                                String status = String.valueOf(applicationRow.get("status")).toLowerCase();
                        %>
                        <tr>
                            <% if (isAdminRole) { %>
                            <td><input type="checkbox" class="app-row-check table-check" value="<%= applicationRow.get("id") %>" aria-label="Pilih permohonan"></td>
                            <% } %>
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
                                <a
                                    class="btn btn-primary js-open-app-modal"
                                    href="${pageContext.request.contextPath}/admin/application?id=<%= applicationRow.get("id") %>"
                                    data-app-id="<%= applicationRow.get("id") %>"
                                    data-company="<%= escapeHtml(applicationRow.get("company_name") == null ? "" : String.valueOf(applicationRow.get("company_name")) ) %>"
                                    data-category="<%= escapeHtml(applicationRow.get("product_category") == null ? "" : String.valueOf(applicationRow.get("product_category")) ) %>"
                                    data-product="<%= escapeHtml(applicationRow.get("product_name") == null ? "" : String.valueOf(applicationRow.get("product_name")) ) %>"
                                    data-status="<%= escapeHtml(applicationRow.get("status") == null ? "" : String.valueOf(applicationRow.get("status")) ) %>"
                                    data-submitted="<%= escapeHtml(submittedAt != null ? submittedAt.toString() : "Belum dihantar") %>"
                                    data-user="<%= escapeHtml(applicationRow.get("full_name") == null ? "" : String.valueOf(applicationRow.get("full_name")) ) %>"
                                    data-email="<%= escapeHtml(applicationRow.get("user_email") == null ? "" : String.valueOf(applicationRow.get("user_email")) ) %>"
                                    data-attachment-image="<%= escapeHtml(applicationRow.get("attachment_image_url") == null ? "" : String.valueOf(applicationRow.get("attachment_image_url")) ) %>"
                                    data-attachment-pdf="<%= escapeHtml(applicationRow.get("attachment_pdf_url") == null ? "" : String.valueOf(applicationRow.get("attachment_pdf_url")) ) %>">
                                    Semak
                                </a>
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
                                <span class="legend-label"><span class="legend-dot pending"></span>Menunggu</span>
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
                            %>
                                <tr>
                                    <td><%= ai + 1 %></td>
                                    <td style="max-width:220px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<%= annTitle %>"><%= annTitle %></td>
                                    <td>
                                        <span style="<%= "display:inline-block; padding:2px 10px; border-radius:20px; font-size:12px; font-weight:600; background:" + (annActive ? "#d4edda" : "#f0f0f0") + "; color:" + (annActive ? "#155724" : "#555") + ";" %>">
                                            <%= annActive ? "Aktif" : "Tidak Aktif" %>
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
        var latestPanel = document.querySelector('.table-card');
        var toggleLatestPanelBtn = document.getElementById('toggleLatestPanelBtn');
        var announcementPanelCard = document.getElementById('announcementPanel');
        var toggleAnnouncementPanelBtn = document.getElementById('toggleAnnouncementPanelBtn');

        var appDetailModal = document.getElementById('appDetailModal');
        var appModalCloseBtn = document.getElementById('appModalCloseBtn');
        var modalReviewLink = document.getElementById('modalReviewLink');
        var modalAttachmentViewer = document.getElementById('modalAttachmentViewer');
        var isAdminRoleClient = <%=  "ADMIN".equals(String.valueOf(session.getAttribute("role"))) ? "true" : "false" %>;

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

        exportButton.addEventListener('click', function(e) {
            e.preventDefault();
            runExport();
        });

        if (quickExportButton) {
            quickExportButton.addEventListener('click', function(e) {
                e.preventDefault();
                runExport();
            });
        }
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
</script>

</body>
</html>
