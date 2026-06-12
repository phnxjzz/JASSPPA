<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.Map" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Map<String, Object> app = (Map<String, Object>) request.getAttribute("application");
    List<Map<String, Object>> documents = (List<Map<String, Object>>) request.getAttribute("documents");
    Map<String, String> requiredDocuments = (Map<String, String>) request.getAttribute("requiredDocuments");

    String status = app.get("status") == null ? "" : String.valueOf(app.get("status"));
    String certNum = app.get("certificate_number") == null ? null : String.valueOf(app.get("certificate_number"));
    int appId = (Integer) app.get("id");
    String appIdFormatted = String.format("PPP%03d", appId);
    boolean showUpdatedNotice = "1".equals(request.getParameter("updated"));
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Butiran Permohonan <%= appIdFormatted %> - SPPA</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');
        :root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-gold: #F2F72E;
            --surface: #ffffff;
            --line: #d4e1ec;
            --text: #1a3040;
            --muted: #5d7484;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif; background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-gold) 100%); border-bottom: 3px solid var(--brand-gold); color: white; padding: 14px 26px; display: flex; justify-content: space-between; align-items: center; gap: 20px; box-shadow: 0 12px 28px rgba(8,51,77,0.2); }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 52px; height: 52px; object-fit: contain; }
        .brand h1 { margin: 0; font-size: 21px; letter-spacing: 0.02em; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; }
        .navbar a { color: white; text-decoration: none; margin-left: 10px; font-weight: 700; padding: 8px 11px; border-radius: 8px; transition: background 0.18s ease; }
        .navbar a:hover { background: rgba(255,255,255,0.14); }
        .icon-inline { width: 16px; height: 16px; object-fit: contain; vertical-align: middle; }
        .icon-link { width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.38); transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 4px; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: rgba(255,255,255,0.26); }
        .container { max-width: 960px; margin: 28px auto; padding: 0 20px 40px; }
        .breadcrumb { font-size: 13px; color: var(--muted); margin-bottom: 16px; }
        .breadcrumb a { color: var(--brand-blue); text-decoration: none; }
        .breadcrumb a:hover { text-decoration: underline; }
        .card { background: var(--surface); border: 1px solid var(--line); border-radius: 14px; box-shadow: 0 8px 26px rgba(9,53,79,0.07); margin-bottom: 20px; }
        .card-header { padding: 16px 22px; border-bottom: 1px solid var(--line); display: flex; align-items: center; justify-content: space-between; }
        .card-header h2 { margin: 0; font-size: 16px; color: #0f405d; }
        .card-body { padding: 20px 22px; }
        .detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px 28px; }
        .detail-item label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); margin-bottom: 3px; }
        .detail-item .val { font-size: 15px; color: var(--text); word-break: break-word; }
        .detail-item .val-empty { color: #aab4bc; font-style: italic; }
        .detail-full { grid-column: 1 / -1; }
        .status-badge { display: inline-block; padding: 5px 14px; border-radius: 999px; font-size: 13px; font-weight: 700; }
        .status-NEW { background: #dbeafe; color: #1e40af; }
        .status-UNDER_REVIEW { background: #e0f2fe; color: #0369a1; }
        .status-IN_PROGRESS { background: #ede9fe; color: #7c3aed; }
        .status-APPROVED { background: #dcfce7; color: #166534; }
        .status-REJECTED { background: #fee2e2; color: #b91c1c; }
        .status-SUSPENDED { background: #ffe4d6; color: #9a3412; }
        .status-DRAFT { background: #e2e8f0; color: #334155; }
        .alert { padding: 13px 16px; border-radius: 12px; margin-bottom: 16px; font-size: 14px; }
        .alert-info { background: #ebf7ff; color: #16537a; border: 1px solid #cce5f5; }
        .alert-success { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .alert-warning { background: #fefce8; color: #854d0e; border: 1px solid #fde68a; }
        .alert-danger { background: #fee2e2; color: #b91c1c; border: 1px solid #fecaca; }
        .alert-icon {
            width: 20px;
            height: 20px;
            object-fit: contain;
            vertical-align: middle;
            margin-right: 8px;
        }
        .btn { display: inline-block; padding: 10px 18px; border-radius: 10px; font-weight: 700; font-size: 14px; text-decoration: none; cursor: pointer; border: 1px solid #fff !important; box-shadow: inset 0 0 0 1px #fff, 0 1px 2px rgba(0,0,0,0.18) !important; transition: transform 0.16s ease; }
        .btn:hover { transform: translateY(-1px); }
        .btn-primary { background: linear-gradient(180deg, var(--brand-navy) 0%, var(--brand-blue) 55%, var(--brand-green) 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
        .btn-green { background: linear-gradient(180deg,#16a34a 0%,#15803d 100%); color: white; }
        .doc-list { list-style: none; margin: 0; padding: 0; }
        .doc-item { display: flex; align-items: center; justify-content: space-between; padding: 9px 0; border-bottom: 1px solid #f0f5f9; font-size: 14px; }
        .doc-item:last-child { border-bottom: none; }
        .doc-name { color: var(--text); }
        .doc-meta { color: var(--muted); font-size: 12px; margin-top: 2px; }
        .doc-missing { color: #aab4bc; font-style: italic; }
        .page-title { font-size: 26px; font-weight: 800; color: var(--brand-navy); margin: 0 0 4px; }
        .page-sub { color: var(--muted); font-size: 14px; margin-bottom: 20px; }
        @media (max-width: 700px) { .detail-grid { grid-template-columns: 1fr; } .detail-full { grid-column: 1; } }
    </style>
</head>
<body>
<div class="navbar">
    <div class="brand">
        <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
        <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo JAS">
        <div>
            <h1>Butiran Permohonan</h1>
            <p>Sistem Pendaftaran Produk Air - Jabatan Air Negeri Sabah</p>
        </div>
    </div>
    <div style="display:flex;align-items:center;">
        <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/profile">Profil</a>
        <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/assets/images/home.png" alt="Home"></a>
        <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
    </div>
</div>

<div class="container">
    <div class="breadcrumb">
        <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a> &rsaquo; Permohonan <%= appIdFormatted %>
    </div>

    <div class="page-title">Permohonan <%= appIdFormatted %></div>
    <div class="page-sub">
        <%= app.get("product_name") %>
        &mdash;
        <span class="status-badge status-<%= status %>"><%= status %></span>
    </div>

    <% if (showUpdatedNotice) { %>
    <div class="alert alert-success">
        <img class="alert-icon" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
        <strong>Permohonan berjaya dikemaskini.</strong>
    </div>
    <% } %>

    <%-- Status notices --%>
    <% if ("APPROVED".equals(status) && certNum != null) { %>
    <div class="alert alert-success">
        Permohonan ini telah <strong>diluluskan</strong>. No. Perakuan: <strong><%= certNum %></strong>.
        Sah sehingga: <strong><%= app.get("valid_until") %></strong>.
        <a class="btn btn-green" style="margin-left:12px;padding:6px 14px;font-size:13px;" href="${pageContext.request.contextPath}/certificate?id=<%= appId %>" target="_blank">Lihat Perakuan</a>
    </div>
    <% } else if ("APPROVED".equals(status)) { %>
    <div class="alert alert-success">Permohonan ini telah <strong>diluluskan</strong>.</div>
    <% } else if ("REJECTED".equals(status)) { %>
    <div class="alert alert-danger">Permohonan ini telah <strong>ditolak</strong>.
        <% String notes = app.get("admin_notes") == null ? "" : String.valueOf(app.get("admin_notes")); if (!notes.isBlank()) { %>
        Sebab: <%= notes %>
        <% } %>
    </div>
    <% } else if ("SUSPENDED".equals(status)) { %>
        <div class="alert alert-warning">Permohonan ini sedang <strong>digantung</strong>.</div>
    <% } else if ("NEW".equals(status)) { %>
        <div class="alert alert-info">Permohonan baru telah dihantar. Anda akan dimaklumkan apabila terdapat keputusan.</div>
    <% } else if ("UNDER_REVIEW".equals(status)) { %>
        <div class="alert alert-info">Permohonan sedang dalam <strong>semakan</strong>.</div>
    <% } else if ("IN_PROGRESS".equals(status)) { %>
        <div class="alert alert-info">Permohonan sedang <strong>diproses</strong>.</div>
    <% } %>

    <%-- Main application info --%>
    <div class="card">
        <div class="card-header">
            <h2>Maklumat Permohonan</h2>
                <span style="font-size:13px;color:var(--muted);">Dihantar: <%= app.get("submitted_at") != null ? String.valueOf(app.get("submitted_at")).substring(0,19) : "Belum dihantar" %></span>
        </div>
        <div class="card-body">
            <div class="detail-grid">
                <div class="detail-item">
                    <label>Jenis Permohonan</label>
                    <div class="val"><%= app.get("application_type") != null ? app.get("application_type") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>Nama Produk</label>
                    <div class="val"><%= app.get("product_name") != null ? app.get("product_name") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>Kategori Produk</label>
                    <div class="val"><%= app.get("product_category") != null ? app.get("product_category") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>Status</label>
                    <div class="val"><span class="status-badge status-<%= status %>"><%= status %></span></div>
                </div>
                <div class="detail-item detail-full">
                    <label>Perihal Produk / Ringkasan</label>
                    <div class="val" style="white-space:pre-wrap;"><%= app.get("product_description") != null ? app.get("product_description") : "<span class='val-empty'>-</span>" %></div>
                </div>
            </div>
        </div>
    </div>

    <%-- Supplier / Company --%>
    <div class="card">
        <div class="card-header"><h2>Maklumat Pembekal</h2></div>
        <div class="card-body">
            <div class="detail-grid">
                <div class="detail-item">
                    <label>Nama Syarikat / Pembekal</label>
                    <div class="val"><%= app.get("supplier_name") != null ? app.get("supplier_name") : (app.get("company_name") != null ? app.get("company_name") : "<span class='val-empty'>-</span>") %></div>
                </div>
                <div class="detail-item">
                    <label>No. Telefon</label>
                    <div class="val"><%= app.get("supplier_phone") != null ? app.get("supplier_phone") : (app.get("contact_number") != null ? app.get("contact_number") : "<span class='val-empty'>-</span>") %></div>
                </div>
                <div class="detail-item detail-full">
                    <label>Alamat</label>
                    <div class="val" style="white-space:pre-wrap;"><%= app.get("supplier_address") != null ? app.get("supplier_address") : (app.get("company_address") != null ? app.get("company_address") : "<span class='val-empty'>-</span>") %></div>
                </div>
            </div>
        </div>
    </div>

    <%-- Manufacturer --%>
    <% boolean hasMfr = app.get("manufacturer_name") != null && !String.valueOf(app.get("manufacturer_name")).isBlank(); %>
    <% if (hasMfr) { %>
    <div class="card">
        <div class="card-header"><h2>Maklumat Pengilang</h2></div>
        <div class="card-body">
            <div class="detail-grid">
                <div class="detail-item">
                    <label>Nama Pengilang</label>
                    <div class="val"><%= app.get("manufacturer_name") %></div>
                </div>
                <div class="detail-item">
                    <label>No. Telefon</label>
                    <div class="val"><%= app.get("manufacturer_phone") != null ? app.get("manufacturer_phone") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item detail-full">
                    <label>Alamat Pengilang</label>
                    <div class="val" style="white-space:pre-wrap;"><%= app.get("manufacturer_address") != null ? app.get("manufacturer_address") : "<span class='val-empty'>-</span>" %></div>
                </div>
            </div>
        </div>
    </div>
    <% } %>

    <%-- Certification & Standards --%>
    <div class="card">
        <div class="card-header"><h2>Persijilan &amp; Standard</h2></div>
        <div class="card-body">
            <div class="detail-grid">
                <div class="detail-item">
                    <label>Nama Standard</label>
                    <div class="val"><%= app.get("standard_name") != null ? app.get("standard_name") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>No. Lesen / Persijilan</label>
                    <div class="val"><%= app.get("certification_license") != null ? app.get("certification_license") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>Tarikh Tamat Lesen</label>
                    <div class="val"><%= app.get("certification_valid_until") != null ? app.get("certification_valid_until") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>Jaminan (Tahun)</label>
                    <div class="val"><%= app.get("warranty_years") != null ? app.get("warranty_years") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>No. Rujukan Laporan Ujian</label>
                    <div class="val"><%= app.get("test_report_reference") != null ? app.get("test_report_reference") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item">
                    <label>Tarikh Laporan Ujian</label>
                    <div class="val"><%= app.get("test_report_date") != null ? app.get("test_report_date") : "<span class='val-empty'>-</span>" %></div>
                </div>
            </div>
        </div>
    </div>

    <%-- Wakil Sabah --%>
    <% boolean hasRep = app.get("sabah_rep_name") != null && !String.valueOf(app.get("sabah_rep_name")).isBlank(); %>
    <% if (hasRep) { %>
    <div class="card">
        <div class="card-header"><h2>Wakil di Sabah</h2></div>
        <div class="card-body">
            <div class="detail-grid">
                <div class="detail-item">
                    <label>Nama Wakil</label>
                    <div class="val"><%= app.get("sabah_rep_name") %></div>
                </div>
                <div class="detail-item">
                    <label>No. Telefon</label>
                    <div class="val"><%= app.get("sabah_rep_phone") != null ? app.get("sabah_rep_phone") : "<span class='val-empty'>-</span>" %></div>
                </div>
                <div class="detail-item detail-full">
                    <label>Alamat</label>
                    <div class="val" style="white-space:pre-wrap;"><%= app.get("sabah_rep_address") != null ? app.get("sabah_rep_address") : "<span class='val-empty'>-</span>" %></div>
                </div>
            </div>
        </div>
    </div>
    <% } %>

    <%-- Documents --%>
    <div class="card">
        <div class="card-header"><h2>Dokumen Dimuat Naik</h2></div>
        <div class="card-body">
            <% if (documents == null || documents.isEmpty()) { %>
                <p style="color:var(--muted);font-style:italic;">Tiada dokumen dimuat naik.</p>
            <% } else { %>
            <ul class="doc-list">
                <% for (Map<String, Object> doc : documents) {
                    String docType = String.valueOf(doc.get("document_type"));
                    String label = requiredDocuments != null && requiredDocuments.containsKey(docType) ? requiredDocuments.get(docType) : docType;
                    long fileSize = (Long) doc.get("file_size");
                    String sizeStr = fileSize > 1024 * 1024 ? String.format("%.1f MB", fileSize / 1048576.0) : String.format("%.0f KB", fileSize / 1024.0);
                    int docId = (Integer) doc.get("id");
                %>
                <li class="doc-item">
                    <div>
                        <div class="doc-name"><%= label %></div>
                        <div class="doc-meta"><%= doc.get("original_filename") %> &mdash; <%= sizeStr %></div>
                    </div>
                    <a href="${pageContext.request.contextPath}/documents/download?id=<%= docId %>" class="btn btn-secondary" style="padding:6px 12px;font-size:12px;">Muat Turun</a>
                </li>
                <% } %>
            </ul>
            <% } %>
        </div>
    </div>

    <%-- Admin notes if any --%>
    <% String adminNotes = app.get("admin_notes") == null ? "" : String.valueOf(app.get("admin_notes")); %>
    <% if (!adminNotes.isBlank()) { %>
    <div class="card">
        <div class="card-header"><h2>Nota Pentadbir</h2></div>
        <div class="card-body" style="white-space:pre-wrap;"><%= adminNotes %></div>
    </div>
    <% } %>

    <div style="display:flex;gap:12px;margin-top:8px;">
        <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-secondary">Kembali ke Dashboard</a>
        <% if ("DRAFT".equals(status) || "NEW".equals(status) || "UNDER_REVIEW".equals(status) || "IN_PROGRESS".equals(status) || "REJECTED".equals(status)) { %>
        <a href="${pageContext.request.contextPath}/applications/<%= appId %>/edit" class="btn btn-primary">Kemaskini Permohonan</a>
        <% } %>
        <% if ("APPROVED".equals(status) && certNum != null) { %>
        <a href="${pageContext.request.contextPath}/certificate?id=<%= appId %>" class="btn btn-green" target="_blank">Lihat Perakuan</a>
        <% } %>
    </div>
</div>
</body>
</html>
