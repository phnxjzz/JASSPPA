<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Perakuan Pendaftaran - JANS</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Times New Roman', Times, serif; background: #f0f0f0; color: #1a1a1a; }

        .screen-bar {
            background: #06344f; color: white; padding: 12px 24px;
            display: flex; justify-content: space-between; align-items: center;
        }
        .screen-bar a { color: #fff; text-decoration: none; margin-left: 16px; font-family: sans-serif; font-size: 14px; }

        .page-wrap { max-width: 800px; margin: 30px auto; padding: 0 20px 40px; }

        .cert-card {
            background: white; border: 3px solid #06344f; border-radius: 4px;
            padding: 40px 50px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);
            position: relative;
        }

        /* Watermark / background pattern */
        .cert-card::before {
            content: 'JANS';
            position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%) rotate(-30deg);
            font-size: 140px; font-weight: bold; color: rgba(6,52,79,0.04);
            white-space: nowrap; pointer-events: none; user-select: none;
        }

        .cert-header { text-align: center; margin-bottom: 28px; border-bottom: 2px solid #06344f; padding-bottom: 20px; }
        .cert-logos { display: flex; justify-content: center; gap: 20px; align-items: center; margin-bottom: 12px; }
        .cert-logos img { height: 72px; object-fit: contain; }
        .cert-org-name { font-size: 15px; font-weight: bold; color: #06344f; letter-spacing: 0.5px; }
        .cert-org-sub  { font-size: 13px; color: #334155; margin-top: 2px; }

        .cert-title-block { margin: 18px 0 12px; }
        .cert-title { font-size: 20px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; color: #06344f; }
        .cert-subtitle { font-size: 14px; color: #475569; margin-top: 4px; }
        .cert-ref { font-size: 12px; color: #64748b; margin-top: 6px; }

        .cert-num-box {
            background: #eff8ff; border: 1px solid #bcd9ea;
            border-radius: 6px; padding: 10px 18px; display: inline-block;
            margin: 16px 0;
        }
        .cert-num-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.6px; color: #475569; }
        .cert-num-value { font-size: 22px; font-weight: bold; color: #06344f; letter-spacing: 1px; font-family: 'Courier New', monospace; }

        .cert-body { font-size: 14px; line-height: 1.8; }
        .cert-body p { margin-bottom: 10px; }
        .cert-body strong { font-weight: bold; }

        .cert-table { width: 100%; border-collapse: collapse; margin: 18px 0; }
        .cert-table td { padding: 8px 12px; vertical-align: top; font-size: 14px; }
        .cert-table td:first-child { width: 42%; color: #475569; }
        .cert-table td:nth-child(2) { width: 4%; color: #475569; }
        .cert-table td:last-child { font-weight: 600; color: #1e293b; }
        .cert-table tr { border-bottom: 1px solid #f1f5f9; }

        .cert-validity {
            margin: 22px 0; background: #f0fdf4; border: 1px solid #86efac;
            border-radius: 6px; padding: 14px 18px;
        }
        .cert-validity .v-label { font-size: 12px; text-transform: uppercase; letter-spacing: 0.6px; color: #16a34a; margin-bottom: 4px; }
        .cert-validity .v-date { font-size: 16px; font-weight: bold; color: #15803d; }

        .cert-expiry-warn {
            background: #fff7ed; border: 1px solid #fed7aa; border-radius: 6px; padding: 10px 14px;
            font-size: 13px; color: #c2410c; margin-bottom: 12px;
        }

        .cert-footer { margin-top: 40px; display: flex; justify-content: space-between; align-items: flex-end; }
        .cert-signatory { text-align: center; min-width: 220px; }
        .cert-sig-line { border-top: 1.5px solid #1e293b; margin: 50px auto 6px; width: 180px; }
        .cert-sig-name { font-weight: bold; font-size: 14px; }
        .cert-sig-title { font-size: 13px; color: #475569; }
        .cert-sig-org { font-size: 12px; color: #64748b; }

        .cert-seal { width: 100px; height: 100px; border: 3px solid #06344f; border-radius: 50%;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            color: #06344f; font-size: 11px; font-weight: bold; text-align: center; letter-spacing: 0.5px;
            opacity: 0.35; }

        .cert-qr-note { font-size: 11px; color: #94a3b8; text-align: center; margin-top: 20px; border-top: 1px solid #e2e8f0; padding-top: 12px; }

        .print-btn-area { text-align: center; margin: 20px 0 10px; }
        .print-btn {
            background: #06344f; color: white; border: none; border-radius: 8px;
            padding: 12px 28px; font-size: 15px; cursor: pointer; font-family: sans-serif;
        }
        .print-btn:hover { background: #0f5a85; }

        @media print {
            body { background: white; }
            .screen-bar, .print-btn-area { display: none !important; }
            .page-wrap { margin: 0; padding: 0; max-width: 100%; }
            .cert-card { box-shadow: none; border-color: #888; }
        }
    </style>
</head>
<body>
<%
    Map<String, Object> certApp = (Map<String, Object>) request.getAttribute("certApp");
    String certNumber   = String.valueOf(certApp.get("certificate_number"));
    String companyName  = String.valueOf(certApp.get("company_name"));
    String applicantName = String.valueOf(certApp.get("applicant_name"));
    String productName  = String.valueOf(certApp.get("product_name"));
    String productCat   = String.valueOf(certApp.get("product_category"));
    String supplierName = certApp.get("supplier_name") != null ? String.valueOf(certApp.get("supplier_name")) : companyName;
    String stdName      = certApp.get("standard_name") != null ? String.valueOf(certApp.get("standard_name")) : "-";
    String appType      = certApp.get("application_type") != null ? String.valueOf(certApp.get("application_type")) : "BAHARU";
    int appId           = ((Number) certApp.get("id")).intValue();

    DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd MMMM yyyy", new java.util.Locale("ms", "MY"));
    DateTimeFormatter fmtEn = DateTimeFormatter.ofPattern("dd MMMM yyyy");

    java.sql.Date issuedAtSql = (java.sql.Date) certApp.get("issued_at");
    java.sql.Date validUntilSql = (java.sql.Date) certApp.get("valid_until");
    LocalDate issuedAt   = issuedAtSql  != null ? issuedAtSql.toLocalDate()  : LocalDate.now();
    LocalDate validUntil = validUntilSql != null ? validUntilSql.toLocalDate() : LocalDate.now().plusYears(2);

    boolean expiringSoon = !validUntil.isAfter(LocalDate.now().plusMonths(6));
    boolean expired      = validUntil.isBefore(LocalDate.now());

    String issuedStr = issuedAt.format(fmtEn);
    String validStr  = validUntil.format(fmtEn);
%>

<div class="screen-bar">
    <span style="font-family:sans-serif;font-weight:bold;">&#128196; Perakuan Pendaftaran JANS</span>
    <div>
        <a href="javascript:history.back()">&#8592; Kembali</a>
        <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
    </div>
</div>

<div class="page-wrap">

    <div class="print-btn-area">
        <button class="print-btn" onclick="window.print()">&#128438; Cetak / Simpan sebagai PDF</button>
    </div>

    <div class="cert-card">

        <div class="cert-header">
            <div class="cert-logos">
                <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" alt="Logo Sabah">
                <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" alt="Logo JANS">
            </div>
            <div class="cert-org-name">JABATAN AIR NEGERI SABAH (JANS)</div>
            <div class="cert-org-sub">Kementerian Infrastruktur dan Pembangunan Luar Bandar, Sabah</div>
            <div class="cert-org-sub">Peti Surat 11473, 88815 Kota Kinabalu, Sabah &nbsp;|&nbsp; Tel: +60-88-232364 &nbsp;|&nbsp; jans.hq@sabah.gov.my</div>

            <div class="cert-title-block">
                <div class="cert-title">Perakuan Pendaftaran Pembekal Dan Produk Bekalan Air</div>
                <div class="cert-subtitle">Registration Certificate — Water Supply Products &amp; Suppliers</div>
                <div class="cert-ref">Rujukan: JANS/GP/PPPBA | Versi 1 | Tarikh Isu: 27/05/2024</div>
            </div>

            <div class="cert-num-box">
                <div class="cert-num-label">Nombor Perakuan / Certificate Number</div>
                <div class="cert-num-value"><%= certNumber %></div>
            </div>
        </div>

        <div class="cert-body">
            <p>Ini adalah untuk memperakukan bahawa syarikat/pembekal yang tersenarai di bawah telah berjaya
            mendaftarkan produk bekalan air mereka dengan Jabatan Air Negeri Sabah (JANS) dan dibenarkan
            untuk membekalkan produk tersebut kepada projek-projek bekalan air di bawah bidang kuasa JANS.</p>

            <% if (expired) { %>
            <div class="cert-expiry-warn">&#9888; AMARAN: Perakuan ini telah TAMAT TEMPOH pada <%= validStr %>.
            Pembekal perlu mengemukakan permohonan pembaharuan segera.</div>
            <% } else if (expiringSoon) { %>
            <div class="cert-expiry-warn">&#9888; PERINGATAN: Perakuan ini akan tamat tempoh pada <%= validStr %>.
            Sila kemukakan pembaharuan sekurang-kurangnya 6 bulan sebelum tarikh tamat.</div>
            <% } %>

            <table class="cert-table">
                <tr>
                    <td>No. Permohonan</td><td>:</td>
                    <td>#<%= appId %> (<%= appType %>)</td>
                </tr>
                <tr>
                    <td>Nama Syarikat / Pembekal</td><td>:</td>
                    <td><%= companyName %></td>
                </tr>
                <tr>
                    <td>Nama Pemohon</td><td>:</td>
                    <td><%= applicantName %></td>
                </tr>
                <tr>
                    <td>Nama Produk</td><td>:</td>
                    <td><%= productName %></td>
                </tr>
                <tr>
                    <td>Kategori Produk</td><td>:</td>
                    <td><%= productCat %></td>
                </tr>
                <tr>
                    <td>Standard / Persijilan</td><td>:</td>
                    <td><%= stdName %></td>
                </tr>
                <tr>
                    <td>Tarikh Dikeluarkan</td><td>:</td>
                    <td><%= issuedStr %></td>
                </tr>
            </table>

            <div class="cert-validity">
                <div class="v-label">&#9989; Sah Sehingga / Valid Until</div>
                <div class="v-date"><%= validStr %></div>
            </div>

            <p style="font-size:13px;color:#475569;">
                Perakuan Pendaftaran ini dikeluarkan tertakluk kepada Garis Panduan Pendaftaran Pembekal dan Produk
                Bekalan Air JANS (Rujukan JANS/GP/PPPBA). Pendaftaran ini hanya sah sehingga tarikh tamat tempoh
                dan boleh dibatalkan oleh JANS pada bila-bila masa jika syarat-syarat pendaftaran tidak dipatuhi.
                Pembaharuan hendaklah dikemukakan tidak lewat daripada enam (6) bulan sebelum tarikh tamat tempoh.
            </p>
        </div>

        <div class="cert-footer">
            <div class="cert-signatory">
                <div class="cert-sig-line"></div>
                <div class="cert-sig-name">Pengarah</div>
                <div class="cert-sig-title">Jabatan Air Negeri Sabah</div>
                <div class="cert-sig-org">Kota Kinabalu, Sabah</div>
            </div>
            <div class="cert-seal">
                <div>JANS</div>
                <div style="font-size:9px;margin-top:2px;">JABATAN AIR</div>
                <div style="font-size:9px;">NEGERI SABAH</div>
            </div>
        </div>

        <div class="cert-qr-note">
            Perakuan ini adalah rekod rasmi digital SPPA. Untuk pengesahan, hubungi jans.hq@sabah.gov.my
            atau semak laman web rasmi Jabatan Air Negeri Sabah.
        </div>

    </div><!-- /cert-card -->

</div><!-- /page-wrap -->
</body>
</html>
