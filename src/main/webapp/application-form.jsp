<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Set" %>
<<<<<<< HEAD
<%@ page import="java.util.List" %>
=======
>>>>>>> origin/SPPPA
<%@ page import="java.util.LinkedHashSet" %>
<%!
    private String toJs(Object value) {
        if (value == null) {
            return "";
        }
        String s = String.valueOf(value);
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "\\n")
                .replace("</", "<\\/");
    }

    private String appValue(Map<String, Object> app, String key) {
        if (app == null || key == null) {
            return "";
        }
        Object value = app.get(key);
        return value == null ? "" : String.valueOf(value);
    }
<<<<<<< HEAD

    private String buildRenewalSourceJson(List<Map<String, Object>> apps) {
        if (apps == null || apps.isEmpty()) {
            return "{}";
        }
        StringBuilder json = new StringBuilder("{");
        for (int i = 0; i < apps.size(); i++) {
            Map<String, Object> approvedApp = apps.get(i);
            Object approvedIdObj = approvedApp.get("id");
            String approvedId = approvedIdObj == null ? "" : String.valueOf(((Number) approvedIdObj).intValue());
            if (i > 0) {
                json.append(',');
            }
            json.append('"').append(toJs(approvedId)).append("\":{")
                .append("\"supplier_email\":\"").append(toJs(appValue(approvedApp, "supplier_email"))).append("\",")
                .append("\"supplier_phone\":\"").append(toJs(appValue(approvedApp, "supplier_phone"))).append("\",")
                .append("\"supplier_name\":\"").append(toJs(appValue(approvedApp, "supplier_name"))).append("\",")
                .append("\"supplier_address\":\"").append(toJs(appValue(approvedApp, "supplier_address"))).append("\",")
                .append("\"manufacturer_name\":\"").append(toJs(appValue(approvedApp, "manufacturer_name"))).append("\",")
                .append("\"manufacturer_address\":\"").append(toJs(appValue(approvedApp, "manufacturer_address"))).append("\",")
                .append("\"manufacturer_phone\":\"").append(toJs(appValue(approvedApp, "manufacturer_phone"))).append("\",")
                .append("\"principal_name\":\"").append(toJs(appValue(approvedApp, "principal_name"))).append("\",")
                .append("\"principal_address\":\"").append(toJs(appValue(approvedApp, "principal_address"))).append("\",")
                .append("\"principal_phone\":\"").append(toJs(appValue(approvedApp, "principal_phone"))).append("\",")
                .append("\"product_category\":\"").append(toJs(appValue(approvedApp, "product_category"))).append("\",")
                .append("\"product_name\":\"").append(toJs(appValue(approvedApp, "product_name"))).append("\",")
                .append("\"brand\":\"").append(toJs(appValue(approvedApp, "brand"))).append("\",")
                .append("\"standard_name\":\"").append(toJs(appValue(approvedApp, "standard_name"))).append("\",")
                .append("\"certification_license\":\"").append(toJs(appValue(approvedApp, "certification_license"))).append("\",")
                .append("\"certification_valid_until\":\"").append(toJs(appValue(approvedApp, "certification_valid_until"))).append("\",")
                .append("\"test_report_reference\":\"").append(toJs(appValue(approvedApp, "test_report_reference"))).append("\",")
                .append("\"test_report_date\":\"").append(toJs(appValue(approvedApp, "test_report_date"))).append("\",")
                .append("\"warranty_years\":\"").append(toJs(appValue(approvedApp, "warranty_years"))).append("\",")
                .append("\"product_model\":\"").append(toJs(appValue(approvedApp, "product_model"))).append("\",")
                .append("\"product_series\":\"").append(toJs(appValue(approvedApp, "product_series"))).append("\",")
                .append("\"product_description\":\"").append(toJs(appValue(approvedApp, "product_description"))).append("\",")
                .append("\"sabah_rep_name\":\"").append(toJs(appValue(approvedApp, "sabah_rep_name"))).append("\",")
                .append("\"sabah_rep_address\":\"").append(toJs(appValue(approvedApp, "sabah_rep_address"))).append("\",")
                .append("\"sabah_rep_phone\":\"").append(toJs(appValue(approvedApp, "sabah_rep_phone"))).append("\"}");
        }
        json.append('}');
        return json.toString();
    }
=======
>>>>>>> origin/SPPPA
%>
<%
    Map<String, Object> editingApp = (Map<String, Object>) request.getAttribute("application");
    boolean editMode = Boolean.TRUE.equals(request.getAttribute("editMode"));
    boolean renewalMode = Boolean.TRUE.equals(request.getAttribute("renewalMode"));
    Object renewalSourceApplicationId = request.getAttribute("renewalSourceApplicationId");
<<<<<<< HEAD
    List<Map<String, Object>> approvedApplications = (List<Map<String, Object>>) request.getAttribute("approvedApplications");
    if (approvedApplications == null) {
        approvedApplications = java.util.Collections.emptyList();
    }
    String selectedRenewalSourceId = renewalSourceApplicationId == null ? "" : String.valueOf(renewalSourceApplicationId);
=======
>>>>>>> origin/SPPPA
    String formAction = request.getAttribute("formAction") != null
            ? String.valueOf(request.getAttribute("formAction"))
            : (request.getContextPath() + "/applications/new");
    Set<String> existingDocumentKeys = (Set<String>) request.getAttribute("existingDocumentKeys");
    if (existingDocumentKeys == null) {
        existingDocumentKeys = new LinkedHashSet<>();
    }
    StringBuilder existingDocKeysCsv = new StringBuilder();
    for (String key : existingDocumentKeys) {
        if (existingDocKeysCsv.length() > 0) {
            existingDocKeysCsv.append('|');
        }
        existingDocKeysCsv.append(key);
    }

    String jsApplicationType = toJs(appValue(editingApp, "application_type"));
    String jsSupplierEmail = toJs(appValue(editingApp, "supplier_email"));
    String jsSupplierPhone = toJs(appValue(editingApp, "supplier_phone"));
    String jsSupplierName = toJs(appValue(editingApp, "supplier_name"));
    String jsSupplierAddress = toJs(appValue(editingApp, "supplier_address"));
    String jsManufacturerName = toJs(appValue(editingApp, "manufacturer_name"));
    String jsManufacturerAddress = toJs(appValue(editingApp, "manufacturer_address"));
    String jsManufacturerPhone = toJs(appValue(editingApp, "manufacturer_phone"));
    String jsPrincipalName = toJs(appValue(editingApp, "principal_name"));
    String jsPrincipalAddress = toJs(appValue(editingApp, "principal_address"));
    String jsPrincipalPhone = toJs(appValue(editingApp, "principal_phone"));
    String jsProductCategory = toJs(appValue(editingApp, "product_category"));
    String jsProductName = toJs(appValue(editingApp, "product_name"));
    String jsBrand = toJs(appValue(editingApp, "brand"));
    String jsStandardName = toJs(appValue(editingApp, "standard_name"));
    String jsCertificationLicense = toJs(appValue(editingApp, "certification_license"));
    String jsCertificationValidUntil = toJs(appValue(editingApp, "certification_valid_until"));
    String jsTestReportReference = toJs(appValue(editingApp, "test_report_reference"));
    String jsTestReportDate = toJs(appValue(editingApp, "test_report_date"));
    String jsWarrantyYears = toJs(appValue(editingApp, "warranty_years"));
<<<<<<< HEAD
    String jsProductModel = toJs(appValue(editingApp, "product_model"));
    String jsProductSeries = toJs(appValue(editingApp, "product_series"));
=======
>>>>>>> origin/SPPPA
    String jsProductDescription = toJs(appValue(editingApp, "product_description"));
    String jsSabahRepName = toJs(appValue(editingApp, "sabah_rep_name"));
    String jsSabahRepAddress = toJs(appValue(editingApp, "sabah_rep_address"));
    String jsSabahRepPhone = toJs(appValue(editingApp, "sabah_rep_phone"));
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Borang Permohonan Online PPP1 - SPPA</title>
    <style>
* { box-sizing: border-box; }
        body { font-family: inherit; margin: 0; background: linear-gradient(180deg, #eff9ff 0%, #f7fbfd 100%); color: #223; }
        .navbar { background: linear-gradient(130deg, #0F6BAE 0%, #2A9D8F 30%, #6DBE45 58%, #CDE11D 80%, #F2F72E 100%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; flex-wrap: nowrap; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 48px; height: 48px; border-radius: 14px; object-fit: contain; padding: 3px; }
        .brand strong { display: block; }
        .brand span { font-size: 12px; opacity: 0.88; }
        .nav-actions { margin-left: auto; display: inline-flex; align-items: center; gap: 6px; flex-shrink: 0; }
        .navbar a { color: white; text-decoration: none; }
        .container { max-width: 1100px; margin: 28px auto; padding: 0 20px; }
        .panel { border-radius: 12px; box-shadow: 0 12px 30px rgba(16, 24, 40, 0.08); padding: 24px; margin-bottom: 24px; }
        .hero { display: grid; grid-template-columns: 2fr 1fr; gap: 20px; }
        .hero h1 { margin-top: 0; font-size: 30px; }
        .hero p { color: #556; line-height: 1.6; }
        .badge { display: inline-block; background: #dbeafe; color: #1d4ed8; border-radius: 999px; padding: 6px 10px; font-size: 12px; font-weight: 600; margin-bottom: 10px; }
        .docs-box { background: #f8fafc; border: 1px solid #d8e1ee; border-radius: 10px; padding: 16px; }
        .docs-box a { display: block; color: #0f766e; text-decoration: none; margin-bottom: 8px; }
        .section-title { margin: 0 0 16px; padding-bottom: 10px; border-bottom: 2px solid #e5e7eb; color: #0f172a; }
        .grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
        .grid-3 { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; }
        .field { display: flex; flex-direction: column; gap: 6px; }
        .field label { font-weight: 600; font-size: 14px; color: #334155; }
        .field input, .field textarea, .field select { width: 100%; padding: 11px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 14px; }
        .field textarea { min-height: 110px; resize: vertical; }
        .field.full { grid-column: 1 / -1; }
        .hint { font-size: 12px; color: #64748b; }
        .alert { padding: 14px 16px; border-radius: 8px; margin-bottom: 18px; }
        .alert.error { background: #fef2f2; color: #b91c1c; }
        .alert.success { background: #ecfdf5; color: #047857; }
        .alert-with-gif { display: flex; align-items: center; gap: 10px; }
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
            line-height: 1.6;
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
        .unsuccessful-popup {
            border: 1px solid #fecaca;
            background: #fef2f2;
            color: #991b1b;
            box-shadow: 0 16px 32px rgba(127, 29, 29, 0.2);
        }
        .unsuccessful-title { color: #991b1b; font-size: 20px; line-height: 1.2; font-weight: 800; text-align: center; }
        .unsuccessful-ok { align-self: center; margin-top: 4px; border: 1px solid #7f1d1d !important; background: #b91c1c; color: #fff; border-radius: 10px; padding: 10px 24px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .unsuccessful-icon {
            width: 52px;
            height: 52px;
            object-fit: contain;
            flex-shrink: 0;
            filter: drop-shadow(0 3px 8px rgba(127, 29, 29, 0.35));
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
        .doc-list { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
        .doc-item { padding: 14px; border: 1px solid #dbe2ea; border-radius: 10px; background: #fcfdff; }
        .doc-item strong { display: block; margin-bottom: 8px; font-size: 14px; }
        .doc-item strong .required-mark { color: #b91c1c; margin-left: 4px; }
        .product-array-wrap { display: grid; gap: 10px; margin-bottom: 10px; }
        .product-array-head { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
        .product-array-list { display: grid; gap: 10px; }
        .product-item { border: 1px solid #dbe2ea; border-radius: 10px; padding: 12px; background: #fcfdff; }
        .product-item-title { font-size: 13px; font-weight: 700; color: #0f172a; margin-bottom: 10px; }
        .product-item-actions { margin-top: 8px; display: flex; justify-content: flex-end; }
        .product-array-foot { margin-top: 12px; display: flex; justify-content: flex-start; }
        .btn.btn-add-product {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-weight: 800;
            font-size: 13px;
            padding: 9px 14px;
            border-radius: 8px;
            background: #0F6BAE;
            color: #ffffff;
            border: 1px solid #0b4f81 !important;
            box-shadow: 0 4px 12px rgba(15, 107, 174, 0.28);
        }
        .btn.btn-add-product:hover,
        .btn.btn-add-product:focus {
            background: #0b5b94;
            color: #ffffff;
            transform: translateY(-1px);
        }
        .btn-add-product img { width: 16px; height: 16px; object-fit: contain; }
        .btn-remove-product { background: #fee2e2; color: #991b1b; border-color: #fecaca !important; }
        .actions { display: flex; gap: 12px; justify-content: flex-end; margin-top: 20px; }
        .btn { border: 1px solid #fff; border-radius: 8px; padding: 12px 18px; font-size: 14px; cursor: pointer; text-decoration: none; }
        .btn-secondary { background: #e2e8f0; color: #1e293b; }
        .btn-primary { background: linear-gradient(135deg, #0F6BAE 0%, #2A9D8F 45%, #6DBE45 100%); color: white; }
        .contact-card { width: 100%; max-width: 420px; border-radius: 12px; border: 1px solid #d8e1ee; background: #f8fbff; padding: 14px; color: #475569; }
        .contact-card strong { display: block; margin-bottom: 8px; color: #0f172a; }
        .contact-card p { margin: 4px 0; }
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; min-width: 0; }
        .jans-contact-section .contact-icon { display: inline-block; width: 10px; height: 10px; background: #0f6bae; border-radius: 2px; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
<<<<<<< HEAD
        .contact-line-hanging { margin-left: 21px; }
=======
>>>>>>> origin/SPPPA
        @media (max-width: 900px) { .hero, .grid, .grid-3, .doc-list { grid-template-columns: 1fr; } }
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
        .icon-inline { width: 20px; height: 20px; object-fit: contain; vertical-align: middle; }
        .icon-link { width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.38); transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 0; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: rgba(255,255,255,0.26); }
    </style>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <strong>Borang Permohonan</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div class="nav-actions">
            <a class="icon-link" href="${pageContext.request.contextPath}/dashboard" title="Kembali ke Dashboard" aria-label="Kembali ke Dashboard"><img src="${pageContext.request.contextPath}/icon/dashboard.png" alt="Dashboard"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/icon/home.png" alt="Home"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
        </div>
    </div>

    <div class="container">
        <% if (request.getAttribute("error") != null) { %>
            <div class="alert error"><%= request.getAttribute("error") %></div>
        <% } %>
        <% if (request.getParameter("success") != null) { %>
            <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
                <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
                <div class="success-popup-content">
                    <div class="success-title">Berjaya!</div>
                    <div class="success-text"></div>
                    <button type="button" class="success-ok" data-close-success-popup>OK</button>
                </div>
            </div>
        <% } %>
        <div id="unsuccessfulPopup" class="success-popup unsuccessful-popup" role="dialog" aria-live="polite" aria-label="Notifikasi gagal">
            <img class="unsuccessful-icon" src="${pageContext.request.contextPath}/assets/images/unsuccessful.png" alt="Tidak berjaya">
            <div class="success-popup-content">
                <div class="unsuccessful-title">Tidak Berjaya Sila Lengkapkan Dokumen yang diperlukan!</div>
                <button type="button" class="unsuccessful-ok" data-close-unsuccessful-popup>OK</button>
            </div>
        </div>

        <div class="panel hero">
            <div>
                <span class="badge">PPP1 + PPP2 + Garis Panduan JANS</span>
                <h1>Borang Permohonan Pendaftaran Pembekal dan Produk Bekalan Air</h1>
            </div>
            <div class="docs-box">
                <strong>Rujukan Asal</strong>
                <a href="${pageContext.request.contextPath}/assets/forms/borang-ppp1-permohonan-pendaftaran-pembekal-produk_0.pdf" target="_blank">Borang PPP1</a>
                <a href="${pageContext.request.contextPath}/assets/forms/borang-ppp2-senarai-semak-pendaftaran-pembekal-produk_0.pdf" target="_blank">Senarai Semak PPP2</a>
                <a href="${pageContext.request.contextPath}/assets/forms/garis-panduan-pendaftaran-pembekal-dan-produk-bekalan-air.pdf" target="_blank">Garis Panduan Pendaftaran</a>
            </div>
        </div>

        <form id="applicationForm" class="panel" method="post" action="<%= formAction %>" enctype="multipart/form-data">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" id="existingDocKeysCsv" value="<%= toJs(existingDocKeysCsv.toString()) %>">
<<<<<<< HEAD
            <input type="hidden" id="renew_from_application_id" name="renew_from_application_id" value="<%= toJs(selectedRenewalSourceId) %>">
=======
            <% if (renewalSourceApplicationId != null) { %>
            <input type="hidden" name="renew_from_application_id" value="<%= renewalSourceApplicationId %>">
            <% } %>
>>>>>>> origin/SPPPA
            <% if (editMode) { %>
            <div class="alert success">Mod kemaskini permohonan. Maklumat boleh dikemaskini dan dihantar semula.</div>
            <% } else if (renewalMode) { %>
            <div class="alert success">Permohonan ini ialah pembaharuan daripada rekod yang telah diluluskan. Dokumen lama akan digunakan semula dan anda hanya perlu memuat naik lampiran pembaharuan yang baharu.</div>
            <% } %>
            <h2 class="section-title">Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal</h2>
            <div class="grid-3">
                <div class="field">
                    <label for="application_type">Jenis Permohonan</label>
                    <select id="application_type" name="application_type" required>
                        <option value="">Pilih</option>
                        <option value="BAHARU" <%= "BAHARU".equals(appValue(editingApp, "application_type")) ? "selected" : "" %>>Baharu</option>
                        <option value="PEMBAHARUAN" <%= "PEMBAHARUAN".equals(appValue(editingApp, "application_type")) ? "selected" : "" %>>Pembaharuan</option>
                    </select>
                </div>
                <div class="field" id="renewalSourceField" style="display:none; grid-column: 1 / -1;">
                    <label for="renewal_source_selector">Produk Diluluskan Untuk Pembaharuan</label>
                    <select id="renewal_source_selector">
                        <option value="">Pilih produk yang diluluskan</option>
                        <% for (Map<String, Object> approvedApp : approvedApplications) {
                               int approvedId = approvedApp.get("id") == null ? 0 : ((Number) approvedApp.get("id")).intValue();
                               String approvedProduct = approvedApp.get("product_name") == null ? "-" : String.valueOf(approvedApp.get("product_name"));
                               String approvedCompany = approvedApp.get("supplier_name") == null ? "-" : String.valueOf(approvedApp.get("supplier_name"));
                               String selectedAttr = String.valueOf(approvedId).equals(selectedRenewalSourceId) ? "selected" : "";
                        %>
                        <option value="<%= approvedId %>" <%= selectedAttr %>><%= String.format("PPP%03d", approvedId) %> - <%= approvedProduct %> (<%= approvedCompany %>)</option>
                        <% } %>
                    </select>
                    <% if (approvedApplications.isEmpty()) { %>
                    <span class="hint" style="color:#b91c1c;">Tiada produk diluluskan ditemui untuk pembaharuan.</span>
                    <% } else { %>
                    <span class="hint">Pilih produk diluluskan untuk auto-isi borang pembaharuan. Anda masih boleh edit semua maklumat selepas auto-isi.</span>
                    <% } %>
                </div>
                <div class="field">
                    <label for="supplier_email">Email Pembekal</label>
                    <input id="supplier_email" name="supplier_email" type="email" placeholder="contoh@syarikat.com" value="<%= appValue(editingApp, "supplier_email") %>" />
                </div>
                <div class="field">
                    <label for="supplier_phone">No. Telefon Pembekal</label>
                    <input id="supplier_phone" name="supplier_phone" type="text" placeholder="088-123456" value="<%= appValue(editingApp, "supplier_phone") %>" />
                </div>
            </div>

            <div class="grid">
                <div class="field full">
                    <label for="supplier_name">Nama Syarikat Pembekal</label>
                    <input id="supplier_name" name="supplier_name" type="text" required value="<%= appValue(editingApp, "supplier_name") %>" />
                </div>
                <div class="field full">
                    <label for="supplier_address">Alamat Pejabat Pembekal</label>
                    <textarea id="supplier_address" name="supplier_address" required><%= appValue(editingApp, "supplier_address") %></textarea>
                </div>
                <div class="field full">
                    <label for="manufacturer_name">Nama Syarikat Pembuat / Pengilang</label>
                    <input id="manufacturer_name" name="manufacturer_name" type="text" value="<%= appValue(editingApp, "manufacturer_name") %>" />
                </div>
                <div class="field full">
                    <label for="manufacturer_address">Alamat Pejabat Pembuat / Pengilang</label>
                    <textarea id="manufacturer_address" name="manufacturer_address"><%= appValue(editingApp, "manufacturer_address") %></textarea>
                </div>
                <div class="field">
                    <label for="manufacturer_phone">No. Telefon Pengilang</label>
                    <input id="manufacturer_phone" name="manufacturer_phone" type="text" value="<%= appValue(editingApp, "manufacturer_phone") %>" />
                </div>
                <div class="field"></div>
                <div class="field full">
                    <label for="principal_name">Nama Syarikat Prinsipal / Pemilik Produk</label>
                    <input id="principal_name" name="principal_name" type="text" value="<%= appValue(editingApp, "principal_name") %>" />
                </div>
                <div class="field full">
                    <label for="principal_address">Alamat Pejabat Prinsipal / Pemilik Produk</label>
                    <textarea id="principal_address" name="principal_address"><%= appValue(editingApp, "principal_address") %></textarea>
                </div>
                <div class="field">
                    <label for="principal_phone">No. Telefon Prinsipal</label>
                    <input id="principal_phone" name="principal_phone" type="text" value="<%= appValue(editingApp, "principal_phone") %>" />
                </div>
            </div>

            <h2 class="section-title">Bahagian B: Maklumat Produk</h2>
            <div class="product-array-wrap">
                <div class="product-array-head">
                    <span class="hint">Pemohon boleh mohon lebih daripada satu produk.</span>
                </div>
                <div id="productArrayList" class="product-array-list">
                    <div class="product-item" data-product-item>
                        <div class="product-item-title">Produk 1</div>
                        <div class="grid-3">
                            <div class="field">
                                <label for="product_category_1">Kategori Produk</label>
                                <select id="product_category_1" name="product_category[]" required>
                                    <option value="">Pilih kategori</option>
                                    <option value="Water Treatment Equipment" <%= "Water Treatment Equipment".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Water Treatment Equipment</option>
                                    <option value="Conveyance Of Water" <%= "Conveyance Of Water".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Conveyance Of Water</option>
                                    <option value="Flow Control" <%= "Flow Control".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Flow Control</option>
                                    <option value="Measuring Device" <%= "Measuring Device".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Measuring Device</option>
                                    <option value="Chemical For Water Treatment" <%= "Chemical For Water Treatment".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Chemical For Water Treatment</option>
                                    <option value="Storage Of Water" <%= "Storage Of Water".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Storage Of Water</option>
                                    <option value="Sanitary" <%= "Sanitary".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Sanitary</option>
                                    <option value="Lining" <%= "Lining".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Lining</option>
                                    <option value="Coating" <%= "Coating".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Coating</option>
                                    <option value="Waterproofing" <%= "Waterproofing".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Waterproofing</option>
                                    <option value="Sealant" <%= "Sealant".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Sealant</option>
                                    <option value="Adhesive" <%= "Adhesive".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Adhesive</option>
                                    <option value="Solvent Cement" <%= "Solvent Cement".equals(appValue(editingApp, "product_category")) ? "selected" : "" %>>Solvent Cement</option>
                                </select>
                            </div>
                            <div class="field">
                                <label for="product_name_1">Nama Produk</label>
                                <input id="product_name_1" name="product_name[]" type="text" required value="<%= appValue(editingApp, "product_name") %>" />
                            </div>
                            <div class="field">
                                <label for="brand_1">Jenama</label>
                                <input id="brand_1" name="brand[]" type="text" required value="<%= appValue(editingApp, "brand") %>" />
                            </div>
                            <div class="field">
                                <label for="standard_name_1">Piawaian / Standard</label>
                                <input id="standard_name_1" name="standard_name[]" type="text" placeholder="MS / BS / ISO / lain-lain" required value="<%= appValue(editingApp, "standard_name") %>" />
                            </div>
                            <div class="field">
                                <label for="certification_license_1">Badan Persijilan & No. Lesen</label>
                                <input id="certification_license_1" name="certification_license[]" type="text" required value="<%= appValue(editingApp, "certification_license") %>" />
                            </div>
                            <div class="field">
                                <label for="certification_valid_until_1">Sah Sehingga</label>
                                <input id="certification_valid_until_1" name="certification_valid_until[]" type="date" required value="<%= appValue(editingApp, "certification_valid_until") %>" />
                            </div>
                            <div class="field">
                                <label for="test_report_reference_1">Badan Persijilan & No. Laporan Pengujian</label>
                                <input id="test_report_reference_1" name="test_report_reference[]" type="text" required value="<%= appValue(editingApp, "test_report_reference") %>" />
                            </div>
                            <div class="field">
                                <label for="test_report_date_1">Tarikh Laporan Pengujian</label>
                                <input id="test_report_date_1" name="test_report_date[]" type="date" required value="<%= appValue(editingApp, "test_report_date") %>" />
                            </div>
                            <div class="field">
                                <label for="warranty_years_1">Tempoh Jaminan Produk (Tahun)</label>
                                <input id="warranty_years_1" name="warranty_years[]" type="number" step="0.1" min="0" required value="<%= appValue(editingApp, "warranty_years") %>" />
                            </div>
                            <div class="field full">
<<<<<<< HEAD
                                <label for="product_model_1">Perihal Produk (Model)</label>
                                <input id="product_model_1" name="product_model[]" type="text" placeholder="Contoh: DUC-500" value="<%= appValue(editingApp, "product_model") %>" />
                            </div>
                            <div class="field full">
                                <label for="product_series_1">Perihal Produk (Siri)</label>
                                <input id="product_series_1" name="product_series[]" type="text" placeholder="Contoh: SERIES-A" value="<%= appValue(editingApp, "product_series") %>" />
                            </div>
                            <div class="field full">
                                <label for="product_description_1">Perihal Produk (Deskripsi / Class / Saiz)</label>
=======
                                <label for="product_description_1">Perihal Produk (Model / Siri / Deskripsi)</label>
>>>>>>> origin/SPPPA
                                <textarea id="product_description_1" name="product_description[]" required><%= appValue(editingApp, "product_description") %></textarea>
                            </div>
                        </div>
                        <div class="product-item-actions">
                            <button type="button" class="btn btn-remove-product" data-remove-product hidden>Buang</button>
                        </div>
                    </div>
                </div>
            </div>

            <div class="product-array-foot">
                <button type="button" id="addProductBtn" class="btn btn-add-product" aria-label="Tambah produk baharu">
                    <img src="${pageContext.request.contextPath}/icon/add-new.png" alt="Tambah produk baharu">
                    Add New
                </button>
            </div>

            <h2 class="section-title">Bahagian C: Sokongan Teknikal di Negeri Sabah</h2>
            <div class="grid">
                <div class="field">
                    <label for="sabah_rep_name">Nama Wakil di Sabah</label>
                    <input id="sabah_rep_name" name="sabah_rep_name" type="text" value="<%= appValue(editingApp, "sabah_rep_name") %>" />
                </div>
                <div class="field">
                    <label for="sabah_rep_phone">No. Telefon Wakil</label>
                    <input id="sabah_rep_phone" name="sabah_rep_phone" type="text" value="<%= appValue(editingApp, "sabah_rep_phone") %>" />
                </div>
                <div class="field full">
                    <label for="sabah_rep_address">Alamat Pejabat Wakil di Sabah</label>
                    <textarea id="sabah_rep_address" name="sabah_rep_address"><%= appValue(editingApp, "sabah_rep_address") %></textarea>
                </div>
            </div>

            <h2 class="section-title">Bahagian D: Dokumen Sokongan (PPP2)</h2>
                <p class="hint"><%= renewalMode
                    ? "Dokumen sedia ada daripada permohonan yang telah diluluskan akan digunakan semula. Muat naik semula hanya jika anda mahu menggantikan dokumen tersebut. Lampiran sijil/perakuan lama JANS untuk pembaharuan masih wajib jika belum pernah dimuat naik."
                    : "Muat naik dokumen dalam format PDF. Untuk pembaharuan, lampiran sijil/perakuan lama adalah wajib. Medan 'jika ada' boleh dibiarkan kosong." %></p>
            <div class="doc-list">
                <% Map<String, String> requiredDocuments = (Map<String, String>) request.getAttribute("requiredDocuments");
                   java.util.Set<String> mandatoryDocKeys = new java.util.HashSet<>();
                   mandatoryDocKeys.add("official_application_letter");
                   mandatoryDocKeys.add("principal_appointment_letter");
                   mandatoryDocKeys.add("certification_license_file");
                   mandatoryDocKeys.add("test_report_file");
                   mandatoryDocKeys.add("brochure_catalogue");
                   mandatoryDocKeys.add("price_list");
                   mandatoryDocKeys.add("product_benefit_summary");
                   mandatoryDocKeys.add("project_reference");
                   mandatoryDocKeys.add("sop_document");
                   mandatoryDocKeys.add("performance_monitoring_program");
                   if (requiredDocuments != null) {
                       for (Map.Entry<String, String> doc : requiredDocuments.entrySet()) {
                           boolean isMandatory = mandatoryDocKeys.contains(doc.getKey());
                           boolean hasExistingDocument = existingDocumentKeys.contains(doc.getKey());
                %>
                <div class="doc-item">
                    <strong><%= doc.getValue() %><% if (isMandatory && !hasExistingDocument) { %><span class="required-mark">*</span><% } %></strong>
                    <% if (hasExistingDocument) { %>
                    <div class="hint" style="margin-bottom:8px;">Dokumen sedia ada telah ditemui dan akan digunakan semula jika tiada fail baharu dimuat naik.</div>
                    <% } %>
                    <input type="file" name="<%= doc.getKey() %>" data-doc-key="<%= doc.getKey() %>" accept="application/pdf" />
                </div>
                <%   }
                   }
                %>
            </div>

            <div class="actions">
                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard">Batal</a>
                <button class="btn btn-primary" type="submit"><%= editMode ? "Kemaskini Permohonan" : "Hantar Permohonan Online" %></button>
            </div>
        </form>

        <div class="container" style="padding-top:0;">
            <div class="jans-contact-section">
<<<<<<< HEAD
                <h3><img class="contact-icon" src="${pageContext.request.contextPath}/icon/contact.png" alt="Hubungi JAS"> Hubungi JAS</h3>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/address.png" alt="Alamat"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/phone.png" alt="Tel"><span>Tel: +60-88-232364 (HQ)</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/fax.png" alt="Fax"><span>Fax: +60-88-232396</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/email.png" alt="Email"><span>Email: jans.hq@sabah.gov.my</span></p>
=======
                <h3>Hubungi JANS</h3>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><span>Tel: +60-88-232364 (HQ) , Fax: +60-88-232396</span></p>
                <p class="contact-line"><span>Email: jans.hq@sabah.gov.my</span></p>
>>>>>>> origin/SPPPA
            </div>
        </div>
    </div>
<script>
(function() {
    var applicationForm = document.getElementById('applicationForm');
    var productArrayList = document.getElementById('productArrayList');
    var addProductBtn = document.getElementById('addProductBtn');
<<<<<<< HEAD
    var applicationTypeField = document.getElementById('application_type');
    var renewalSourceField = document.getElementById('renewalSourceField');
    var renewalSourceSelect = document.getElementById('renewal_source_selector');
    var renewalSourceInput = document.getElementById('renew_from_application_id');
=======
>>>>>>> origin/SPPPA
    var unsuccessfulPopup = document.getElementById('unsuccessfulPopup');
    var popup = document.getElementById('successPopup');
    var mandatoryDocKeys = [
        'official_application_letter',
        'principal_appointment_letter',
        'certification_license_file',
        'test_report_file',
        'brochure_catalogue',
        'price_list',
        'product_benefit_summary',
        'project_reference',
        'sop_document',
        'performance_monitoring_program'
    ];
    var existingDocCsvField = document.getElementById('existingDocKeysCsv');
    var existingDocKeys = new Set(
        existingDocCsvField && existingDocCsvField.value
            ? existingDocCsvField.value.split('|').filter(function(v) { return v && v.trim() !== ''; })
            : []
    );
<<<<<<< HEAD
    var uppercaseFieldNames = new Set([
        'supplier_name',
        'supplier_address',
        'supplier_phone',
        'manufacturer_name',
        'manufacturer_address',
        'manufacturer_phone',
        'principal_name',
        'principal_address',
        'principal_phone',
        'sabah_rep_name',
        'sabah_rep_address',
        'sabah_rep_phone',
        'declaration_name',
        'declaration_position',
        'product_name[]',
        'brand[]',
        'standard_name[]',
        'certification_license[]',
        'test_report_reference[]',
        'product_model[]',
        'product_series[]',
        'product_description[]',
    ]);
=======
>>>>>>> origin/SPPPA

    var initialFormData = {
        application_type: "<%= jsApplicationType %>",
        supplier_email: "<%= jsSupplierEmail %>",
        supplier_phone: "<%= jsSupplierPhone %>",
        supplier_name: "<%= jsSupplierName %>",
        supplier_address: "<%= jsSupplierAddress %>",
        manufacturer_name: "<%= jsManufacturerName %>",
        manufacturer_address: "<%= jsManufacturerAddress %>",
        manufacturer_phone: "<%= jsManufacturerPhone %>",
        principal_name: "<%= jsPrincipalName %>",
        principal_address: "<%= jsPrincipalAddress %>",
        principal_phone: "<%= jsPrincipalPhone %>",
        product_category: "<%= jsProductCategory %>",
        product_name: "<%= jsProductName %>",
        brand: "<%= jsBrand %>",
        standard_name: "<%= jsStandardName %>",
        certification_license: "<%= jsCertificationLicense %>",
        certification_valid_until: "<%= jsCertificationValidUntil %>",
        test_report_reference: "<%= jsTestReportReference %>",
        test_report_date: "<%= jsTestReportDate %>",
        warranty_years: "<%= jsWarrantyYears %>",
<<<<<<< HEAD
        product_model: "<%= jsProductModel %>",
        product_series: "<%= jsProductSeries %>",
=======
>>>>>>> origin/SPPPA
        product_description: "<%= jsProductDescription %>",
        sabah_rep_name: "<%= jsSabahRepName %>",
        sabah_rep_address: "<%= jsSabahRepAddress %>",
        sabah_rep_phone: "<%= jsSabahRepPhone %>"
    };

<<<<<<< HEAD
    var selectedRenewalSourceId = "<%= toJs(selectedRenewalSourceId) %>";
    var renewalSourceData = JSON.parse("<%= toJs(buildRenewalSourceJson(approvedApplications)) %>" || "{}");

=======
>>>>>>> origin/SPPPA
    function setFieldValue(selector, value) {
        var field = document.querySelector(selector);
        if (!field || value == null || value === '') {
            return;
        }
        field.value = value;
    }
<<<<<<< HEAD

    function forceFieldValue(selector, value) {
        var field = document.querySelector(selector);
        if (!field) {
            return;
        }
        field.value = value == null ? '' : value;
    }

    function shouldForceUppercase(field) {
        if (!field || !field.name) {
            return false;
        }
        return uppercaseFieldNames.has(field.name);
    }

    function forceUppercaseField(field) {
        if (!shouldForceUppercase(field)) {
            return;
        }
        var original = field.value;
        var upper = original == null ? '' : original.toUpperCase();
        if (original === upper) {
            return;
        }
        field.value = upper;
    }

    function normalizeUppercaseFields() {
        if (!applicationForm) {
            return;
        }
        var fields = applicationForm.querySelectorAll('input[type="text"], textarea');
        Array.prototype.forEach.call(fields, forceUppercaseField);
    }
=======
>>>>>>> origin/SPPPA

    function closeUnsuccessfulPopup() {
        if (!unsuccessfulPopup) return;
        unsuccessfulPopup.classList.remove('show');
    }

    if (unsuccessfulPopup) {
        var closeUnsuccessfulBtn = unsuccessfulPopup.querySelector('[data-close-unsuccessful-popup]');
        if (closeUnsuccessfulBtn) closeUnsuccessfulBtn.addEventListener('click', closeUnsuccessfulPopup);
        unsuccessfulPopup.addEventListener('click', function(e) {
            if (e.target === unsuccessfulPopup) closeUnsuccessfulPopup();
        });
    }

    if (applicationForm) {
        function syncProductBlocks() {
            if (!productArrayList) {
                return;
            }
            var fieldConfigs = [
                { name: 'product_category[]', id: 'product_category_' },
                { name: 'product_name[]', id: 'product_name_' },
                { name: 'brand[]', id: 'brand_' },
                { name: 'standard_name[]', id: 'standard_name_' },
                { name: 'certification_license[]', id: 'certification_license_' },
                { name: 'certification_valid_until[]', id: 'certification_valid_until_' },
                { name: 'test_report_reference[]', id: 'test_report_reference_' },
                { name: 'test_report_date[]', id: 'test_report_date_' },
                { name: 'warranty_years[]', id: 'warranty_years_' },
<<<<<<< HEAD
                { name: 'product_model[]', id: 'product_model_' },
                { name: 'product_series[]', id: 'product_series_' },
                { name: 'product_description[]', id: 'product_description_' },
=======
                { name: 'product_description[]', id: 'product_description_' }
>>>>>>> origin/SPPPA
            ];
            var items = Array.prototype.slice.call(productArrayList.querySelectorAll('[data-product-item]'));
            items.forEach(function(item, index) {
                var number = index + 1;
                var title = item.querySelector('.product-item-title');
                if (title) {
                    title.textContent = 'Produk ' + number;
                }
                var removeBtn = item.querySelector('[data-remove-product]');

                fieldConfigs.forEach(function(config) {
                    var field = item.querySelector('[name="' + config.name + '"]');
                    if (!field) {
                        return;
                    }
                    var nextId = config.id + number;
                    field.id = nextId;
                    field.required = true;

                    var label = item.querySelector('label[for^="' + config.id.replace(/_$/, '') + '"]');
                    if (label) {
                        label.setAttribute('for', nextId);
                    }
                });

                if (removeBtn) {
                    removeBtn.hidden = items.length <= 1;
                }
            });
        }

<<<<<<< HEAD
        function keepSingleProductBlock() {
            if (!productArrayList) {
                return;
            }
            var items = Array.prototype.slice.call(productArrayList.querySelectorAll('[data-product-item]'));
            while (items.length > 1) {
                var item = items.pop();
                item.remove();
            }
            syncProductBlocks();
        }

        function applyRenewalSourcePrefill(sourceId) {
            var source = renewalSourceData[sourceId];
            if (!source) {
                return;
            }
            keepSingleProductBlock();
            forceFieldValue('#supplier_email', source.supplier_email);
            forceFieldValue('#supplier_phone', source.supplier_phone);
            forceFieldValue('#supplier_name', source.supplier_name);
            forceFieldValue('#supplier_address', source.supplier_address);
            forceFieldValue('#manufacturer_name', source.manufacturer_name);
            forceFieldValue('#manufacturer_address', source.manufacturer_address);
            forceFieldValue('#manufacturer_phone', source.manufacturer_phone);
            forceFieldValue('#principal_name', source.principal_name);
            forceFieldValue('#principal_address', source.principal_address);
            forceFieldValue('#principal_phone', source.principal_phone);
            forceFieldValue('#product_category_1', source.product_category);
            forceFieldValue('#product_name_1', source.product_name);
            forceFieldValue('#brand_1', source.brand);
            forceFieldValue('#standard_name_1', source.standard_name);
            forceFieldValue('#certification_license_1', source.certification_license);
            forceFieldValue('#certification_valid_until_1', source.certification_valid_until);
            forceFieldValue('#test_report_reference_1', source.test_report_reference);
            forceFieldValue('#test_report_date_1', source.test_report_date);
            forceFieldValue('#warranty_years_1', source.warranty_years);
            forceFieldValue('#product_model_1', source.product_model);
            forceFieldValue('#product_series_1', source.product_series);
            forceFieldValue('#product_description_1', source.product_description);
            forceFieldValue('#sabah_rep_name', source.sabah_rep_name);
            forceFieldValue('#sabah_rep_address', source.sabah_rep_address);
            forceFieldValue('#sabah_rep_phone', source.sabah_rep_phone);
            normalizeUppercaseFields();
        }

        function toggleRenewalSourceField() {
            var isRenewal = applicationTypeField && applicationTypeField.value === 'PEMBAHARUAN';
            if (!renewalSourceField) {
                return;
            }
            renewalSourceField.style.display = isRenewal ? '' : 'none';
            if (!isRenewal) {
                if (renewalSourceSelect) {
                    renewalSourceSelect.value = '';
                }
                if (renewalSourceInput) {
                    renewalSourceInput.value = '';
                }
            }
        }

=======
>>>>>>> origin/SPPPA
        if (addProductBtn && productArrayList) {
            addProductBtn.addEventListener('click', function() {
                var firstItem = productArrayList.querySelector('[data-product-item]');
                if (!firstItem) {
                    return;
                }

                var clone = firstItem.cloneNode(true);
                Array.prototype.slice.call(clone.querySelectorAll('input')).forEach(function(input) {
                    input.value = '';
                });
                Array.prototype.slice.call(clone.querySelectorAll('select')).forEach(function(select) {
                    select.selectedIndex = 0;
                });
                Array.prototype.slice.call(clone.querySelectorAll('textarea')).forEach(function(textarea) {
                    textarea.value = '';
                });

                productArrayList.appendChild(clone);
                syncProductBlocks();
<<<<<<< HEAD
                normalizeUppercaseFields();
=======
>>>>>>> origin/SPPPA
            });

            productArrayList.addEventListener('click', function(event) {
                var removeButton = event.target.closest('[data-remove-product]');
                if (!removeButton) {
                    return;
                }
                var items = productArrayList.querySelectorAll('[data-product-item]');
                if (items.length <= 1) {
                    return;
                }
                var block = removeButton.closest('[data-product-item]');
                if (block) {
                    block.remove();
                    syncProductBlocks();
                }
            });

            syncProductBlocks();
        }

        setFieldValue('#application_type', initialFormData.application_type);
        setFieldValue('#supplier_email', initialFormData.supplier_email);
        setFieldValue('#supplier_phone', initialFormData.supplier_phone);
        setFieldValue('#supplier_name', initialFormData.supplier_name);
        setFieldValue('#supplier_address', initialFormData.supplier_address);
        setFieldValue('#manufacturer_name', initialFormData.manufacturer_name);
        setFieldValue('#manufacturer_address', initialFormData.manufacturer_address);
        setFieldValue('#manufacturer_phone', initialFormData.manufacturer_phone);
        setFieldValue('#principal_name', initialFormData.principal_name);
        setFieldValue('#principal_address', initialFormData.principal_address);
        setFieldValue('#principal_phone', initialFormData.principal_phone);
        setFieldValue('#product_category_1', initialFormData.product_category);
        setFieldValue('#product_name_1', initialFormData.product_name);
        setFieldValue('#brand_1', initialFormData.brand);
        setFieldValue('#standard_name_1', initialFormData.standard_name);
        setFieldValue('#certification_license_1', initialFormData.certification_license);
        setFieldValue('#certification_valid_until_1', initialFormData.certification_valid_until);
        setFieldValue('#test_report_reference_1', initialFormData.test_report_reference);
        setFieldValue('#test_report_date_1', initialFormData.test_report_date);
        setFieldValue('#warranty_years_1', initialFormData.warranty_years);
<<<<<<< HEAD
        setFieldValue('#product_model_1', initialFormData.product_model);
        setFieldValue('#product_series_1', initialFormData.product_series);
=======
>>>>>>> origin/SPPPA
        setFieldValue('#product_description_1', initialFormData.product_description);
        setFieldValue('#sabah_rep_name', initialFormData.sabah_rep_name);
        setFieldValue('#sabah_rep_address', initialFormData.sabah_rep_address);
        setFieldValue('#sabah_rep_phone', initialFormData.sabah_rep_phone);
<<<<<<< HEAD
        normalizeUppercaseFields();

        applicationForm.addEventListener('input', function(event) {
            forceUppercaseField(event.target);
        });

        if (renewalSourceSelect && selectedRenewalSourceId) {
            renewalSourceSelect.value = selectedRenewalSourceId;
        }
        if (renewalSourceInput && selectedRenewalSourceId) {
            renewalSourceInput.value = selectedRenewalSourceId;
        }
        toggleRenewalSourceField();

        if (applicationTypeField) {
            applicationTypeField.addEventListener('change', function() {
                toggleRenewalSourceField();
                if (applicationTypeField.value !== 'PEMBAHARUAN') {
                    return;
                }
                var selectedId = renewalSourceSelect ? renewalSourceSelect.value : '';
                if (renewalSourceInput) {
                    renewalSourceInput.value = selectedId;
                }
                if (selectedId) {
                    applyRenewalSourcePrefill(selectedId);
                }
            });
        }

        if (renewalSourceSelect) {
            renewalSourceSelect.addEventListener('change', function() {
                var selectedId = renewalSourceSelect.value;
                if (renewalSourceInput) {
                    renewalSourceInput.value = selectedId;
                }
                if (selectedId) {
                    applyRenewalSourcePrefill(selectedId);
                }
            });

            if (applicationTypeField && applicationTypeField.value === 'PEMBAHARUAN' && renewalSourceSelect.value) {
                applyRenewalSourcePrefill(renewalSourceSelect.value);
            }
        }
=======
>>>>>>> origin/SPPPA

        applicationForm.addEventListener('submit', function(e) {
            var applicationType = applicationTypeField ? applicationTypeField.value : '';
            var keysToCheck = mandatoryDocKeys.slice();

            if (applicationType === 'PEMBAHARUAN') {
                var selectedRenewalId = renewalSourceSelect ? renewalSourceSelect.value : '';
                if (!selectedRenewalId) {
                    e.preventDefault();
                    window.alert('Sila pilih produk diluluskan untuk pembaharuan.');
                    if (renewalSourceSelect) {
                        renewalSourceSelect.focus();
                    }
                    return;
                }
                if (renewalSourceInput) {
                    renewalSourceInput.value = selectedRenewalId;
                }
                keysToCheck.push('renewal_certificate');
            }

            var hasMissingRequiredDoc = keysToCheck.some(function(docKey) {
                var fileInput = applicationForm.querySelector('input[type="file"][data-doc-key="' + docKey + '"]');
                var hasNewUpload = fileInput && fileInput.files && fileInput.files.length > 0;
                return !hasNewUpload && !existingDocKeys.has(docKey);
            });

            if (hasMissingRequiredDoc) {
                e.preventDefault();
                if (unsuccessfulPopup) {
                    unsuccessfulPopup.classList.add('show');
                }
            }
        });
    }

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
