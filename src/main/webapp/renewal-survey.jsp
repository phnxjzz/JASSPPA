<<<<<<< HEAD
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Borang KSPP Pembaharuan</title>
    <style>
* { box-sizing: border-box; }
        body { margin: 0; font-family: inherit; background: #edf1f5; color: #111; }
        .screen-bar {
            background: #1b2a52; color: #fff; padding: 10px 22px;
            display: flex; justify-content: space-between; align-items: center; font-size: 14px;
        }
        .screen-bar a { color: #fff; text-decoration: none; margin-left: 14px; }
        .btn-row {
            display: flex; gap: 10px; justify-content: center; padding: 16px 18px 12px; flex-wrap: wrap;
        }
        .btn {
            border: none; border-radius: 6px; padding: 10px 22px; font-size: 14px;
            text-decoration: none; display: inline-flex; align-items: center; gap: 6px; cursor: pointer;
            color: #fff;
        }
        .btn-print { background: #1b2a52; }
        .btn-pdf { background: #2e7d32; }
        .btn-cert { background: #0f766e; }
        .btn:hover { opacity: 0.92; }
        .page-wrap { max-width: 980px; margin: 0 auto 40px; padding: 0 18px; }
        .form-page {
            background: #fff; padding: 34px 28px 38px; border: 1px solid #cfd6df; box-shadow: 0 12px 28px rgba(0,0,0,0.08);
        }
        .title { text-align: center; margin-bottom: 24px; }
        .title h1, .title h2, .title h3, .title h4 { margin: 0; }
        .title h1 { font-size: 20px; }
        .title h2, .title h3, .title h4 { font-size: 17px; margin-top: 5px; }
        .section-title { font-size: 16px; font-weight: 700; margin: 20px 0 8px; }
        .section-note { font-size: 13px; margin-bottom: 10px; }
        .two-col-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .two-col-table td {
            border: 1px solid #111; padding: 0; vertical-align: top;
        }
        .label-cell { width: 34%; padding: 10px 12px; font-size: 14px; }
        .input-cell { width: 66%; padding: 0; }
        .input-cell input, .input-cell textarea {
            width: 100%; border: 0; padding: 10px 12px; font-size: 14px; min-height: 42px; font-family: inherit;
        }
        .input-cell textarea { resize: vertical; min-height: 72px; }
        .question-table { width: 100%; border-collapse: collapse; margin-top: 8px; }
        .question-table th, .question-table td { border: 1px solid #111; padding: 8px; font-size: 13px; vertical-align: top; }
        .question-table th { text-align: center; }
        .question-no { width: 6%; text-align: center; }
        .question-text { width: 58%; }
        .question-select { width: 16%; }
        .question-note { width: 20%; }
        .question-table select, .question-table input {
            width: 100%; border: 1px solid #cbd5e1; border-radius: 4px; padding: 7px 8px; font-size: 13px;
        }
        .disclaimer {
            background: #fff8e1; border: 1px solid #eab308; padding: 10px 12px; font-size: 13px; margin: 14px 0 18px;
        }
        .line-text { width: 100%; border: none; border-bottom: 1px solid #111; padding: 6px 2px; font-size: 14px; }
        .signature-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-top: 18px; }
        .signature-grid .field { display: flex; flex-direction: column; gap: 8px; }
        .footer-space { margin-top: 16px; }
        @media (max-width: 760px) {
            .form-page { padding: 24px 14px 28px; }
            .signature-grid { grid-template-columns: 1fr; }
            .question-table { display: block; overflow-x: auto; }
        }
        @media print {
            body { background: #fff; }
            .screen-bar, .btn-row, .disclaimer { display: none !important; }
            .page-wrap { max-width: 100%; padding: 0; margin: 0; }
            .form-page { box-shadow: none; border: none; padding: 12px 0 0; }
        }
    </style>
</head>
<body>
<%
    Map<String, Object> renewalApp = (Map<String, Object>) request.getAttribute("renewalApp");
    List<String> questions = (List<String>) request.getAttribute("questions");
    int appId = ((Number) renewalApp.get("id")).intValue();
    String storageKey = "kspp-renewal-form-" + appId;
    String productName = renewalApp.get("product_name") == null ? "" : String.valueOf(renewalApp.get("product_name"));
    String brand = renewalApp.get("brand") == null ? "" : String.valueOf(renewalApp.get("brand"));
    String productDescription = renewalApp.get("product_description") == null ? "" : String.valueOf(renewalApp.get("product_description"));
    String supplierName = renewalApp.get("supplier_name") == null ? "" : String.valueOf(renewalApp.get("supplier_name"));
%>
<div class="screen-bar">
    <span style="font-weight:700;">&#128196; Borang KSPP Pembaharuan</span>
    <div>
        <a href="javascript:history.back()">&#8592; Kembali</a>
        <a href="${pageContext.request.contextPath}/dashboard" title="Dashboard" aria-label="Dashboard"><img src="${pageContext.request.contextPath}/icon/dashboard.png" alt="Dashboard" style="width:18px;height:18px;object-fit:contain;vertical-align:middle;"></a>
    </div>
</div>

<div class="btn-row">
    <button class="btn btn-print" type="button" onclick="window.print()">&#128438; Cetak</button>
    <a class="btn btn-pdf" href="<%= request.getContextPath() %>/renewal-form/pdf?id=<%= appId %>" download>&#128229; Muat Turun PDF</a>
    <a class="btn btn-cert" href="<%= request.getContextPath() %>/certificate?id=<%= appId %>">&#128196; Kembali ke Sijil</a>
</div>

<div class="page-wrap">
    <div class="disclaimer">Borang ini boleh diisi terus dalam pelayar. Isian disimpan sementara pada peranti ini sahaja sehingga anda membersihkan data pelayar.</div>

    <div class="form-page" id="renewalSurveyForm" data-storage-key="<%= storageKey %>">
        <div class="title">
            <h1>JABATAN AIR SABAH</h1>
            <h2>BORANG KAJI SELIDIK</h2>
            <h3>PRESTASI PEMBEKAL DAN PRODUK BEKALAN AIR</h3>
            <h4>(PEMBAHARUAN)</h4>
        </div>

        <div class="section-title">BAHAGIAN A : MAKLUMAT RESPONDEN</div>
        <table class="two-col-table">
            <tr><td class="label-cell">Nama Penuh</td><td class="input-cell"><input type="text" data-field="respondent_name"></td></tr>
            <tr><td class="label-cell">Cawangan / Jabatan Air Daerah</td><td class="input-cell"><input type="text" data-field="branch"></td></tr>
            <tr><td class="label-cell">Jawatan Hakiki &amp; Gred</td><td class="input-cell"><input type="text" data-field="grade"></td></tr>
            <tr><td class="label-cell">Gelaran Jawatan</td><td class="input-cell"><input type="text" data-field="position"></td></tr>
            <tr><td class="label-cell">Nombor Telefon</td><td class="input-cell"><input type="text" data-field="respondent_phone"></td></tr>
            <tr><td class="label-cell">Emel Rasmi Kerajaan</td><td class="input-cell"><input type="email" data-field="government_email"></td></tr>
            <tr><td class="label-cell">Tempoh berkhidmat</td><td class="input-cell"><input type="text" data-field="service_period"></td></tr>
        </table>

        <div class="section-title">BAHAGIAN B : MAKLUMAT PRODUK</div>
        <table class="two-col-table">
            <tr><td class="label-cell">Nama Produk</td><td class="input-cell"><input type="text" data-field="product_name_b" value="<%= productName %>"></td></tr>
            <tr><td class="label-cell">Jenama</td><td class="input-cell"><input type="text" data-field="brand_b" value="<%= brand %>"></td></tr>
            <tr><td class="label-cell">Perihal Produk<br>(Model/Kelas/Saiz)</td><td class="input-cell"><textarea data-field="product_desc_b"><%= productDescription %></textarea></td></tr>
            <tr><td class="label-cell">Tarikh Mula &amp; Siap</td><td class="input-cell"><input type="text" data-field="start_finish_date"></td></tr>
            <tr><td class="label-cell">% Siap</td><td class="input-cell"><input type="text" data-field="completion_percentage"></td></tr>
        </table>

        <div class="section-title">BAHAGIAN C : MAKLUMAT PEMBEKAL DAN PRODUK</div>
        <table class="two-col-table">
            <tr><td class="label-cell">Nama Pembekal</td><td class="input-cell"><input type="text" data-field="supplier_name_c" value="<%= supplierName %>"></td></tr>
            <tr><td class="label-cell">Nama Produk</td><td class="input-cell"><input type="text" data-field="product_name_c" value="<%= productName %>"></td></tr>
            <tr><td class="label-cell">Jenama</td><td class="input-cell"><input type="text" data-field="brand_c" value="<%= brand %>"></td></tr>
            <tr><td class="label-cell">Perihal Produk<br>(Model/Kelas/Saiz/dll)</td><td class="input-cell"><textarea data-field="product_desc_c"><%= productDescription %></textarea></td></tr>
        </table>

        <p class="section-note"><strong>Nota:</strong> Hanya Borang KSPP ini yang dicetak atas kertas A4 putih (depan &amp; belakang) diterima.</p>

        <div class="section-title">BAHAGIAN D : PRESTASI PEMBEKAL DAN PRODUK</div>
        <p class="section-note">Nota: # Sila nyatakan (Ya / Tidak / Tidak Berkenaan)</p>
        <table class="question-table">
            <thead>
                <tr>
                    <th class="question-no">NO</th>
                    <th class="question-text">PERKARA</th>
                    <th class="question-select"># CATATAN</th>
                    <th class="question-note">ULASAN</th>
                </tr>
            </thead>
            <tbody>
                <% for (int i = 0; i < questions.size(); i++) { %>
                <tr>
                    <td class="question-no"><%= i + 1 %></td>
                    <td class="question-text"><%= questions.get(i) %></td>
                    <td class="question-select">
                        <select data-field="question_<%= i + 1 %>_status">
                            <option value=""></option>
                            <option value="Ya">Ya</option>
                            <option value="Tidak">Tidak</option>
                            <option value="Tidak Berkenaan">Tidak Berkenaan</option>
                        </select>
                    </td>
                    <td class="question-note"><input type="text" data-field="question_<%= i + 1 %>_note"></td>
                </tr>
                <% } %>
            </tbody>
        </table>

        <div class="section-title">BAHAGIAN E : ULASAN TERHADAP PEMBAHARUAN PERAKUAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR</div>
        <p>Saya <em>*bersetuju / tidak bersetuju</em> terhadap kelulusan Perakuan Pembaharuan Pendaftaran Pembekal dan Produk tersebut. (Sila potong yang mana tidak berkenaan)</p>
        <div class="footer-space"></div>
        <label for="renewal_comment">Jika tidak bersetuju, sila beri ulasan</label>
        <textarea id="renewal_comment" class="line-text" style="min-height:90px; border:1px solid #111; padding:10px;" data-field="renewal_comment"></textarea>
        <div class="footer-space"></div>
        <p>Saya dengan ini mengesahkan bahawa semua maklumat dan butiran yang dinyatakan dalam Borang Kaji Selidik Prestasi Pembekal dan Produk ini adalah tepat dan benar.</p>

        <div class="signature-grid">
            <div class="field">
                <label>Nama</label>
                <input class="line-text" type="text" data-field="signature_name">
            </div>
            <div class="field">
                <label>Tarikh</label>
                <input class="line-text" type="date" data-field="signature_date">
            </div>
            <div class="field">
                <label>Cop Jawatan</label>
                <input class="line-text" type="text" data-field="job_stamp">
            </div>
        </div>
    </div>
</div>

<script>
(function () {
    const container = document.getElementById('renewalSurveyForm');
    if (!container) return;
    const storageKey = container.dataset.storageKey;
    const fields = Array.from(container.querySelectorAll('[data-field]'));

    function loadSavedValues() {
        try {
            const raw = localStorage.getItem(storageKey);
            if (!raw) return;
            const data = JSON.parse(raw);
            fields.forEach((field) => {
                const key = field.dataset.field;
                if (Object.prototype.hasOwnProperty.call(data, key)) {
                    field.value = data[key];
                }
            });
        } catch (error) {
            console.warn('Tidak dapat memulihkan isian KSPP:', error);
        }
    }

    function saveValues() {
        const data = {};
        fields.forEach((field) => {
            data[field.dataset.field] = field.value || '';
        });
        try {
            localStorage.setItem(storageKey, JSON.stringify(data));
        } catch (error) {
            console.warn('Tidak dapat menyimpan isian KSPP:', error);
        }
    }

    fields.forEach((field) => {
        field.addEventListener('input', saveValues);
        field.addEventListener('change', saveValues);
    });

    loadSavedValues();
})();
</script>
</body>
</html>
=======
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Borang KSPP Pembaharuan</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: Arial, Helvetica, sans-serif; background: #edf1f5; color: #111; }
        .screen-bar {
            background: #1b2a52; color: #fff; padding: 10px 22px;
            display: flex; justify-content: space-between; align-items: center; font-size: 14px;
        }
        .screen-bar a { color: #fff; text-decoration: none; margin-left: 14px; }
        .btn-row {
            display: flex; gap: 10px; justify-content: center; padding: 16px 18px 12px; flex-wrap: wrap;
        }
        .btn {
            border: none; border-radius: 6px; padding: 10px 22px; font-size: 14px;
            text-decoration: none; display: inline-flex; align-items: center; gap: 6px; cursor: pointer;
            color: #fff;
        }
        .btn-print { background: #1b2a52; }
        .btn-pdf { background: #2e7d32; }
        .btn-cert { background: #0f766e; }
        .btn:hover { opacity: 0.92; }
        .page-wrap { max-width: 980px; margin: 0 auto 40px; padding: 0 18px; }
        .form-page {
            background: #fff; padding: 34px 28px 38px; border: 1px solid #cfd6df; box-shadow: 0 12px 28px rgba(0,0,0,0.08);
        }
        .title { text-align: center; margin-bottom: 24px; }
        .title h1, .title h2, .title h3, .title h4 { margin: 0; }
        .title h1 { font-size: 20px; }
        .title h2, .title h3, .title h4 { font-size: 17px; margin-top: 5px; }
        .section-title { font-size: 16px; font-weight: 700; margin: 20px 0 8px; }
        .section-note { font-size: 13px; margin-bottom: 10px; }
        .two-col-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .two-col-table td {
            border: 1px solid #111; padding: 0; vertical-align: top;
        }
        .label-cell { width: 34%; padding: 10px 12px; font-size: 14px; }
        .input-cell { width: 66%; padding: 0; }
        .input-cell input, .input-cell textarea {
            width: 100%; border: 0; padding: 10px 12px; font-size: 14px; min-height: 42px; font-family: inherit;
        }
        .input-cell textarea { resize: vertical; min-height: 72px; }
        .question-table { width: 100%; border-collapse: collapse; margin-top: 8px; }
        .question-table th, .question-table td { border: 1px solid #111; padding: 8px; font-size: 13px; vertical-align: top; }
        .question-table th { text-align: center; }
        .question-no { width: 6%; text-align: center; }
        .question-text { width: 58%; }
        .question-select { width: 16%; }
        .question-note { width: 20%; }
        .question-table select, .question-table input {
            width: 100%; border: 1px solid #cbd5e1; border-radius: 4px; padding: 7px 8px; font-size: 13px;
        }
        .disclaimer {
            background: #fff8e1; border: 1px solid #eab308; padding: 10px 12px; font-size: 13px; margin: 14px 0 18px;
        }
        .line-text { width: 100%; border: none; border-bottom: 1px solid #111; padding: 6px 2px; font-size: 14px; }
        .signature-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-top: 18px; }
        .signature-grid .field { display: flex; flex-direction: column; gap: 8px; }
        .footer-space { margin-top: 16px; }
        @media (max-width: 760px) {
            .form-page { padding: 24px 14px 28px; }
            .signature-grid { grid-template-columns: 1fr; }
            .question-table { display: block; overflow-x: auto; }
        }
        @media print {
            body { background: #fff; }
            .screen-bar, .btn-row, .disclaimer { display: none !important; }
            .page-wrap { max-width: 100%; padding: 0; margin: 0; }
            .form-page { box-shadow: none; border: none; padding: 12px 0 0; }
        }
    </style>
</head>
<body>
<%
    Map<String, Object> renewalApp = (Map<String, Object>) request.getAttribute("renewalApp");
    List<String> questions = (List<String>) request.getAttribute("questions");
    int appId = ((Number) renewalApp.get("id")).intValue();
    String storageKey = "kspp-renewal-form-" + appId;
    String productName = renewalApp.get("product_name") == null ? "" : String.valueOf(renewalApp.get("product_name"));
    String brand = renewalApp.get("brand") == null ? "" : String.valueOf(renewalApp.get("brand"));
    String productDescription = renewalApp.get("product_description") == null ? "" : String.valueOf(renewalApp.get("product_description"));
    String supplierName = renewalApp.get("supplier_name") == null ? "" : String.valueOf(renewalApp.get("supplier_name"));
%>
<div class="screen-bar">
    <span style="font-weight:700;">&#128196; Borang KSPP Pembaharuan</span>
    <div>
        <a href="javascript:history.back()">&#8592; Kembali</a>
        <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
    </div>
</div>

<div class="btn-row">
    <button class="btn btn-print" type="button" onclick="window.print()">&#128438; Cetak</button>
    <a class="btn btn-pdf" href="<%= request.getContextPath() %>/renewal-form/pdf?id=<%= appId %>" download>&#128229; Muat Turun PDF</a>
    <a class="btn btn-cert" href="<%= request.getContextPath() %>/certificate?id=<%= appId %>">&#128196; Kembali ke Sijil</a>
</div>

<div class="page-wrap">
    <div class="disclaimer">Borang ini boleh diisi terus dalam pelayar. Isian disimpan sementara pada peranti ini sahaja sehingga anda membersihkan data pelayar.</div>

    <div class="form-page" id="renewalSurveyForm" data-storage-key="<%= storageKey %>">
        <div class="title">
            <h1>JABATAN AIR SABAH</h1>
            <h2>BORANG KAJI SELIDIK</h2>
            <h3>PRESTASI PEMBEKAL DAN PRODUK BEKALAN AIR</h3>
            <h4>(PEMBAHARUAN)</h4>
        </div>

        <div class="section-title">BAHAGIAN A : MAKLUMAT RESPONDEN</div>
        <table class="two-col-table">
            <tr><td class="label-cell">Nama Penuh</td><td class="input-cell"><input type="text" data-field="respondent_name"></td></tr>
            <tr><td class="label-cell">Cawangan / Jabatan Air Daerah</td><td class="input-cell"><input type="text" data-field="branch"></td></tr>
            <tr><td class="label-cell">Jawatan Hakiki &amp; Gred</td><td class="input-cell"><input type="text" data-field="grade"></td></tr>
            <tr><td class="label-cell">Gelaran Jawatan</td><td class="input-cell"><input type="text" data-field="position"></td></tr>
            <tr><td class="label-cell">Nombor Telefon</td><td class="input-cell"><input type="text" data-field="respondent_phone"></td></tr>
            <tr><td class="label-cell">Emel Rasmi Kerajaan</td><td class="input-cell"><input type="email" data-field="government_email"></td></tr>
            <tr><td class="label-cell">Tempoh berkhidmat</td><td class="input-cell"><input type="text" data-field="service_period"></td></tr>
        </table>

        <div class="section-title">BAHAGIAN B : MAKLUMAT PRODUK</div>
        <table class="two-col-table">
            <tr><td class="label-cell">Nama Produk</td><td class="input-cell"><input type="text" data-field="product_name_b" value="<%= productName %>"></td></tr>
            <tr><td class="label-cell">Jenama</td><td class="input-cell"><input type="text" data-field="brand_b" value="<%= brand %>"></td></tr>
            <tr><td class="label-cell">Perihal Produk<br>(Model/Kelas/Saiz)</td><td class="input-cell"><textarea data-field="product_desc_b"><%= productDescription %></textarea></td></tr>
            <tr><td class="label-cell">Tarikh Mula &amp; Siap</td><td class="input-cell"><input type="text" data-field="start_finish_date"></td></tr>
            <tr><td class="label-cell">% Siap</td><td class="input-cell"><input type="text" data-field="completion_percentage"></td></tr>
        </table>

        <div class="section-title">BAHAGIAN C : MAKLUMAT PEMBEKAL DAN PRODUK</div>
        <table class="two-col-table">
            <tr><td class="label-cell">Nama Pembekal</td><td class="input-cell"><input type="text" data-field="supplier_name_c" value="<%= supplierName %>"></td></tr>
            <tr><td class="label-cell">Nama Produk</td><td class="input-cell"><input type="text" data-field="product_name_c" value="<%= productName %>"></td></tr>
            <tr><td class="label-cell">Jenama</td><td class="input-cell"><input type="text" data-field="brand_c" value="<%= brand %>"></td></tr>
            <tr><td class="label-cell">Perihal Produk<br>(Model/Kelas/Saiz/dll)</td><td class="input-cell"><textarea data-field="product_desc_c"><%= productDescription %></textarea></td></tr>
        </table>

        <p class="section-note"><strong>Nota:</strong> Hanya Borang KSPP ini yang dicetak atas kertas A4 putih (depan &amp; belakang) diterima.</p>

        <div class="section-title">BAHAGIAN D : PRESTASI PEMBEKAL DAN PRODUK</div>
        <p class="section-note">Nota: # Sila nyatakan (Ya / Tidak / Tidak Berkenaan)</p>
        <table class="question-table">
            <thead>
                <tr>
                    <th class="question-no">NO</th>
                    <th class="question-text">PERKARA</th>
                    <th class="question-select"># CATATAN</th>
                    <th class="question-note">ULASAN</th>
                </tr>
            </thead>
            <tbody>
                <% for (int i = 0; i < questions.size(); i++) { %>
                <tr>
                    <td class="question-no"><%= i + 1 %></td>
                    <td class="question-text"><%= questions.get(i) %></td>
                    <td class="question-select">
                        <select data-field="question_<%= i + 1 %>_status">
                            <option value=""></option>
                            <option value="Ya">Ya</option>
                            <option value="Tidak">Tidak</option>
                            <option value="Tidak Berkenaan">Tidak Berkenaan</option>
                        </select>
                    </td>
                    <td class="question-note"><input type="text" data-field="question_<%= i + 1 %>_note"></td>
                </tr>
                <% } %>
            </tbody>
        </table>

        <div class="section-title">BAHAGIAN E : ULASAN TERHADAP PEMBAHARUAN PERAKUAN PENDAFTARAN PEMBEKAL DAN PRODUK BEKALAN AIR</div>
        <p>Saya <em>*bersetuju / tidak bersetuju</em> terhadap kelulusan Perakuan Pembaharuan Pendaftaran Pembekal dan Produk tersebut. (Sila potong yang mana tidak berkenaan)</p>
        <div class="footer-space"></div>
        <label for="renewal_comment">Jika tidak bersetuju, sila beri ulasan</label>
        <textarea id="renewal_comment" class="line-text" style="min-height:90px; border:1px solid #111; padding:10px;" data-field="renewal_comment"></textarea>
        <div class="footer-space"></div>
        <p>Saya dengan ini mengesahkan bahawa semua maklumat dan butiran yang dinyatakan dalam Borang Kaji Selidik Prestasi Pembekal dan Produk ini adalah tepat dan benar.</p>

        <div class="signature-grid">
            <div class="field">
                <label>Nama</label>
                <input class="line-text" type="text" data-field="signature_name">
            </div>
            <div class="field">
                <label>Tarikh</label>
                <input class="line-text" type="date" data-field="signature_date">
            </div>
            <div class="field">
                <label>Cop Jawatan</label>
                <input class="line-text" type="text" data-field="job_stamp">
            </div>
        </div>
    </div>
</div>

<script>
(function () {
    const container = document.getElementById('renewalSurveyForm');
    if (!container) return;
    const storageKey = container.dataset.storageKey;
    const fields = Array.from(container.querySelectorAll('[data-field]'));

    function loadSavedValues() {
        try {
            const raw = localStorage.getItem(storageKey);
            if (!raw) return;
            const data = JSON.parse(raw);
            fields.forEach((field) => {
                const key = field.dataset.field;
                if (Object.prototype.hasOwnProperty.call(data, key)) {
                    field.value = data[key];
                }
            });
        } catch (error) {
            console.warn('Tidak dapat memulihkan isian KSPP:', error);
        }
    }

    function saveValues() {
        const data = {};
        fields.forEach((field) => {
            data[field.dataset.field] = field.value || '';
        });
        try {
            localStorage.setItem(storageKey, JSON.stringify(data));
        } catch (error) {
            console.warn('Tidak dapat menyimpan isian KSPP:', error);
        }
    }

    fields.forEach((field) => {
        field.addEventListener('input', saveValues);
        field.addEventListener('change', saveValues);
    });

    loadSavedValues();
})();
</script>
</body>
</html>
>>>>>>> origin/SPPPA
