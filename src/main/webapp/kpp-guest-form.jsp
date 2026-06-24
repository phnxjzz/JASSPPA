<<<<<<< HEAD
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.lang.String" %>
<%@ page import="java.util.Map" %>
<%!
    private String escapeJs(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "\\r")
                .replace("\n", "\\n");
    }

    private String safePrefill(Map<String, String> data, String key) {
        if (data == null || key == null) {
            return "";
        }
        String value = data.get(key);
        return value == null ? "" : value;
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Borang Digital KPP Guest</title>
    <style>
* { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: inherit;
            background: #eef4f8;
            color: #0f172a;
        }
        .top {
            background: #123b64;
            color: #fff;
            padding: 12px 18px;
            font-weight: 700;
        }
        .wrap {
            max-width: 980px;
            margin: 18px auto 34px;
            padding: 0 14px;
        }
        .card {
            background: #fff;
            border: 1px solid #d2deea;
            border-radius: 12px;
            box-shadow: 0 14px 30px rgba(2, 44, 74, 0.1);
            padding: 18px;
        }
        .meta {
            background: #f8fbff;
            border: 1px solid #d8e7f7;
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 12px;
            font-size: 0.95rem;
            color: #334155;
        }
        .ok {
            background: #ecfdf3;
            border: 1px solid #86efac;
            color: #166534;
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 12px;
            font-size: 0.93rem;
        }
        .section {
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 14px;
            margin-bottom: 12px;
        }
        .section h2 {
            margin: 0 0 10px;
            font-size: 1.02rem;
            color: #0b3e6f;
        }
        .section h3 {
            margin: 8px 0 10px;
            font-size: 0.95rem;
            color: #0f172a;
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        .field {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .field-full { grid-column: 1 / -1; }
        label {
            font-size: 0.88rem;
            color: #334155;
            font-weight: 600;
        }
        input, select, textarea {
            border: 1px solid #c9d7e5;
            border-radius: 9px;
            padding: 10px;
            font-size: 0.93rem;
            font-family: inherit;
            width: 100%;
        }
        input[type="text"],
        input[type="email"],
        textarea {
            text-transform: uppercase;
        }
        textarea { min-height: 90px; resize: vertical; }
        [data-locked-field="1"] {
            background: #f3f7fb;
            color: #496073;
        }
        .checklist {
            display: grid;
            gap: 8px;
        }
        .check-item {
            border: 1px solid #dbe5ef;
            border-radius: 8px;
            padding: 10px;
            background: #f9fcff;
        }
        .check-item p {
            margin: 0 0 8px;
            font-size: 0.9rem;
            font-weight: 600;
            color: #1e293b;
        }
        .check-grid {
            display: grid;
            grid-template-columns: 220px 1fr;
            gap: 8px;
        }
        .radio-row {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
            min-height: 40px;
        }
        .radio-row label {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-weight: 500;
            font-size: 0.88rem;
            color: #1f2937;
        }
        .radio-row input[type="radio"] {
            width: auto;
            margin: 0;
            padding: 0;
        }
        .submit-row {
            margin-top: 10px;
            display: flex;
            justify-content: flex-end;
        }
        button {
            border: 0;
            border-radius: 10px;
            background: #0b5cab;
            color: #fff;
            font-size: 0.95rem;
            font-weight: 700;
            padding: 11px 16px;
            cursor: pointer;
        }
        @media (max-width: 760px) {
            .grid { grid-template-columns: 1fr; }
            .check-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<%
    String actionType = request.getAttribute("kppActionType") == null ? "" : String.valueOf(request.getAttribute("kppActionType"));
    String applicationRef = request.getAttribute("kppApplicationRef") == null ? "" : String.valueOf(request.getAttribute("kppApplicationRef"));
    String token = request.getAttribute("kppToken") == null ? "" : String.valueOf(request.getAttribute("kppToken"));
    boolean formSaved = Boolean.TRUE.equals(request.getAttribute("kppFormSaved"));
    boolean showKspp = "KSPP".equals(actionType) || "KSPP_UJPPP".equals(actionType);
    boolean showUjppp = "UJPPP".equals(actionType) || "KSPP_UJPPP".equals(actionType);
    Map<String, String> prefillData = (Map<String, String>) request.getAttribute("kppPrefillData");
    if (prefillData == null) {
        prefillData = java.util.Collections.emptyMap();
    }
%>
<div class="top">SPPPA GUEST</div>

<div class="wrap">
    <div class="card" id="kppGuestForm" data-storage-key="kpp-guest-<%= token.hashCode() %>" data-show-kspp="<%= showKspp %>" data-show-ujppp="<%= showUjppp %>">
        <% if (formSaved) { %>
        <div class="ok">Borang digital berjaya dihantar. Data telah disimpan oleh sistem SPPPA.</div>
        <% } %>

        <form method="post" action="<%= request.getContextPath() %>/kpp/guest-access">
            <input type="hidden" name="flow_action" value="save_form">
            <input type="hidden" name="token" value="<%= token %>">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" name="f_application_ref" value="<%= applicationRef %>">

            <% if (!applicationRef.isBlank()) { %>
            <div class="meta">Borang Permohonan Dirujuk: <strong><%= applicationRef %></strong></div>
            <% } %>

            <div class="section">
                <h2>Bahagian A: Maklumat Responden</h2>
                <div class="grid">
                    <div class="field"><label>Nama Penuh</label><input name="f_respondent_name" data-field="f_respondent_name" required></div>
                    <div class="field"><label>Cawangan / Jabatan Air Daerah</label><input name="f_respondent_branch" data-field="f_respondent_branch"></div>
                    <div class="field"><label>Jawatan Hakiki &amp; Gred</label><input name="f_respondent_position_grade" data-field="f_respondent_position_grade"></div>
                    <div class="field"><label>Gelaran Jawatan</label><input name="f_respondent_title" data-field="f_respondent_title"></div>
                    <div class="field"><label>No. Telefon</label><input name="f_phone" data-field="f_phone"></div>
                    <div class="field"><label>Emel Rasmi Kerajaan</label><input type="email" name="f_respondent_official_email" data-field="f_respondent_official_email"></div>
                    <div class="field"><label>Tempoh Berkhidmat</label><input name="f_respondent_service_period" data-field="f_respondent_service_period"></div>
                </div>
            </div>

            <% if (showKspp) { %>
            <div class="section">
                <h2>Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP)</h2>
                <h3>Bahagian B: Maklumat Produk</h3>
                <div class="grid">
                    <div class="field"><label>Nama Produk</label><input name="f_kspp_product_name" data-field="f_kspp_product_name"></div>
                    <div class="field"><label>Jenama</label><input name="f_kspp_brand" data-field="f_kspp_brand"></div>
                    <div class="field field-full"><label>Perihal Produk (Model/Kelas/Saiz)</label><textarea name="f_kspp_product_desc" data-field="f_kspp_product_desc"></textarea></div>
                    <div class="field"><label>Tarikh Mula &amp; Siap</label><input name="f_kspp_start_end_date" data-field="f_kspp_start_end_date"></div>
                    <div class="field"><label>% Siap</label><input name="f_kspp_completion_percent" data-field="f_kspp_completion_percent"></div>
                </div>

                <h3>Bahagian C: Maklumat Pembekal dan Produk</h3>
                <div class="grid">
                    <div class="field"><label>Nama Pembekal</label><input name="f_kspp_supplier_name" data-field="f_kspp_supplier_name"></div>
                    <div class="field"><label>Nama Produk</label><input name="f_kspp_supplier_product_name" data-field="f_kspp_supplier_product_name"></div>
                    <div class="field"><label>Jenama</label><input name="f_kspp_supplier_brand" data-field="f_kspp_supplier_brand"></div>
                    <div class="field field-full"><label>Perihal Produk (Model/Kelas/Saiz/dll)</label><textarea name="f_kspp_supplier_product_desc" data-field="f_kspp_supplier_product_desc"></textarea></div>
                </div>

                <h3>Bahagian D: Prestasi Pembekal dan Produk</h3>
                <div class="checklist">
                    <div class="check-item"><p>1. Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q1" value="Ya" data-field="f_kspp_q1">Ya</label><label><input type="radio" name="f_kspp_q1" value="Tidak" data-field="f_kspp_q1">Tidak</label><label><input type="radio" name="f_kspp_q1" value="Tidak Berkenaan" data-field="f_kspp_q1">Tidak Berkenaan</label></div><input name="f_kspp_q1_note" data-field="f_kspp_q1_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>2. Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal/pemilik produk masih sah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q2" value="Ya" data-field="f_kspp_q2">Ya</label><label><input type="radio" name="f_kspp_q2" value="Tidak" data-field="f_kspp_q2">Tidak</label><label><input type="radio" name="f_kspp_q2" value="Tidak Berkenaan" data-field="f_kspp_q2">Tidak Berkenaan</label></div><input name="f_kspp_q2_note" data-field="f_kspp_q2_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>3. Adakah dokumen jaminan produk masih sah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q3" value="Ya" data-field="f_kspp_q3">Ya</label><label><input type="radio" name="f_kspp_q3" value="Tidak" data-field="f_kspp_q3">Tidak</label><label><input type="radio" name="f_kspp_q3" value="Tidak Berkenaan" data-field="f_kspp_q3">Tidak Berkenaan</label></div><input name="f_kspp_q3_note" data-field="f_kspp_q3_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>4. Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q4" value="Ya" data-field="f_kspp_q4">Ya</label><label><input type="radio" name="f_kspp_q4" value="Tidak" data-field="f_kspp_q4">Tidak</label><label><input type="radio" name="f_kspp_q4" value="Tidak Berkenaan" data-field="f_kspp_q4">Tidak Berkenaan</label></div><input name="f_kspp_q4_note" data-field="f_kspp_q4_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>5. Adakah mudah dihubungi pada bila-bila masa?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q5" value="Ya" data-field="f_kspp_q5">Ya</label><label><input type="radio" name="f_kspp_q5" value="Tidak" data-field="f_kspp_q5">Tidak</label><label><input type="radio" name="f_kspp_q5" value="Tidak Berkenaan" data-field="f_kspp_q5">Tidak Berkenaan</label></div><input name="f_kspp_q5_note" data-field="f_kspp_q5_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>6. Adakah jadual penghantaran produk ke lokasi dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q6" value="Ya" data-field="f_kspp_q6">Ya</label><label><input type="radio" name="f_kspp_q6" value="Tidak" data-field="f_kspp_q6">Tidak</label><label><input type="radio" name="f_kspp_q6" value="Tidak Berkenaan" data-field="f_kspp_q6">Tidak Berkenaan</label></div><input name="f_kspp_q6_note" data-field="f_kspp_q6_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>7. Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q7" value="Ya" data-field="f_kspp_q7">Ya</label><label><input type="radio" name="f_kspp_q7" value="Tidak" data-field="f_kspp_q7">Tidak</label><label><input type="radio" name="f_kspp_q7" value="Tidak Berkenaan" data-field="f_kspp_q7">Tidak Berkenaan</label></div><input name="f_kspp_q7_note" data-field="f_kspp_q7_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>8. Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q8" value="Ya" data-field="f_kspp_q8">Ya</label><label><input type="radio" name="f_kspp_q8" value="Tidak" data-field="f_kspp_q8">Tidak</label><label><input type="radio" name="f_kspp_q8" value="Tidak Berkenaan" data-field="f_kspp_q8">Tidak Berkenaan</label></div><input name="f_kspp_q8_note" data-field="f_kspp_q8_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>9. Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q9" value="Ya" data-field="f_kspp_q9">Ya</label><label><input type="radio" name="f_kspp_q9" value="Tidak" data-field="f_kspp_q9">Tidak</label><label><input type="radio" name="f_kspp_q9" value="Tidak Berkenaan" data-field="f_kspp_q9">Tidak Berkenaan</label></div><input name="f_kspp_q9_note" data-field="f_kspp_q9_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>10. Adakah amalan pelaksanaan kerja mengurangkan kesan/impak negatif terhadap alam sekitar dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q10" value="Ya" data-field="f_kspp_q10">Ya</label><label><input type="radio" name="f_kspp_q10" value="Tidak" data-field="f_kspp_q10">Tidak</label><label><input type="radio" name="f_kspp_q10" value="Tidak Berkenaan" data-field="f_kspp_q10">Tidak Berkenaan</label></div><input name="f_kspp_q10_note" data-field="f_kspp_q10_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>11. Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q11" value="Ya" data-field="f_kspp_q11">Ya</label><label><input type="radio" name="f_kspp_q11" value="Tidak" data-field="f_kspp_q11">Tidak</label><label><input type="radio" name="f_kspp_q11" value="Tidak Berkenaan" data-field="f_kspp_q11">Tidak Berkenaan</label></div><input name="f_kspp_q11_note" data-field="f_kspp_q11_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>12. Adakah pemasangan produk dieselia/dipantau sehingga selesai?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q12" value="Ya" data-field="f_kspp_q12">Ya</label><label><input type="radio" name="f_kspp_q12" value="Tidak" data-field="f_kspp_q12">Tidak</label><label><input type="radio" name="f_kspp_q12" value="Tidak Berkenaan" data-field="f_kspp_q12">Tidak Berkenaan</label></div><input name="f_kspp_q12_note" data-field="f_kspp_q12_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>13. Adakah pengujian dan pentauliahan produk diasakna sehingga selesai?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q13" value="Ya" data-field="f_kspp_q13">Ya</label><label><input type="radio" name="f_kspp_q13" value="Tidak" data-field="f_kspp_q13">Tidak</label><label><input type="radio" name="f_kspp_q13" value="Tidak Berkenaan" data-field="f_kspp_q13">Tidak Berkenaan</label></div><input name="f_kspp_q13_note" data-field="f_kspp_q13_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>14. Adakah produk yang rosak diganti ataupun dibaiki dengan segera?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q14" value="Ya" data-field="f_kspp_q14">Ya</label><label><input type="radio" name="f_kspp_q14" value="Tidak" data-field="f_kspp_q14">Tidak</label><label><input type="radio" name="f_kspp_q14" value="Tidak Berkenaan" data-field="f_kspp_q14">Tidak Berkenaan</label></div><input name="f_kspp_q14_note" data-field="f_kspp_q14_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>15. Adakah Manual Operasi diberikan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q15" value="Ya" data-field="f_kspp_q15">Ya</label><label><input type="radio" name="f_kspp_q15" value="Tidak" data-field="f_kspp_q15">Tidak</label><label><input type="radio" name="f_kspp_q15" value="Tidak Berkenaan" data-field="f_kspp_q15">Tidak Berkenaan</label></div><input name="f_kspp_q15_note" data-field="f_kspp_q15_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>16. Adakah latihan operasi dan senggara produk diberikan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q16" value="Ya" data-field="f_kspp_q16">Ya</label><label><input type="radio" name="f_kspp_q16" value="Tidak" data-field="f_kspp_q16">Tidak</label><label><input type="radio" name="f_kspp_q16" value="Tidak Berkenaan" data-field="f_kspp_q16">Tidak Berkenaan</label></div><input name="f_kspp_q16_note" data-field="f_kspp_q16_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>17. Adakah produk yang dibekalkan memenuhi spesifikasi yang dititikrafkan, berfungsi dengan baik dan tidak ada kecacatan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q17" value="Ya" data-field="f_kspp_q17">Ya</label><label><input type="radio" name="f_kspp_q17" value="Tidak" data-field="f_kspp_q17">Tidak</label><label><input type="radio" name="f_kspp_q17" value="Tidak Berkenaan" data-field="f_kspp_q17">Tidak Berkenaan</label></div><input name="f_kspp_q17_note" data-field="f_kspp_q17_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>18. Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q18" value="Ya" data-field="f_kspp_q18">Ya</label><label><input type="radio" name="f_kspp_q18" value="Tidak" data-field="f_kspp_q18">Tidak</label><label><input type="radio" name="f_kspp_q18" value="Tidak Berkenaan" data-field="f_kspp_q18">Tidak Berkenaan</label></div><input name="f_kspp_q18_note" data-field="f_kspp_q18_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>19. Adakah produk mempunyai rekod prestasi yang tidak memuaskan/rosak dalam tempoh tanggungan kecacatan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q19" value="Ya" data-field="f_kspp_q19">Ya</label><label><input type="radio" name="f_kspp_q19" value="Tidak" data-field="f_kspp_q19">Tidak</label><label><input type="radio" name="f_kspp_q19" value="Tidak Berkenaan" data-field="f_kspp_q19">Tidak Berkenaan</label></div><input name="f_kspp_q19_note" data-field="f_kspp_q19_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>20. Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan.</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q20" value="Ya" data-field="f_kspp_q20">Ya</label><label><input type="radio" name="f_kspp_q20" value="Tidak" data-field="f_kspp_q20">Tidak</label><label><input type="radio" name="f_kspp_q20" value="Tidak Berkenaan" data-field="f_kspp_q20">Tidak Berkenaan</label></div><input name="f_kspp_q20_note" data-field="f_kspp_q20_note" placeholder="Catatan"></div></div>
                </div>

                <h3>Bahagian E: Keputusan Pembaharuan Perakuan</h3>
                <div class="grid">
                    <div class="field">
                        <label>Keputusan</label>
                        <select name="f_kspp_review_decision" data-field="f_kspp_review_decision">
                            <option value="">-- Pilih --</option>
                            <option value="Bersetuju">Bersetuju</option>
                            <option value="Tidak Bersetuju">Tidak Bersetuju</option>
                        </select>
                    </div>
                    <div class="field"><label>Tarikh</label><input type="date" name="f_kspp_review_date" data-field="f_kspp_review_date"></div>
                </div>
            </div>
            <% } %>

            <% if (showUjppp) { %>
            <div class="section">
                <h2>Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP)</h2>
                <h3>Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal</h3>
                <div class="grid">
                    <div class="field"><label>Jenis Permohonan (Baharu / Pembaharuan)</label><input name="f_ujppp_application_type" data-field="f_ujppp_application_type"></div>
                    <div class="field field-full"><label>Nama Syarikat Pembekal, Alamat Pejabat &amp; No. Telefon</label><textarea name="f_ujppp_supplier_company_info" data-field="f_ujppp_supplier_company_info"></textarea></div>
                    <div class="field field-full"><label>Nama Syarikat Pembuat / Pengilang, Alamat Pejabat &amp; No. Telefon</label><textarea name="f_ujppp_manufacturer_company_info" data-field="f_ujppp_manufacturer_company_info"></textarea></div>
                    <div class="field field-full"><label>Nama Syarikat Prinsipal / Pemilik Produk, Alamat Pejabat &amp; No. Telefon</label><textarea name="f_ujppp_principal_company_info" data-field="f_ujppp_principal_company_info"></textarea></div>
                </div>

                <h3>Bahagian B: Maklumat Produk</h3>
                <div class="grid">
                    <div class="field"><label>Kategori</label><input name="f_ujppp_category" data-field="f_ujppp_category"></div>
                    <div class="field"><label>Nama Produk</label><input name="f_ujppp_product_name" data-field="f_ujppp_product_name"></div>
                    <div class="field"><label>Jenama</label><input name="f_ujppp_brand" data-field="f_ujppp_brand"></div>
                    <div class="field"><label>Piawaian / Standard</label><input name="f_ujppp_standard" data-field="f_ujppp_standard"></div>
                    <div class="field field-full"><label>Badan Persijilan &amp; No. Lesen Persijilan Barangan (Sah sehingga)</label><textarea name="f_ujppp_certification_body" data-field="f_ujppp_certification_body"></textarea></div>
                    <div class="field field-full"><label>Badan Persijilan &amp; No. Laporan Pengujian (Tarikh dikeluarkan)</label><textarea name="f_ujppp_test_report" data-field="f_ujppp_test_report"></textarea></div>
                    <div class="field field-full"><label>Perihal Produk (Model / Siri / Deskripsi)</label><textarea name="f_ujppp_product_desc" data-field="f_ujppp_product_desc"></textarea></div>
                    <div class="field"><label>Tempoh Jaminan Produk (Tahun)</label><input name="f_ujppp_warranty_year" data-field="f_ujppp_warranty_year"></div>
                </div>

                <h3>Bahagian C: Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Selaku Pengguna Produk</h3>
                <div class="grid">
                    <div class="field"><label>Tarikh</label><input type="date" name="f_ujppp_review_date" data-field="f_ujppp_review_date"></div>
                    <div class="field field-full"><label>Syor (diterima/ditolak/digantung/dibatal)</label><select name="f_ujppp_review_recommendation" data-field="f_ujppp_review_recommendation"><option value="">-- Pilih --</option><option value="diterima">diterima</option><option value="ditolak">ditolak</option><option value="digantung">digantung</option><option value="dibatal">dibatal</option></select></div>
                    <div class="field field-full"><label>Ulasan</label><textarea name="f_ujppp_review_note" data-field="f_ujppp_review_note"></textarea></div>
                </div>
            </div>
            <% } %>

            <div class="submit-row">
                <button type="submit">Hantar</button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const box = document.getElementById('kppGuestForm');
    if (!box) return;

    const storageKey = box.dataset.storageKey;
    const shouldLockKspp = box.dataset.showKspp === 'true';
    const shouldLockUjppp = box.dataset.showUjppp === 'true';
    const fields = Array.from(box.querySelectorAll('[data-field]'));
    const lockedPrefillData = {
        f_respondent_name: `<%= escapeJs(safePrefill(prefillData, "f_respondent_name")) %>`,
        f_respondent_branch: `<%= escapeJs(safePrefill(prefillData, "f_respondent_branch")) %>`,
        f_respondent_position_grade: `<%= escapeJs(safePrefill(prefillData, "f_respondent_position_grade")) %>`,
        f_respondent_title: `<%= escapeJs(safePrefill(prefillData, "f_respondent_title")) %>`,
        f_respondent_official_email: `<%= escapeJs(safePrefill(prefillData, "f_respondent_official_email")) %>`,
        f_kspp_product_name: `<%= escapeJs(safePrefill(prefillData, "f_kspp_product_name")) %>`,
        f_kspp_brand: `<%= escapeJs(safePrefill(prefillData, "f_kspp_brand")) %>`,
        f_kspp_product_desc: `<%= escapeJs(safePrefill(prefillData, "f_kspp_product_desc")) %>`,
        f_kspp_start_end_date: `<%= escapeJs(safePrefill(prefillData, "f_kspp_start_end_date")) %>`,
        f_kspp_completion_percent: `<%= escapeJs(safePrefill(prefillData, "f_kspp_completion_percent")) %>`,
        f_kspp_supplier_name: `<%= escapeJs(safePrefill(prefillData, "f_kspp_supplier_name")) %>`,
        f_kspp_supplier_product_name: `<%= escapeJs(safePrefill(prefillData, "f_kspp_supplier_product_name")) %>`,
        f_kspp_supplier_brand: `<%= escapeJs(safePrefill(prefillData, "f_kspp_supplier_brand")) %>`,
        f_kspp_supplier_product_desc: `<%= escapeJs(safePrefill(prefillData, "f_kspp_supplier_product_desc")) %>`,
        f_ujppp_application_type: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_application_type")) %>`,
        f_ujppp_supplier_company_info: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_supplier_company_info")) %>`,
        f_ujppp_manufacturer_company_info: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_manufacturer_company_info")) %>`,
        f_ujppp_principal_company_info: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_principal_company_info")) %>`,
        f_ujppp_category: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_category")) %>`,
        f_ujppp_product_name: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_product_name")) %>`,
        f_ujppp_brand: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_brand")) %>`,
        f_ujppp_standard: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_standard")) %>`,
        f_ujppp_certification_body: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_certification_body")) %>`,
        f_ujppp_test_report: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_test_report")) %>`,
        f_ujppp_product_desc: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_product_desc")) %>`,
        f_ujppp_warranty_year: `<%= escapeJs(safePrefill(prefillData, "f_ujppp_warranty_year")) %>`
    };
    const ksppLockedFields = [
        'f_respondent_name',
        'f_respondent_branch',
        'f_respondent_position_grade',
        'f_respondent_title',
        'f_respondent_official_email',
        'f_kspp_product_name',
        'f_kspp_brand',
        'f_kspp_product_desc',
        'f_kspp_start_end_date',
        'f_kspp_completion_percent',
        'f_kspp_supplier_name',
        'f_kspp_supplier_product_name',
        'f_kspp_supplier_brand',
        'f_kspp_supplier_product_desc'
    ];
    const ujpppLockedFields = [
        'f_ujppp_application_type',
        'f_ujppp_supplier_company_info',
        'f_ujppp_manufacturer_company_info',
        'f_ujppp_principal_company_info',
        'f_ujppp_category',
        'f_ujppp_product_name',
        'f_ujppp_brand',
        'f_ujppp_standard',
        'f_ujppp_certification_body',
        'f_ujppp_test_report',
        'f_ujppp_product_desc',
        'f_ujppp_warranty_year'
    ];
    const activeLockedFields = [];
    if (shouldLockKspp) {
        ksppLockedFields.forEach((name) => activeLockedFields.push(name));
    }
    if (shouldLockUjppp) {
        ujpppLockedFields.forEach((name) => activeLockedFields.push(name));
    }
    const lockedFieldNames = new Set(activeLockedFields);
    const isKsppRenewalForm = shouldLockKspp && !shouldLockUjppp;

    function isKsppSectionDField(fieldName) {
        return /^f_kspp_q([1-9]|1\d|20)(_note)?$/.test(fieldName || '');
    }

    function isRenewalLockedField(field) {
        if (!isKsppRenewalForm || !field) {
            return false;
        }
        const fieldName = field.name || '';
        const fieldKey = field.dataset ? (field.dataset.field || '') : '';
        if (!fieldName || !fieldKey) {
            return false;
        }
        return !isKsppSectionDField(fieldName);
    }

    function isUppercaseTarget(field) {
        if (!field) {
            return false;
        }
        if (field.tagName === 'TEXTAREA') {
            return true;
        }
        if (field.tagName !== 'INPUT') {
            return false;
        }
        const inputType = (field.type || '').toLowerCase();
        return inputType === 'text' || inputType === 'email';
    }

    function enforceUppercase(field) {
        if (!isUppercaseTarget(field)) {
            return;
        }
        const currentValue = field.value || '';
        const normalizedValue = currentValue.toUpperCase();
        if (currentValue !== normalizedValue) {
            field.value = normalizedValue;
        }
    }

    function applyUppercaseAttributes() {
        fields.forEach((field) => {
            if (!isUppercaseTarget(field)) {
                return;
            }
            field.setAttribute('autocapitalize', 'characters');
            enforceUppercase(field);
        });
    }

    function isLockedField(field) {
        return !!field && (lockedFieldNames.has(field.name || '') || isRenewalLockedField(field));
    }

    function applyLockedPrefill() {
        activeLockedFields.forEach((fieldName) => {
            const fieldNodes = Array.from(box.querySelectorAll('[name="' + fieldName + '"]'));
            fieldNodes.forEach((field) => {
                const value = Object.prototype.hasOwnProperty.call(lockedPrefillData, fieldName)
                    ? (lockedPrefillData[fieldName] || '')
                    : '';
                field.setAttribute('data-locked-field', '1');
                if (typeof field.readOnly !== 'undefined') {
                    field.readOnly = true;
                }
                if (field.tagName === 'INPUT' || field.tagName === 'TEXTAREA') {
                    field.value = value;
                }
            });
        });
    }

    function applyRenewalLockState() {
        if (!isKsppRenewalForm) {
            return;
        }
        fields.forEach((field) => {
            if (!isRenewalLockedField(field)) {
                return;
            }
            field.setAttribute('data-locked-field', '1');
            if (field.type === 'radio' || field.type === 'checkbox' || field.tagName === 'SELECT') {
                field.disabled = true;
                return;
            }
            if (typeof field.readOnly !== 'undefined') {
                field.readOnly = true;
            }
        });
    }

    function save() {
        const data = {};
        fields.forEach((field) => {
            const key = field.dataset.field;
            if (!key || isLockedField(field)) {
                return;
            }

            if (field.type === 'radio') {
                if (field.checked) {
                    data[key] = field.value || '';
                } else if (!Object.prototype.hasOwnProperty.call(data, key)) {
                    data[key] = '';
                }
                return;
            }

            data[key] = field.value || '';
        });
        try {
            localStorage.setItem(storageKey, JSON.stringify(data));
        } catch (error) {
            console.warn('Gagal simpan cache borang guest:', error);
        }
    }

    function load() {
        try {
            const raw = localStorage.getItem(storageKey);
            if (!raw) return;
            const data = JSON.parse(raw);
            fields.forEach((field) => {
                const key = field.dataset.field;
                if (isLockedField(field) || !Object.prototype.hasOwnProperty.call(data, key)) {
                    return;
                }

                if (field.type === 'radio') {
                    field.checked = field.value === data[key];
                    return;
                }

                field.value = data[key];
                enforceUppercase(field);
            });
        } catch (error) {
            console.warn('Gagal muat cache borang guest:', error);
        }
    }

    fields.forEach((field) => {
        if (isLockedField(field)) {
            return;
        }
        field.addEventListener('input', () => {
            enforceUppercase(field);
            save();
        });
        field.addEventListener('change', () => {
            enforceUppercase(field);
            save();
        });
    });

    applyUppercaseAttributes();
    applyLockedPrefill();
    applyRenewalLockState();
    load();
    applyUppercaseAttributes();
    applyLockedPrefill();
    applyRenewalLockState();
})();
</script>
</body>
</html>
=======
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.lang.String" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Borang Digital KPP Guest</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #eef4f8;
            color: #0f172a;
        }
        .top {
            background: #123b64;
            color: #fff;
            padding: 12px 18px;
            font-weight: 700;
        }
        .wrap {
            max-width: 980px;
            margin: 18px auto 34px;
            padding: 0 14px;
        }
        .card {
            background: #fff;
            border: 1px solid #d2deea;
            border-radius: 12px;
            box-shadow: 0 14px 30px rgba(2, 44, 74, 0.1);
            padding: 18px;
        }
        .meta {
            background: #f8fbff;
            border: 1px solid #d8e7f7;
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 12px;
            font-size: 0.95rem;
            color: #334155;
        }
        .ok {
            background: #ecfdf3;
            border: 1px solid #86efac;
            color: #166534;
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 12px;
            font-size: 0.93rem;
        }
        .section {
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 14px;
            margin-bottom: 12px;
        }
        .section h2 {
            margin: 0 0 10px;
            font-size: 1.02rem;
            color: #0b3e6f;
        }
        .section h3 {
            margin: 8px 0 10px;
            font-size: 0.95rem;
            color: #0f172a;
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        .field {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .field-full { grid-column: 1 / -1; }
        label {
            font-size: 0.88rem;
            color: #334155;
            font-weight: 600;
        }
        input, select, textarea {
            border: 1px solid #c9d7e5;
            border-radius: 9px;
            padding: 10px;
            font-size: 0.93rem;
            font-family: inherit;
            width: 100%;
        }
        textarea { min-height: 90px; resize: vertical; }
        .checklist {
            display: grid;
            gap: 8px;
        }
        .check-item {
            border: 1px solid #dbe5ef;
            border-radius: 8px;
            padding: 10px;
            background: #f9fcff;
        }
        .check-item p {
            margin: 0 0 8px;
            font-size: 0.9rem;
            font-weight: 600;
            color: #1e293b;
        }
        .check-grid {
            display: grid;
            grid-template-columns: 220px 1fr;
            gap: 8px;
        }
        .radio-row {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            align-items: center;
            min-height: 40px;
        }
        .radio-row label {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-weight: 500;
            font-size: 0.88rem;
            color: #1f2937;
        }
        .radio-row input[type="radio"] {
            width: auto;
            margin: 0;
            padding: 0;
        }
        .submit-row {
            margin-top: 10px;
            display: flex;
            justify-content: flex-end;
        }
        button {
            border: 0;
            border-radius: 10px;
            background: #0b5cab;
            color: #fff;
            font-size: 0.95rem;
            font-weight: 700;
            padding: 11px 16px;
            cursor: pointer;
        }
        @media (max-width: 760px) {
            .grid { grid-template-columns: 1fr; }
            .check-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<%
    String actionType = request.getAttribute("kppActionType") == null ? "" : String.valueOf(request.getAttribute("kppActionType"));
    String token = request.getAttribute("kppToken") == null ? "" : String.valueOf(request.getAttribute("kppToken"));
    boolean formSaved = Boolean.TRUE.equals(request.getAttribute("kppFormSaved"));
    boolean showKspp = "KSPP".equals(actionType) || "KSPP_UJPPP".equals(actionType);
    boolean showUjppp = "UJPPP".equals(actionType) || "KSPP_UJPPP".equals(actionType);
%>
<div class="top">SPPA GUEST</div>

<div class="wrap">
    <div class="card" id="kppGuestForm" data-storage-key="kpp-guest-<%= token.hashCode() %>">
        <% if (formSaved) { %>
        <div class="ok">Borang digital berjaya dihantar. Data telah disimpan oleh sistem SPPA.</div>
        <% } %>

        <form method="post" action="<%= request.getContextPath() %>/kpp/guest-access">
            <input type="hidden" name="flow_action" value="save_form">
            <input type="hidden" name="token" value="<%= token %>">
            <input type="hidden" name="_csrf" value="${csrf_token}">

            <div class="section">
                <h2>Bahagian A: Maklumat Responden</h2>
                <div class="grid">
                    <div class="field"><label>Nama Penuh</label><input name="f_respondent_name" data-field="f_respondent_name" required></div>
                    <div class="field"><label>Cawangan / Jabatan Air Daerah</label><input name="f_respondent_branch" data-field="f_respondent_branch"></div>
                    <div class="field"><label>Jawatan Hakiki &amp; Gred</label><input name="f_respondent_position_grade" data-field="f_respondent_position_grade"></div>
                    <div class="field"><label>Gelaran Jawatan</label><input name="f_respondent_title" data-field="f_respondent_title"></div>
                    <div class="field"><label>No. Telefon</label><input name="f_phone" data-field="f_phone"></div>
                    <div class="field"><label>Emel Rasmi Kerajaan</label><input type="email" name="f_respondent_official_email" data-field="f_respondent_official_email"></div>
                    <div class="field"><label>Tempoh Berkhidmat</label><input name="f_respondent_service_period" data-field="f_respondent_service_period"></div>
                </div>
            </div>

            <% if (showKspp) { %>
            <div class="section">
                <h2>Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP)</h2>
                <h3>Bahagian B: Maklumat Produk</h3>
                <div class="grid">
                    <div class="field"><label>Nama Produk</label><input name="f_kspp_product_name" data-field="f_kspp_product_name"></div>
                    <div class="field"><label>Jenama</label><input name="f_kspp_brand" data-field="f_kspp_brand"></div>
                    <div class="field field-full"><label>Perihal Produk (Model/Kelas/Saiz)</label><textarea name="f_kspp_product_desc" data-field="f_kspp_product_desc"></textarea></div>
                    <div class="field"><label>Tarikh Mula &amp; Siap</label><input name="f_kspp_start_end_date" data-field="f_kspp_start_end_date"></div>
                    <div class="field"><label>% Siap</label><input name="f_kspp_completion_percent" data-field="f_kspp_completion_percent"></div>
                </div>

                <h3>Bahagian C: Maklumat Pembekal dan Produk</h3>
                <div class="grid">
                    <div class="field"><label>Nama Pembekal</label><input name="f_kspp_supplier_name" data-field="f_kspp_supplier_name"></div>
                    <div class="field"><label>Nama Produk</label><input name="f_kspp_supplier_product_name" data-field="f_kspp_supplier_product_name"></div>
                    <div class="field"><label>Jenama</label><input name="f_kspp_supplier_brand" data-field="f_kspp_supplier_brand"></div>
                    <div class="field field-full"><label>Perihal Produk (Model/Kelas/Saiz/dll)</label><textarea name="f_kspp_supplier_product_desc" data-field="f_kspp_supplier_product_desc"></textarea></div>
                </div>

                <h3>Bahagian D: Prestasi Pembekal dan Produk</h3>
                <div class="checklist">
                    <div class="check-item"><p>1. Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q1" value="Ya" data-field="f_kspp_q1">Ya</label><label><input type="radio" name="f_kspp_q1" value="Tidak" data-field="f_kspp_q1">Tidak</label><label><input type="radio" name="f_kspp_q1" value="Tidak Berkenaan" data-field="f_kspp_q1">Tidak Berkenaan</label></div><input name="f_kspp_q1_note" data-field="f_kspp_q1_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>2. Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal/pemilik produk masih sah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q2" value="Ya" data-field="f_kspp_q2">Ya</label><label><input type="radio" name="f_kspp_q2" value="Tidak" data-field="f_kspp_q2">Tidak</label><label><input type="radio" name="f_kspp_q2" value="Tidak Berkenaan" data-field="f_kspp_q2">Tidak Berkenaan</label></div><input name="f_kspp_q2_note" data-field="f_kspp_q2_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>3. Adakah dokumen jaminan produk masih sah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q3" value="Ya" data-field="f_kspp_q3">Ya</label><label><input type="radio" name="f_kspp_q3" value="Tidak" data-field="f_kspp_q3">Tidak</label><label><input type="radio" name="f_kspp_q3" value="Tidak Berkenaan" data-field="f_kspp_q3">Tidak Berkenaan</label></div><input name="f_kspp_q3_note" data-field="f_kspp_q3_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>4. Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q4" value="Ya" data-field="f_kspp_q4">Ya</label><label><input type="radio" name="f_kspp_q4" value="Tidak" data-field="f_kspp_q4">Tidak</label><label><input type="radio" name="f_kspp_q4" value="Tidak Berkenaan" data-field="f_kspp_q4">Tidak Berkenaan</label></div><input name="f_kspp_q4_note" data-field="f_kspp_q4_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>5. Adakah mudah dihubungi pada bila-bila masa?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q5" value="Ya" data-field="f_kspp_q5">Ya</label><label><input type="radio" name="f_kspp_q5" value="Tidak" data-field="f_kspp_q5">Tidak</label><label><input type="radio" name="f_kspp_q5" value="Tidak Berkenaan" data-field="f_kspp_q5">Tidak Berkenaan</label></div><input name="f_kspp_q5_note" data-field="f_kspp_q5_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>6. Adakah jadual penghantaran produk ke lokasi dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q6" value="Ya" data-field="f_kspp_q6">Ya</label><label><input type="radio" name="f_kspp_q6" value="Tidak" data-field="f_kspp_q6">Tidak</label><label><input type="radio" name="f_kspp_q6" value="Tidak Berkenaan" data-field="f_kspp_q6">Tidak Berkenaan</label></div><input name="f_kspp_q6_note" data-field="f_kspp_q6_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>7. Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q7" value="Ya" data-field="f_kspp_q7">Ya</label><label><input type="radio" name="f_kspp_q7" value="Tidak" data-field="f_kspp_q7">Tidak</label><label><input type="radio" name="f_kspp_q7" value="Tidak Berkenaan" data-field="f_kspp_q7">Tidak Berkenaan</label></div><input name="f_kspp_q7_note" data-field="f_kspp_q7_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>8. Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q8" value="Ya" data-field="f_kspp_q8">Ya</label><label><input type="radio" name="f_kspp_q8" value="Tidak" data-field="f_kspp_q8">Tidak</label><label><input type="radio" name="f_kspp_q8" value="Tidak Berkenaan" data-field="f_kspp_q8">Tidak Berkenaan</label></div><input name="f_kspp_q8_note" data-field="f_kspp_q8_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>9. Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q9" value="Ya" data-field="f_kspp_q9">Ya</label><label><input type="radio" name="f_kspp_q9" value="Tidak" data-field="f_kspp_q9">Tidak</label><label><input type="radio" name="f_kspp_q9" value="Tidak Berkenaan" data-field="f_kspp_q9">Tidak Berkenaan</label></div><input name="f_kspp_q9_note" data-field="f_kspp_q9_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>10. Adakah amalan pelaksanaan kerja mengurangkan kesan/impak negatif terhadap alam sekitar dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q10" value="Ya" data-field="f_kspp_q10">Ya</label><label><input type="radio" name="f_kspp_q10" value="Tidak" data-field="f_kspp_q10">Tidak</label><label><input type="radio" name="f_kspp_q10" value="Tidak Berkenaan" data-field="f_kspp_q10">Tidak Berkenaan</label></div><input name="f_kspp_q10_note" data-field="f_kspp_q10_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>11. Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q11" value="Ya" data-field="f_kspp_q11">Ya</label><label><input type="radio" name="f_kspp_q11" value="Tidak" data-field="f_kspp_q11">Tidak</label><label><input type="radio" name="f_kspp_q11" value="Tidak Berkenaan" data-field="f_kspp_q11">Tidak Berkenaan</label></div><input name="f_kspp_q11_note" data-field="f_kspp_q11_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>12. Adakah pemasangan produk dieselia/dipantau sehingga selesai?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q12" value="Ya" data-field="f_kspp_q12">Ya</label><label><input type="radio" name="f_kspp_q12" value="Tidak" data-field="f_kspp_q12">Tidak</label><label><input type="radio" name="f_kspp_q12" value="Tidak Berkenaan" data-field="f_kspp_q12">Tidak Berkenaan</label></div><input name="f_kspp_q12_note" data-field="f_kspp_q12_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>13. Adakah pengujian dan pentauliahan produk diasakna sehingga selesai?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q13" value="Ya" data-field="f_kspp_q13">Ya</label><label><input type="radio" name="f_kspp_q13" value="Tidak" data-field="f_kspp_q13">Tidak</label><label><input type="radio" name="f_kspp_q13" value="Tidak Berkenaan" data-field="f_kspp_q13">Tidak Berkenaan</label></div><input name="f_kspp_q13_note" data-field="f_kspp_q13_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>14. Adakah produk yang rosak diganti ataupun dibaiki dengan segera?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q14" value="Ya" data-field="f_kspp_q14">Ya</label><label><input type="radio" name="f_kspp_q14" value="Tidak" data-field="f_kspp_q14">Tidak</label><label><input type="radio" name="f_kspp_q14" value="Tidak Berkenaan" data-field="f_kspp_q14">Tidak Berkenaan</label></div><input name="f_kspp_q14_note" data-field="f_kspp_q14_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>15. Adakah Manual Operasi diberikan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q15" value="Ya" data-field="f_kspp_q15">Ya</label><label><input type="radio" name="f_kspp_q15" value="Tidak" data-field="f_kspp_q15">Tidak</label><label><input type="radio" name="f_kspp_q15" value="Tidak Berkenaan" data-field="f_kspp_q15">Tidak Berkenaan</label></div><input name="f_kspp_q15_note" data-field="f_kspp_q15_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>16. Adakah latihan operasi dan senggara produk diberikan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q16" value="Ya" data-field="f_kspp_q16">Ya</label><label><input type="radio" name="f_kspp_q16" value="Tidak" data-field="f_kspp_q16">Tidak</label><label><input type="radio" name="f_kspp_q16" value="Tidak Berkenaan" data-field="f_kspp_q16">Tidak Berkenaan</label></div><input name="f_kspp_q16_note" data-field="f_kspp_q16_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>17. Adakah produk yang dibekalkan memenuhi spesifikasi yang dititikrafkan, berfungsi dengan baik dan tidak ada kecacatan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q17" value="Ya" data-field="f_kspp_q17">Ya</label><label><input type="radio" name="f_kspp_q17" value="Tidak" data-field="f_kspp_q17">Tidak</label><label><input type="radio" name="f_kspp_q17" value="Tidak Berkenaan" data-field="f_kspp_q17">Tidak Berkenaan</label></div><input name="f_kspp_q17_note" data-field="f_kspp_q17_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>18. Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q18" value="Ya" data-field="f_kspp_q18">Ya</label><label><input type="radio" name="f_kspp_q18" value="Tidak" data-field="f_kspp_q18">Tidak</label><label><input type="radio" name="f_kspp_q18" value="Tidak Berkenaan" data-field="f_kspp_q18">Tidak Berkenaan</label></div><input name="f_kspp_q18_note" data-field="f_kspp_q18_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>19. Adakah produk mempunyai rekod prestasi yang tidak memuaskan/rosak dalam tempoh tanggungan kecacatan?</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q19" value="Ya" data-field="f_kspp_q19">Ya</label><label><input type="radio" name="f_kspp_q19" value="Tidak" data-field="f_kspp_q19">Tidak</label><label><input type="radio" name="f_kspp_q19" value="Tidak Berkenaan" data-field="f_kspp_q19">Tidak Berkenaan</label></div><input name="f_kspp_q19_note" data-field="f_kspp_q19_note" placeholder="Catatan"></div></div>
                    <div class="check-item"><p>20. Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan.</p><div class="check-grid"><div class="radio-row"><label><input type="radio" name="f_kspp_q20" value="Ya" data-field="f_kspp_q20">Ya</label><label><input type="radio" name="f_kspp_q20" value="Tidak" data-field="f_kspp_q20">Tidak</label><label><input type="radio" name="f_kspp_q20" value="Tidak Berkenaan" data-field="f_kspp_q20">Tidak Berkenaan</label></div><input name="f_kspp_q20_note" data-field="f_kspp_q20_note" placeholder="Catatan"></div></div>
                </div>

                <h3>Bahagian E: Ulasan Terhadap Pembaharuan Perakuan</h3>
                <div class="grid">
                    <div class="field">
                        <label>Keputusan Ulasan</label>
                        <select name="f_kspp_review_decision" data-field="f_kspp_review_decision">
                            <option value="">-- Pilih --</option>
                            <option value="Bersetuju">Bersetuju</option>
                            <option value="Tidak Bersetuju">Tidak Bersetuju</option>
                        </select>
                    </div>
                    <div class="field"><label>Tarikh</label><input type="date" name="f_kspp_review_date" data-field="f_kspp_review_date"></div>
                    <div class="field field-full"><label>Ulasan</label><textarea name="f_kspp_review_note" data-field="f_kspp_review_note"></textarea></div>
                    <div class="field"><label>Nama</label><input name="f_kspp_sign_name" data-field="f_kspp_sign_name"></div>
                </div>
            </div>
            <% } %>

            <% if (showUjppp) { %>
            <div class="section">
                <h2>Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP)</h2>
                <h3>Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal</h3>
                <div class="grid">
                    <div class="field"><label>Jenis Permohonan (Baharu / Pembaharuan)</label><input name="f_ujppp_application_type" data-field="f_ujppp_application_type"></div>
                    <div class="field field-full"><label>Nama Syarikat Pembekal, Alamat Pejabat &amp; No. Telefon</label><textarea name="f_ujppp_supplier_company_info" data-field="f_ujppp_supplier_company_info"></textarea></div>
                    <div class="field field-full"><label>Nama Syarikat Pembuat / Pengilang, Alamat Pejabat &amp; No. Telefon</label><textarea name="f_ujppp_manufacturer_company_info" data-field="f_ujppp_manufacturer_company_info"></textarea></div>
                    <div class="field field-full"><label>Nama Syarikat Prinsipal / Pemilik Produk, Alamat Pejabat &amp; No. Telefon</label><textarea name="f_ujppp_principal_company_info" data-field="f_ujppp_principal_company_info"></textarea></div>
                </div>

                <h3>Bahagian B: Maklumat Produk</h3>
                <div class="grid">
                    <div class="field"><label>Kategori</label><input name="f_ujppp_category" data-field="f_ujppp_category"></div>
                    <div class="field"><label>Nama Produk</label><input name="f_ujppp_product_name" data-field="f_ujppp_product_name"></div>
                    <div class="field"><label>Jenama</label><input name="f_ujppp_brand" data-field="f_ujppp_brand"></div>
                    <div class="field"><label>Piawaian / Standard</label><input name="f_ujppp_standard" data-field="f_ujppp_standard"></div>
                    <div class="field field-full"><label>Badan Persijilan &amp; No. Lesen Persijilan Barangan (Sah sehingga)</label><textarea name="f_ujppp_certification_body" data-field="f_ujppp_certification_body"></textarea></div>
                    <div class="field field-full"><label>Badan Persijilan &amp; No. Laporan Pengujian (Tarikh dikeluarkan)</label><textarea name="f_ujppp_test_report" data-field="f_ujppp_test_report"></textarea></div>
                    <div class="field field-full"><label>Perihal Produk (Model / Siri / Deskripsi)</label><textarea name="f_ujppp_product_desc" data-field="f_ujppp_product_desc"></textarea></div>
                    <div class="field"><label>Tempoh Jaminan Produk (Tahun)</label><input name="f_ujppp_warranty_year" data-field="f_ujppp_warranty_year"></div>
                </div>

                <h3>Bahagian C: Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Selaku Pengguna Produk</h3>
                <div class="grid">
                    <div class="field"><label>Tarikh</label><input type="date" name="f_ujppp_review_date" data-field="f_ujppp_review_date"></div>
                    <div class="field field-full"><label>Syor (diterima/ditolak/digantung/dibatal)</label><textarea name="f_ujppp_review_recommendation" data-field="f_ujppp_review_recommendation"></textarea></div>
                </div>
            </div>
            <% } %>

            <div class="submit-row">
                <button type="submit">Hantar</button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const box = document.getElementById('kppGuestForm');
    if (!box) return;

    const storageKey = box.dataset.storageKey;
    const fields = Array.from(box.querySelectorAll('[data-field]'));

    function save() {
        const data = {};
        fields.forEach((field) => {
            const key = field.dataset.field;
            if (!key) {
                return;
            }

            if (field.type === 'radio') {
                if (field.checked) {
                    data[key] = field.value || '';
                } else if (!Object.prototype.hasOwnProperty.call(data, key)) {
                    data[key] = '';
                }
                return;
            }

            data[key] = field.value || '';
        });
        try {
            localStorage.setItem(storageKey, JSON.stringify(data));
        } catch (error) {
            console.warn('Gagal simpan cache borang guest:', error);
        }
    }

    function load() {
        try {
            const raw = localStorage.getItem(storageKey);
            if (!raw) return;
            const data = JSON.parse(raw);
            fields.forEach((field) => {
                const key = field.dataset.field;
                if (!Object.prototype.hasOwnProperty.call(data, key)) {
                    return;
                }

                if (field.type === 'radio') {
                    field.checked = field.value === data[key];
                    return;
                }

                field.value = data[key];
            });
        } catch (error) {
            console.warn('Gagal muat cache borang guest:', error);
        }
    }

    fields.forEach((field) => {
        field.addEventListener('input', save);
        field.addEventListener('change', save);
    });

    load();
})();
</script>
</body>
</html>
>>>>>>> origin/SPPPA
