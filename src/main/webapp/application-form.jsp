<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Borang Permohonan Online PPP1 - SPPA</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; background: linear-gradient(180deg, #eff9ff 0%, #f7fbfd 100%); color: #223; }
        .navbar { background: linear-gradient(130deg, #06344f 0%, #0097d9 74%, #fff212 190%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand img { width: 48px; background: white; border-radius: 14px; padding: 6px; }
        .brand strong { display: block; }
        .brand span { font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; }
        .container { max-width: 1100px; margin: 28px auto; padding: 0 20px; }
        .panel { background: white; border-radius: 12px; box-shadow: 0 12px 30px rgba(16, 24, 40, 0.08); padding: 24px; margin-bottom: 24px; }
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
        .doc-list { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
        .doc-item { padding: 14px; border: 1px solid #dbe2ea; border-radius: 10px; background: #fcfdff; }
        .doc-item strong { display: block; margin-bottom: 8px; font-size: 14px; }
        .actions { display: flex; gap: 12px; justify-content: flex-end; margin-top: 20px; }
        .btn { border: none; border-radius: 8px; padding: 12px 18px; font-size: 14px; cursor: pointer; text-decoration: none; }
        .btn-secondary { background: #e2e8f0; color: #1e293b; }
        .btn-primary { background: linear-gradient(135deg, #06344f 0%, #0097d9 100%); color: white; }
        @media (max-width: 900px) { .hero, .grid, .grid-3, .doc-list { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" alt="Logo Jabatan Air Sabah">
            <div>
                <strong>SPPA - Permohonan Online PPP1</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div>
            <a href="${pageContext.request.contextPath}/dashboard">Kembali ke Dashboard</a>
            <a href="${pageContext.request.contextPath}/logout">Log Keluar</a>
        </div>
    </div>

    <div class="container">
        <% if (request.getAttribute("error") != null) { %>
            <div class="alert error"><%= request.getAttribute("error") %></div>
        <% } %>
        <% if (request.getParameter("success") != null) { %>
            <div class="alert success">Permohonan online berjaya dihantar. ID permohonan anda ialah <strong>#<%= request.getParameter("id") %></strong>.</div>
        <% } %>

        <div class="panel hero">
            <div>
                <span class="badge">PPP1 + PPP2 + Garis Panduan JANS</span>
                <h1>Borang Permohonan Pendaftaran Pembekal dan Produk Bekalan Air</h1>
                <p>
                    Borang online ini menggantikan pengisian manual PPP1. Pemohon perlu mengisi maklumat pembekal, produk,
                    dan sokongan teknikal dengan lengkap, kemudian memuat naik dokumen sokongan dalam format PDF mengikut PPP2
                    dan garis panduan pendaftaran pembekal dan produk bekalan air.
                </p>
                <p>
                    Permohonan baharu dan pembaharuan kedua-duanya disokong. Untuk pembaharuan, sijil/perakuan lama JANS perlu
                    dilampirkan dan pembaharuan perlu dibuat sekurang-kurangnya enam bulan sebelum tarikh tamat.
                </p>
            </div>
            <div class="docs-box">
                <strong>Rujukan Asal</strong>
                <a href="${pageContext.request.contextPath}/assets/forms/borang-ppp1-permohonan-pendaftaran-pembekal-produk_0.pdf" target="_blank">Borang PPP1</a>
                <a href="${pageContext.request.contextPath}/assets/forms/borang-ppp2-senarai-semak-pendaftaran-pembekal-produk_0.pdf" target="_blank">Senarai Semak PPP2</a>
                <a href="${pageContext.request.contextPath}/assets/forms/garis-panduan-pendaftaran-pembekal-dan-produk-bekalan-air.pdf" target="_blank">Garis Panduan Pendaftaran</a>
            </div>
        </div>

        <form class="panel" method="post" action="${pageContext.request.contextPath}/applications/new" enctype="multipart/form-data">
            <h2 class="section-title">Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal</h2>
            <div class="grid-3">
                <div class="field">
                    <label for="application_type">Jenis Permohonan</label>
                    <select id="application_type" name="application_type" required>
                        <option value="">Pilih</option>
                        <option value="BAHARU">Baharu</option>
                        <option value="PEMBAHARUAN">Pembaharuan</option>
                    </select>
                </div>
                <div class="field">
                    <label for="supplier_email">Email Pembekal</label>
                    <input id="supplier_email" name="supplier_email" type="email" placeholder="contoh@syarikat.com" />
                </div>
                <div class="field">
                    <label for="supplier_phone">No. Telefon Pembekal</label>
                    <input id="supplier_phone" name="supplier_phone" type="text" placeholder="088-123456" />
                </div>
            </div>

            <div class="grid">
                <div class="field full">
                    <label for="supplier_name">Nama Syarikat Pembekal</label>
                    <input id="supplier_name" name="supplier_name" type="text" required />
                </div>
                <div class="field full">
                    <label for="supplier_address">Alamat Pejabat Pembekal</label>
                    <textarea id="supplier_address" name="supplier_address" required></textarea>
                </div>
                <div class="field full">
                    <label for="manufacturer_name">Nama Syarikat Pembuat / Pengilang</label>
                    <input id="manufacturer_name" name="manufacturer_name" type="text" />
                </div>
                <div class="field full">
                    <label for="manufacturer_address">Alamat Pejabat Pembuat / Pengilang</label>
                    <textarea id="manufacturer_address" name="manufacturer_address"></textarea>
                </div>
                <div class="field">
                    <label for="manufacturer_phone">No. Telefon Pengilang</label>
                    <input id="manufacturer_phone" name="manufacturer_phone" type="text" />
                </div>
                <div class="field"></div>
                <div class="field full">
                    <label for="principal_name">Nama Syarikat Prinsipal / Pemilik Produk</label>
                    <input id="principal_name" name="principal_name" type="text" />
                </div>
                <div class="field full">
                    <label for="principal_address">Alamat Pejabat Prinsipal / Pemilik Produk</label>
                    <textarea id="principal_address" name="principal_address"></textarea>
                </div>
                <div class="field">
                    <label for="principal_phone">No. Telefon Prinsipal</label>
                    <input id="principal_phone" name="principal_phone" type="text" />
                </div>
            </div>

            <h2 class="section-title">Bahagian B: Maklumat Produk</h2>
            <div class="grid-3">
                <div class="field">
                    <label for="product_category">Kategori Produk</label>
                    <select id="product_category" name="product_category" required>
                        <option value="">Pilih kategori</option>
                        <option value="Water Treatment Equipment">Water Treatment Equipment</option>
                        <option value="Conveyance Of Water">Conveyance Of Water</option>
                        <option value="Flow Control">Flow Control</option>
                        <option value="Measuring Device">Measuring Device</option>
                        <option value="Chemical For Water Treatment">Chemical For Water Treatment</option>
                        <option value="Storage Of Water">Storage Of Water</option>
                        <option value="Sanitary">Sanitary</option>
                        <option value="Lining">Lining</option>
                        <option value="Coating">Coating</option>
                        <option value="Waterproofing">Waterproofing</option>
                        <option value="Sealant">Sealant</option>
                        <option value="Adhesive">Adhesive</option>
                        <option value="Solvent Cement">Solvent Cement</option>
                    </select>
                </div>
                <div class="field">
                    <label for="product_name">Nama Produk</label>
                    <input id="product_name" name="product_name" type="text" required />
                </div>
                <div class="field">
                    <label for="brand">Jenama</label>
                    <input id="brand" name="brand" type="text" required />
                </div>
                <div class="field">
                    <label for="standard_name">Piawaian / Standard</label>
                    <input id="standard_name" name="standard_name" type="text" placeholder="MS / BS / ISO / lain-lain" />
                </div>
                <div class="field">
                    <label for="certification_license">Badan Persijilan & No. Lesen</label>
                    <input id="certification_license" name="certification_license" type="text" />
                </div>
                <div class="field">
                    <label for="certification_valid_until">Sah Sehingga</label>
                    <input id="certification_valid_until" name="certification_valid_until" type="date" />
                </div>
                <div class="field">
                    <label for="test_report_reference">Badan Persijilan & No. Laporan Pengujian</label>
                    <input id="test_report_reference" name="test_report_reference" type="text" />
                </div>
                <div class="field">
                    <label for="test_report_date">Tarikh Laporan Pengujian</label>
                    <input id="test_report_date" name="test_report_date" type="date" />
                </div>
                <div class="field">
                    <label for="warranty_years">Tempoh Jaminan Produk (Tahun)</label>
                    <input id="warranty_years" name="warranty_years" type="number" step="0.1" min="0" />
                </div>
                <div class="field full">
                    <label for="product_description">Perihal Produk (Model / Siri / Deskripsi)</label>
                    <textarea id="product_description" name="product_description" required></textarea>
                </div>
            </div>

            <h2 class="section-title">Bahagian C: Sokongan Teknikal di Negeri Sabah</h2>
            <div class="grid">
                <div class="field">
                    <label for="sabah_rep_name">Nama Wakil di Sabah</label>
                    <input id="sabah_rep_name" name="sabah_rep_name" type="text" />
                </div>
                <div class="field">
                    <label for="sabah_rep_phone">No. Telefon Wakil</label>
                    <input id="sabah_rep_phone" name="sabah_rep_phone" type="text" />
                </div>
                <div class="field full">
                    <label for="sabah_rep_address">Alamat Pejabat Wakil di Sabah</label>
                    <textarea id="sabah_rep_address" name="sabah_rep_address"></textarea>
                </div>
            </div>

            <h2 class="section-title">Bahagian D: Dokumen Sokongan (PPP2)</h2>
            <p class="hint">Muat naik dokumen dalam format PDF. Untuk pembaharuan, lampiran sijil/perakuan lama adalah wajib. Medan “jika ada” boleh dibiarkan kosong.</p>
            <div class="doc-list">
                <% Map<String, String> requiredDocuments = (Map<String, String>) request.getAttribute("requiredDocuments");
                   if (requiredDocuments != null) {
                       for (Map.Entry<String, String> doc : requiredDocuments.entrySet()) {
                %>
                <div class="doc-item">
                    <strong><%= doc.getValue() %></strong>
                    <input type="file" name="<%= doc.getKey() %>" accept="application/pdf" />
                </div>
                <%   }
                   }
                %>
            </div>

            <h2 class="section-title">Pengesahan Pemohon</h2>
            <div class="grid">
                <div class="field">
                    <label for="declaration_name">Nama Pemohon</label>
                    <input id="declaration_name" name="declaration_name" type="text" required />
                </div>
                <div class="field">
                    <label for="declaration_position">Jawatan</label>
                    <input id="declaration_position" name="declaration_position" type="text" required />
                </div>
            </div>

            <div class="actions">
                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard">Batal</a>
                <button class="btn btn-primary" type="submit">Hantar Permohonan Online</button>
            </div>
        </form>

        <div class="panel" style="padding:18px;">
            <strong style="display:block;margin-bottom:12px;">Hubungi Jabatan Air Sabah</strong>
            <img src="${pageContext.request.contextPath}/assets/images/contact-jans.png" alt="Maklumat hubungan Jabatan Air Sabah" style="width:100%;max-width:420px;border-radius:12px;border:1px solid #d8e1ee;">
        </div>
    </div>
</body>
</html>