<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%!
    private String formatCertificateNumber(Object value) {
        if (value == null) {
            return "-";
        }
        String raw = String.valueOf(value).trim();
        if (raw.isEmpty() || "null".equalsIgnoreCase(raw) || "-".equals(raw)) {
            return "-";
        }

        String compact = raw.replaceAll("\\s+", "").toUpperCase(java.util.Locale.ROOT);
        java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("^JANS([A-Z0-9]+)$", java.util.regex.Pattern.CASE_INSENSITIVE)
                .matcher(compact);
        if (matcher.find()) {
            String token = matcher.group(1).toUpperCase(java.util.Locale.ROOT);
            if (token.matches("\\d+") && token.length() < 6) {
                token = String.format("%06d", Integer.parseInt(token));
            }
            return "JANS" + token;
        }
        return compact;
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Perakuan Pendaftaran - JANS</title>
    <style>
* { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: inherit; background: #e8e8e8; color: #111; }

        /* ── screen toolbar ── */
        .screen-bar {
            background: #1b2a52; color: white; padding: 10px 22px;
            display: flex; justify-content: space-between; align-items: center;
            font-size: 14px;
        }
        .screen-bar a { color: #fff; text-decoration: none; margin-left: 14px; }

        /* ── button row ── */
        .btn-row {
            display: flex; gap: 10px; justify-content: center;
            padding: 16px 0 12px; flex-wrap: wrap;
        }
        .btn {
            border: none; border-radius: 6px; padding: 10px 24px;
            font-size: 14px; cursor: pointer; font-family: inherit;
            text-decoration: none; display: inline-flex; align-items: center; gap: 6px;
        }
        .btn-print { background: #1b2a52; color: #fff; }
        .btn-pdf   { background: #2e7d32; color: #fff; }
        .btn-print:hover { background: #2e4080; }
        .btn-pdf:hover   { background: #1b5e20; }

        /* ── A4 page ── */
        .page-wrap { max-width: 794px; margin: 0 auto 40px; padding: 0 20px; }

        .cert-page {
            background: #fff;
            border: 2.5px solid #1b2a52;
            outline: 1px solid #1b2a52;
            outline-offset: -9px;
            position: relative;
            padding: 50px 60px 44px;
            min-height: 1050px;
        }

        /* watermark */
        .cert-page::before {
            content: '';
            position: absolute; top: 50%; left: 50%;
            transform: translate(-50%, -52%);
            width: 340px; height: 340px;
            background-image: url('${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png');
            background-size: contain; background-repeat: no-repeat; background-position: center;
            opacity: 0.09; pointer-events: none;
        }

        /* ── header ── */
        .cert-header { text-align: center; margin-bottom: 22px; }
        .cert-header img { width: 90px; height: 90px; object-fit: contain; display: block; margin: 0 auto 8px; }
        .cert-org   { font-size: 16px; font-weight: bold; letter-spacing: 0.5px; margin-bottom: 3px; }
        .cert-sub   { font-size: 13px; font-weight: normal; }

        /* ── fields ── */
        .field-table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        .field-table tr td { padding: 8px 0 2px; vertical-align: bottom; font-size: 11.5pt; }
        .field-table .lbl { width: 33%; font-weight: bold; padding-left: 2px; }
        .field-table .colon { width: 4%; }
        .field-table .val {
            border-bottom: 1px solid #111;
            padding-bottom: 3px;
        }
        .field-table .val-multiline {
            white-space: pre-line;
            vertical-align: top;
            line-height: 1.25;
            padding-top: 4px;
            padding-bottom: 6px;
        }

        /* ── product table ── */
        .prod-wrap { margin-top: 22px; }
        .prod-table { width: 100%; border-collapse: collapse; }
        .prod-table th, .prod-table td {
            border: 1px solid #111;
            padding: 0 8px;
            font-size: 11pt;
            text-align: left;
        }
        .prod-table th { font-weight: bold; text-align: center; padding: 8px 4px; }
        .prod-table td { height: 50px; vertical-align: top; padding-top: 6px; }

        /* ── print ── */
        @media print {
            body { background: #fff; }
            .screen-bar, .btn-row { display: none !important; }
            .page-wrap { margin: 0; padding: 0; max-width: 100%; }
            .cert-page { border-color: #1b2a52; outline-color: #1b2a52; box-shadow: none; min-height: auto; }
        }
    </style>
</head>
<body>
<%
    Map<String, Object> certApp = (Map<String, Object>) request.getAttribute("certApp");
    List<Map<String, String>> certProducts = (List<Map<String, String>>) certApp.get("certificate_products");

    String certNumber   = formatCertificateNumber(certApp.get("certificate_number"));
    int    appId        = ((Number) certApp.get("id")).intValue();

    String supplierNm   = certApp.get("supplier_name")       != null ? String.valueOf(certApp.get("supplier_name"))       : "";
    String mfrNm        = certApp.get("manufacturer_name")   != null ? String.valueOf(certApp.get("manufacturer_name"))   : "";
    String principalNm  = certApp.get("principal_name")      != null ? String.valueOf(certApp.get("principal_name"))      : "";
    String productName  = String.valueOf(certApp.get("product_name"));
    String productCat   = String.valueOf(certApp.get("product_category"));
    String stdName      = certApp.get("standard_name")       != null ? String.valueOf(certApp.get("standard_name"))       : "";
    String classSizeModel = certApp.get("certificate_class_size_model") != null ? String.valueOf(certApp.get("certificate_class_size_model")) : "";
    String brandName      = certApp.get("certificate_brand") != null ? String.valueOf(certApp.get("certificate_brand")) : "";
    String productBrief   = certApp.get("certificate_product_brief") != null ? String.valueOf(certApp.get("certificate_product_brief")) : "";

    DateTimeFormatter fmtMs = DateTimeFormatter.ofPattern("dd MMMM yyyy", new java.util.Locale("ms", "MY"));
    java.sql.Date issuedAtSql   = (java.sql.Date) certApp.get("issued_at");
    java.sql.Date validUntilSql = (java.sql.Date) certApp.get("valid_until");
    LocalDate issuedAt   = issuedAtSql  != null ? issuedAtSql.toLocalDate()  : LocalDate.now();
    LocalDate validUntil = validUntilSql != null ? validUntilSql.toLocalDate() : LocalDate.now().plusYears(2);
    String issuedStr = issuedAt.format(fmtMs);
    String validStr  = validUntil.format(fmtMs);
%>

<div class="screen-bar">
    <span style="font-weight:bold;">Perakuan Pendaftaran Produk Air Jabatan Air Sabah</span>
    <div>
        <a href="#" onclick="goBackOrDashboard(event)">&#8592; Kembali</a>
        <a href="${pageContext.request.contextPath}/dashboard" title="Dashboard" aria-label="Dashboard"><img src="${pageContext.request.contextPath}/icon/dashboard.png" alt="Dashboard" style="width:18px;height:18px;object-fit:contain;vertical-align:middle;"></a>
    </div>
</div>

<div class="btn-row">
    <button class="btn btn-print" onclick="window.print()">&#128438; Cetak</button>
    <a class="btn btn-pdf" href="<%= request.getContextPath() %>/certificate/pdf?id=<%= appId %>" download>
        &#128229; Muat Turun PDF
    </a>
</div>

<div class="page-wrap">
<div class="cert-page">

    <!-- header -->
    <div class="cert-header">
        <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png"
             alt="Logo JANS">
        <div class="cert-org">JABATAN AIR SABAH</div>
        <div class="cert-sub">Butiran Pendaftaran</div>
    </div>

    <!-- field list -->
    <table class="field-table">
        <tr>
            <td class="lbl">No Sijil</td>
            <td class="colon">:</td>
            <td class="val"><%= certNumber %></td>
        </tr>
        <tr>
            <td class="lbl">Nama Pembekal</td>
            <td class="colon">:</td>
            <td class="val"><%= supplierNm %></td>
        </tr>
        <tr>
            <td class="lbl">Nama Pengilang</td>
            <td class="colon">:</td>
            <td class="val"><%= mfrNm %></td>
        </tr>
        <tr>
            <td class="lbl">Nama Prinsipal / Pemilik</td>
            <td class="colon">:</td>
            <td class="val"><%= principalNm %></td>
        </tr>
        <tr>
            <td class="lbl">Nama Produk</td>
            <td class="colon">:</td>
            <td class="val"><%= productName %></td>
        </tr>
        <tr>
            <td class="lbl">Kategori</td>
            <td class="colon">:</td>
            <td class="val"><%= productCat %></td>
        </tr>
        <tr>
            <td class="lbl">Kelas/Saiz/Model</td>
            <td class="colon">:</td>
            <td class="val"><%= classSizeModel %></td>
        </tr>
        <tr>
            <td class="lbl">Jenama</td>
            <td class="colon">:</td>
            <td class="val"><%= brandName %></td>
        </tr>
        <tr>
            <td class="lbl">Piawaian</td>
            <td class="colon">:</td>
            <td class="val"><%= stdName %></td>
        </tr>
        <tr>
            <td class="lbl">Tarikh Dikeluarkan</td>
            <td class="colon">:</td>
            <td class="val"><%= issuedStr %></td>
        </tr>
        <tr>
            <td class="lbl">Sah Sehingga</td>
            <td class="colon">:</td>
            <td class="val"><%= validStr %></td>
        </tr>
        <tr>
            <td class="lbl">Perihal Produk</td>
            <td class="colon">:</td>    
            <td class="val val-multiline"><%= productBrief %></td>
        </tr>
    </table>

    <!-- product table -->
    <div class="prod-wrap">
        <table class="prod-table">
            <thead>
                <tr>
                    <th style="width:28%">NAMA PRODUK</th>
                    <th style="width:23%">MODEL</th>
                    <th style="width:16%">SIRI</th>
                    <th style="width:33%">PERIHAL/CLASS/SAIZ</th>
                </tr>
            </thead>
            <tbody>
                <% for (Map<String, String> productRow : certProducts) { %>
                <tr>
                    <td><%= productRow.get("name") %></td>
                    <td><%= productRow.get("model") %></td>
                    <td><%= productRow.get("series") %></td>
                    <td><%= productRow.get("description") %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>

</div><!-- /cert-page -->
</div><!-- /page-wrap -->

<script>
    function goBackOrDashboard(event) {
        event.preventDefault();
        if (window.history.length > 1) {
            window.history.back();
            return;
        }
        window.location.href = '<%= request.getContextPath() %>/dashboard';
    }
</script>

</body>
</html>
