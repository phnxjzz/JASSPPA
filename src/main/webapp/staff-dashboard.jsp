<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Portal Staff - SPPPA</title>
    <style>
:root {
            --brand-blue: #0f6bae;
            --brand-teal: #2a9d8f;
            --text: #173040;
            --muted: #4d6779;
            --surface: #ffffff;
            --surface-soft: #eef8ff;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: inherit;
            color: var(--text);
            background: radial-gradient(circle at top right, #d8f2ff 0%, #f6fbff 55%, #ffffff 100%);
            min-height: 100vh;
        }
        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 14px 20px;
            border-bottom: 1px solid #d8e7f2;
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(6px);
            position: sticky;
            top: 0;
            z-index: 20;
        }
        .topbar-title {
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 700;
            color: #0e5f8f;
        }
        .topbar-title img {
            width: 24px;
            height: 24px;
            object-fit: contain;
        }
        .topbar-actions {
            display: flex;
            gap: 10px;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 9px 14px;
            border-radius: 999px;
            text-decoration: none;
            font-weight: 700;
            border: 1px solid #ffffff;
            box-shadow: inset 0 0 0 1px #ffffff, 0 1px 2px rgba(0, 0, 0, 0.18);
        }
        .btn-secondary {
            color: #0f5d88;
            background: #e8f5ff;
        }
        .btn-primary {
            color: #ffffff;
            background: linear-gradient(135deg, var(--brand-blue) 0%, var(--brand-teal) 100%);
        }
        .btn-icon {
            width: 40px;
            height: 40px;
            padding: 0;
            border-radius: 999px;
        }
        .btn-icon img {
            width: 20px;
            height: 20px;
            object-fit: contain;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 28px 18px 40px;
        }
        .hero {
            border: 1px solid #d7e6f2;
            border-radius: 18px;
            background: linear-gradient(135deg, #ffffff 0%, #ecf9ff 100%);
            box-shadow: 0 14px 28px rgba(6, 47, 72, 0.09);
            padding: 24px;
            margin-bottom: 18px;
        }
        .hero h1 {
            margin: 0 0 8px;
            font-size: clamp(24px, 3vw, 32px);
            color: #0a4f78;
        }
        .hero p {
            margin: 0;
            color: var(--muted);
            line-height: 1.55;
            max-width: 720px;
        }
        .aduan-section {
            margin: 18px 0;
            border: 1px solid #d8e7f2;
            border-radius: 16px;
            background: var(--surface);
            box-shadow: 0 10px 24px rgba(6, 47, 72, 0.08);
            padding: 16px;
        }
        .aduan-section h2 {
            margin: 0 0 6px;
            font-size: 20px;
            color: #0d4568;
        }
        .aduan-section p {
            margin: 0 0 12px;
            color: var(--muted);
            line-height: 1.5;
        }
        .aduan-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }
        .field {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .field label {
            color: #23495f;
            font-size: 13px;
            font-weight: 700;
        }
        .field input,
        .field select,
        .field textarea {
            width: 100%;
            border: 1px solid #cfe1ef;
            border-radius: 10px;
            padding: 10px 11px;
            font-family: inherit;
            font-size: 14px;
            color: #173040;
            background: #ffffff;
        }
        .field textarea {
            min-height: 130px;
            resize: vertical;
        }
        .field input:focus,
        .field select:focus,
        .field textarea:focus {
            outline: none;
            border-color: #9fc0da;
            box-shadow: 0 0 0 2px rgba(15, 107, 174, 0.12);
        }
        .field.readonly input {
            background: #f2f8fd;
        }
        .field-full {
            grid-column: 1 / -1;
        }
        .section-e-wrap {
            grid-column: 1 / -1;
            border: 1px solid #d8e7f2;
            border-radius: 12px;
            background: #f9fcff;
            padding: 12px;
        }
        .section-e-wrap h3 {
            margin: 0 0 6px;
            font-size: 17px;
            color: #0d4568;
        }
        .section-e-note {
            margin: 0 0 10px;
            color: #587387;
            font-size: 13px;
        }
        .section-e-table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            border-radius: 10px;
            overflow: hidden;
        }
        .section-e-table th,
        .section-e-table td {
            border: 1px solid #d8e7f2;
            padding: 8px;
            vertical-align: top;
            font-size: 13px;
            color: #21465d;
        }
        .section-e-table th {
            background: #eef6fd;
            font-weight: 700;
            text-align: left;
        }
        .section-e-table .no-col { width: 40px; text-align: center; }
        .section-e-table .catatan-col { width: 220px; }
        .section-e-select,
        .section-e-input {
            width: 100%;
            border: 1px solid #cfe1ef;
            border-radius: 8px;
            padding: 8px 9px;
            font-family: inherit;
            font-size: 13px;
            color: #173040;
            background: #ffffff;
        }
        .section-e-select:focus,
        .section-e-input:focus {
            outline: none;
            border-color: #9fc0da;
            box-shadow: 0 0 0 2px rgba(15, 107, 174, 0.12);
        }
        .renewal-box {
            margin-top: 12px;
            border: 1px solid #d8e7f2;
            border-radius: 10px;
            background: #ffffff;
            padding: 10px;
        }
        .renewal-box h4 {
            margin: 0 0 6px;
            font-size: 15px;
            color: #0d4568;
        }
        .radio-row {
            display: flex;
            gap: 16px;
            align-items: center;
            flex-wrap: wrap;
            margin: 6px 0 10px;
        }
        .radio-row label {
            display: inline-flex;
            gap: 6px;
            align-items: center;
            font-size: 13px;
            color: #21465d;
            font-weight: 600;
        }
        .status-alert {
            margin: 0 0 12px;
            border-radius: 10px;
            padding: 10px 12px;
            font-size: 14px;
            font-weight: 600;
            border: 1px solid transparent;
        }
        .status-alert.success {
            background: #ecfdf3;
            border-color: #b7eac8;
            color: #166534;
        }
        .status-alert.error {
            background: #fff1f2;
            border-color: #fecdd3;
            color: #b91c1c;
        }
        .form-actions {
            grid-column: 1 / -1;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 4px;
        }
        .btn-submit {
            border: 1px solid #ffffff;
            box-shadow: inset 0 0 0 1px #ffffff, 0 1px 2px rgba(0, 0, 0, 0.18);
            color: #ffffff;
            background: linear-gradient(135deg, var(--brand-blue) 0%, var(--brand-teal) 100%);
            border-radius: 999px;
            padding: 10px 16px;
            font-weight: 700;
            cursor: pointer;
        }
        .caption {
            margin-top: 8px;
            font-size: 13px;
            color: #5d7484;
        }
        .sent-popup {
            position: fixed;
            inset: 0;
            background: rgba(6, 25, 40, 0.45);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1600;
            padding: 16px;
        }
        .sent-popup.show {
            display: flex;
        }
        .sent-popup-card {
            width: min(360px, 100%);
            background: #ffffff;
            border: 1px solid #d8e5ef;
            border-radius: 16px;
            box-shadow: 0 24px 54px rgba(3, 30, 54, 0.28);
            padding: 20px 18px 16px;
            text-align: center;
        }
        .sent-popup-icon {
            width: 84px;
            height: 84px;
            object-fit: contain;
            display: block;
            margin: 0 auto 10px;
        }
        .sent-popup-title {
            margin: 0 0 12px;
            font-size: 22px;
            font-weight: 800;
            color: #0f3f61;
        }
        .sent-popup-ok {
            min-width: 130px;
            border: none;
            border-radius: 10px;
            background: #0a7fbf;
            color: #fff;
            font-weight: 700;
            font-size: 14px;
            padding: 10px 14px;
            cursor: pointer;
        }
        .sent-popup-ok:hover {
            background: #086da5;
        }
        @media (max-width: 860px) {
            .aduan-grid { grid-template-columns: 1fr; }
            .topbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .topbar-actions { width: 100%; }
            .topbar-actions .btn { flex: 1; }
            .section-e-table .catatan-col { width: auto; }
        }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="topbar-title">
            <img src="${pageContext.request.contextPath}/icon/Staff.png" alt="Portal Staff">
            <span>Portal Staff</span>
        </div>
        <div class="topbar-actions">
            <a class="btn btn-secondary btn-icon" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama">
                <img src="${pageContext.request.contextPath}/icon/home.png" alt="Laman Utama">
            </a>
            <a class="btn btn-primary" href="${pageContext.request.contextPath}/logout">Log Keluar</a>
        </div>
    </header>

    <main class="container">
        <section class="aduan-section" aria-label="Borang Aduan">
            <%
                String complaintState = request.getParameter("staff_complaint");
                String sessionEmail = String.valueOf(session.getAttribute("email") == null ? "" : session.getAttribute("email"));
                String sessionUsername = String.valueOf(session.getAttribute("username") == null ? "" : session.getAttribute("username"));
            %>
            <h2>BORANG SIASATAN ADUAN PEMBEKAL DAN PRODUK AIR</h2>

            <% if ("forbidden".equals(complaintState)) { %>
                <div class="status-alert error">Akses ditolak. Hanya Admin/Staff dengan e-mel kerajaan dibenarkan menghantar aduan.</div>
            <% } else if ("invalid".equals(complaintState)) { %>
                <div class="status-alert error">Sila lengkapkan semua medan wajib borang aduan.</div>
            <% } else if ("error".equals(complaintState)) { %>
                <div class="status-alert error">Ralat semasa menyimpan aduan. Sila cuba semula.</div>
            <% } %>

            <form id="aduan-digital" class="aduan-grid" method="post" action="${pageContext.request.contextPath}/staff/complaints">
                <input type="hidden" name="_csrf" value="${csrf_token}">

                <div class="field readonly">
                    <label for="staffUsername">Nama Pengguna</label>
                    <input id="staffUsername" type="text" value="<%= sessionUsername %>" readonly>
                </div>
                <div class="field readonly">
                    <label for="staffEmail">E-mel Rasmi</label>
                    <input id="staffEmail" type="text" value="<%= sessionEmail %>" readonly>
                </div>

                <div class="field">
                    <label for="department">Bahagian / Jabatan *</label>
                    <input id="department" name="department" type="text" required placeholder="Contoh: Unit Operasi Air">
                </div>
                <div class="field">
                    <label for="complaintCategory">Kategori Aduan *</label>
                    <select id="complaintCategory" name="complaint_category" required>
                        <option value="">Pilih kategori</option>
                        <option value="Sistem">Sistem</option>
                        <option value="Perkhidmatan">Perkhidmatan</option>
                        <option value="Infrastruktur">Infrastruktur</option>
                        <option value="Dokumentasi">Dokumentasi</option>
                        <option value="Lain-lain">Lain-lain</option>
                    </select>
                </div>

                <div class="field field-full">
                    <label for="complaintTitle">Tajuk Aduan *</label>
                    <input id="complaintTitle" name="complaint_title" type="text" required placeholder="Ringkasan tajuk aduan">
                </div>

                <div class="field field-full">
                    <label for="complaintDetails">Butiran Aduan *</label>
                    <textarea id="complaintDetails" name="complaint_details" required placeholder="Sila jelaskan isu aduan secara lengkap"></textarea>
                </div>

                <div class="field">
                    <label for="incidentDate">Tarikh Kejadian</label>
                    <input id="incidentDate" name="incident_date" type="date">
                </div>
                <div class="field">
                    <label for="incidentLocation">Lokasi Kejadian</label>
                    <input id="incidentLocation" name="incident_location" type="text" placeholder="Contoh: Blok A, Tingkat 2">
                </div>

                <div class="field">
                    <label for="urgency">Tahap Keutamaan *</label>
                    <select id="urgency" name="urgency" required>
                        <option value="">Pilih tahap</option>
                        <option value="RENDAH">Rendah</option>
                        <option value="SEDERHANA">Sederhana</option>
                        <option value="TINGGI">Tinggi</option>
                        <option value="KRITIKAL">Kritikal</option>
                    </select>
                </div>
                <div class="field">
                    <label for="preferredContact">Kaedah Dihubungi</label>
                    <input id="preferredContact" name="preferred_contact" type="text" placeholder="Contoh: E-mel / Telefon">
                </div>

                <div class="section-e-wrap" aria-label="Bahagian E">
                    <h3>Bahagian E: Maklumat Aduan Terhadap Pembekal dan Produk</h3>
                    <p class="section-e-note">Sila nyatakan Ya / Tidak / Tidak Berkenaan bagi setiap perkara dan isi catatan jika perlu.</p>
                    <table class="section-e-table">
                        <thead>
                            <tr>
                                <th class="no-col">No</th>
                                <th>Perkara</th>
                                <th class="catatan-col">Maklum balas &amp; Catatan</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td class="no-col">1</td>
                                <td>Adakah Prosedur Operasi Standard (SOP) penghantaran dan pengendalian produk dari kilang ke tapak bina dipatuhi?</td>
                                <td>
                                    <select class="section-e-select" name="section_e_q1" required>
                                        <option value="">Pilih</option>
                                        <option value="YA">Ya</option>
                                        <option value="TIDAK">Tidak</option>
                                        <option value="TIDAK_BERKENAAN">Tidak Berkenaan</option>
                                    </select>
                                    <input class="section-e-input" type="text" name="section_e_note1" placeholder="Catatan (jika ada)">
                                </td>
                            </tr>
                            <tr>
                                <td class="no-col">2</td>
                                <td>Adakah produk memenuhi spesifikasi seperti dalam sijil pendaftaran produk yang berdaftar dengan JANS?</td>
                                <td>
                                    <select class="section-e-select" name="section_e_q2" required>
                                        <option value="">Pilih</option>
                                        <option value="YA">Ya</option>
                                        <option value="TIDAK">Tidak</option>
                                        <option value="TIDAK_BERKENAAN">Tidak Berkenaan</option>
                                    </select>
                                    <input class="section-e-input" type="text" name="section_e_note2" placeholder="Catatan (jika ada)">
                                </td>
                            </tr>
                            <tr>
                                <td class="no-col">3</td>
                                <td>Adakah Factory Acceptance Test (FAT) telah dijalankan?</td>
                                <td>
                                    <select class="section-e-select" name="section_e_q3" required>
                                        <option value="">Pilih</option>
                                        <option value="YA">Ya</option>
                                        <option value="TIDAK">Tidak</option>
                                        <option value="TIDAK_BERKENAAN">Tidak Berkenaan</option>
                                    </select>
                                    <input class="section-e-input" type="text" name="section_e_note3" placeholder="Catatan (jika ada)">
                                </td>
                            </tr>
                            <tr>
                                <td class="no-col">4</td>
                                <td>Adakah pemeriksaan produk dibuat sebelum pemasangan?</td>
                                <td>
                                    <select class="section-e-select" name="section_e_q4" required>
                                        <option value="">Pilih</option>
                                        <option value="YA">Ya</option>
                                        <option value="TIDAK">Tidak</option>
                                        <option value="TIDAK_BERKENAAN">Tidak Berkenaan</option>
                                    </select>
                                    <input class="section-e-input" type="text" name="section_e_note4" placeholder="Catatan (jika ada)">
                                </td>
                            </tr>
                            <tr>
                                <td class="no-col">5</td>
                                <td>Apakah tahap prestasi Perkhidmatan Selepas Jualan (After Sales Service)?</td>
                                <td>
                                    <select class="section-e-select" name="section_e_q5" required>
                                        <option value="">Pilih</option>
                                        <option value="YA">Ya</option>
                                        <option value="TIDAK">Tidak</option>
                                        <option value="TIDAK_BERKENAAN">Tidak Berkenaan</option>
                                    </select>
                                    <input class="section-e-input" type="text" name="section_e_note5" placeholder="Catatan (jika ada)">
                                </td>
                            </tr>
                            <tr>
                                <td class="no-col">6</td>
                                <td>Lain-lain perkara berkaitan (jika ada)</td>
                                <td>
                                    <select class="section-e-select" name="section_e_q6">
                                        <option value="">Pilih</option>
                                        <option value="YA">Ya</option>
                                        <option value="TIDAK">Tidak</option>
                                        <option value="TIDAK_BERKENAAN">Tidak Berkenaan</option>
                                    </select>
                                    <input class="section-e-input" type="text" name="section_e_note6" placeholder="Catatan (jika ada)">
                                </td>
                            </tr>
                        </tbody>
                    </table>

                    <div class="renewal-box">
                        <h4>Bahagian E: Ulasan Terhadap Pembaharuan Perakuan Pendaftaran Pembekal dan Produk Bekalan Air</h4>
                        <p class="section-e-note">Saya <strong>berpuas hati / tidak berpuas hati</strong> terhadap maklumbalas yang diberikan oleh pembekal.</p>
                        <div class="radio-row">
                            <label><input type="radio" name="renewal_satisfaction" value="BERPUAS_HATI" required> Berpuas hati</label>
                            <label><input type="radio" name="renewal_satisfaction" value="TIDAK_BERPUAS_HATI" required> Tidak berpuas hati</label>
                        </div>
                        <div class="field">
                            <label for="renewalReview">Jika tidak berpuas hati, sila beri ulasan</label>
                            <textarea id="renewalReview" name="renewal_review" placeholder="Nyatakan ulasan anda (jika ada)"></textarea>
                        </div>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn-submit">Hantar Borang Aduan</button>
                </div>
            </form>
            <p class="caption">Medan bertanda * adalah wajib.</p>
        </section>
    </main>

    <div class="sent-popup<%= "submitted".equals(complaintState) ? " show" : "" %>" id="staffSentPopup" aria-hidden="<%= "submitted".equals(complaintState) ? "false" : "true" %>">
        <div class="sent-popup-card" role="dialog" aria-modal="true" aria-labelledby="staffSentPopupTitle">
            <img src="${pageContext.request.contextPath}/icon/send.gif" alt="Berjaya dihantar" class="sent-popup-icon">
            <h4 class="sent-popup-title" id="staffSentPopupTitle">Borang Berjaya Dihantar!</h4>
            <button type="button" class="sent-popup-ok" id="staffSentPopupOkBtn">OK</button>
        </div>
    </div>

    <script>
        (function () {
            var popup = document.getElementById('staffSentPopup');
            var okBtn = document.getElementById('staffSentPopupOkBtn');

            if (!popup || !okBtn || !popup.classList.contains('show')) {
                return;
            }

            function closePopup() {
                popup.classList.remove('show');
                popup.setAttribute('aria-hidden', 'true');
                try {
                    var url = new URL(window.location.href);
                    url.searchParams.delete('staff_complaint');
                    window.history.replaceState({}, document.title, url.toString());
                } catch (error) {
                    // Ignore URL cleanup issues in older browsers.
                }
            }

            okBtn.addEventListener('click', closePopup);
            popup.addEventListener('click', function (event) {
                if (event.target === popup) {
                    closePopup();
                }
            });
        })();
    </script>
</body>
</html>
