<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Timestamp" %>
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
<%
    String avatarValue = request.getAttribute("avatar_url") == null ? null : String.valueOf(request.getAttribute("avatar_url"));
    String avatarToken = avatarValue == null ? "0" : String.valueOf(avatarValue.hashCode());
    java.util.List<java.util.Map<String, Object>> approvedCertificates = (java.util.List<java.util.Map<String, Object>>) request.getAttribute("approved_certificates");
    if (approvedCertificates == null) {
        approvedCertificates = java.util.Collections.emptyList();
    }
    Object approvedCertificateCount = request.getAttribute("approved_certificate_count");
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
<<<<<<< HEAD
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Profil dan Sijil - SPPA</title>
=======
    <title>Profil &amp; Sijil - SPPA</title>
>>>>>>> origin/SPPPA
    <style>
:root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
            --surface: #ffffff;
            --muted: #60798b;
            --line: #d7e7ef;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: inherit; background: radial-gradient(circle at top left, #fffcd4 0%, #edf8ff 35%, #f7fbfd 100%); color: #183244; }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-yellow) 100%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 50px; height: 50px; border-radius: 14px; display: grid; place-items: center; color: var(--brand-navy); font-weight: 800; letter-spacing: 0.08em; }
        .brand h1 { margin: 0; font-size: 19px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; font-weight: 600; }
        .container { max-width: 1080px; margin: 28px auto; padding: 0 20px 32px; display: grid; grid-template-columns: 2fr 1fr; gap: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 20px; padding: 24px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); }
        .panel h2 { margin-top: 0; }
        .field { margin-bottom: 16px; }
        .field label { display: block; margin-bottom: 6px; color: var(--muted); font-size: 13px; font-weight: 700; }
        .field input { width: 100%; padding: 12px; border-radius: 12px; border: 1px solid var(--line); }
        .hint { color: var(--muted); font-size: 13px; margin-top: 6px; }
        .btn-row { display: flex; gap: 12px; margin-top: 10px; }
        .btn { padding: 12px 18px; border-radius: 12px; border: 1px solid #fff; font-weight: 700; cursor: pointer; text-decoration: none; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .message { padding: 12px 14px; border-radius: 12px; margin-bottom: 16px; }
        .error { background: #fdecec; color: #b42318; }
        .success { background: #ebfff0; color: #0f7a3d; }
        .message-with-gif { display: flex; align-items: center; gap: 10px; }
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
        .summary-item { padding: 14px; border-radius: 14px; background: #f6fbff; margin-bottom: 12px; }
        .summary-item strong { display: block; margin-bottom: 4px; }
        .avatar-card { display: grid; grid-template-columns: 96px 1fr; gap: 14px; align-items: center; padding: 14px; border: 1px dashed var(--line); border-radius: 16px; margin-bottom: 18px; background: #f9fcff; }
        .avatar-preview, .avatar-placeholder { width: 96px; height: 96px; border-radius: 24px; object-fit: cover; border: 1px solid var(--line); background: linear-gradient(135deg, #d7f0ff 0%, #fff7b2 100%); display: flex; align-items: center; justify-content: center; font-size: 34px; font-weight: 800; color: var(--brand-navy); }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); padding: 14px; background: #f8fbff; }
        .contact-image strong { display: block; margin-bottom: 8px; color: var(--brand-navy); }
        .contact-image p { margin: 4px 0; color: var(--muted); }
        @media (max-width: 900px) { .container { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; gap: 12px; } .navbar a { margin-left: 0; margin-right: 16px; } .avatar-card { grid-template-columns: 1fr; } }
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
        .icon-link { width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.38); transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 4px; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: rgba(255,255,255,0.26); }
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
<<<<<<< HEAD
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; display: inline-flex; align-items: center; gap: 8px; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; min-width: 0; }
        .jans-contact-section .contact-icon { width: 13px; height: 13px; object-fit: contain; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-line-hanging { margin-left: 21px; }
    </style>
    </head>
=======
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; }
        .jans-contact-section .contact-icon { width: 10px; height: 10px; object-fit: contain; flex: 0 0 10px; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }</style>
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; min-width: 0; }
        .jans-contact-section .contact-icon { display: inline-block; width: 10px; height: 10px; background: #0f6bae; border-radius: 2px; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
    </style>
>>>>>>> origin/SPPPA
<body>
    <div class="navbar">
        <div class="brand">
            <div class="brand-logo" aria-label="Logo Jabatan Air Sabah">JANS</div>
            <div>
<<<<<<< HEAD
                <h1>Profil dan Sijil</h1>
                <p>Sistem Pendaftaran Pembekal dan Produk Air</p>
=======
                <h1>Profil &amp; Sijil</h1>
                <p>Sistem Pendaftaran Produk Air</p>
>>>>>>> origin/SPPPA
            </div>
        </div>
        <div>
            <a class="icon-link" href="${pageContext.request.contextPath}/dashboard" title="Dashboard" aria-label="Dashboard"><img src="${pageContext.request.contextPath}/icon/dashboard.png" alt="Dashboard"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/assets/images/home.png" alt="Home"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
        </div>
    </div>

    <div class="container">
        <div class="panel">
            <h2>Maklumat Akaun</h2>

            <% if (request.getAttribute("error") != null) { %>
                <div class="message error"><%= request.getAttribute("error") %></div>
            <% } %>
            <% if (request.getParameter("updated") != null) { %>
                <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
                    <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
                    <div class="success-popup-content">
                        <div class="success-title">Berjaya!</div>
                        <div class="success-text"></div>
                        <button type="button" class="success-ok" data-close-success-popup>OK</button>
                    </div>
                </div>
            <% } %>

            <div class="avatar-card">
                <% if (avatarValue != null && !avatarValue.isBlank()) { %>
                    <img class="avatar-preview" src="${pageContext.request.contextPath}/avatars/view?v=<%= avatarToken %>" alt="Gambar profil semasa">
                <% } else { %>
                    <div class="avatar-placeholder"><%= request.getAttribute("full_name") != null && !String.valueOf(request.getAttribute("full_name")).isBlank() ? String.valueOf(request.getAttribute("full_name")).substring(0, 1).toUpperCase() : "P" %></div>
                <% } %>
            </div>

            <form method="post" action="${pageContext.request.contextPath}/profile" enctype="multipart/form-data">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <div class="field">
                    <label for="full_name">Nama Penuh</label>
                    <input id="full_name" name="full_name" type="text" value="<%= request.getAttribute("full_name") != null ? request.getAttribute("full_name") : "" %>" required>
                </div>
                <div class="field">
                    <label for="username">Nama Pengguna</label>
                    <input id="username" name="username" type="text" value="<%= request.getAttribute("username") != null ? request.getAttribute("username") : "" %>" required>
                </div>
                <div class="field">
                    <label for="email">Email</label>
                    <input id="email" name="email" type="email" value="<%= request.getAttribute("email") != null ? request.getAttribute("email") : "" %>" required>
                </div>
                <div class="field">
                    <label for="phone_number">Nombor Telefon</label>
                    <input id="phone_number" name="phone_number" type="tel" pattern="[0-9+()\-\s]{8,20}" inputmode="tel" value="<%= request.getAttribute("phone_number") != null ? request.getAttribute("phone_number") : "" %>" required>
                </div>
                <div class="field">
                    <label for="avatar_file">Muat Naik Gambar Profil</label>
                    <input id="avatar_file" name="avatar_file" type="file" accept="image/png,image/jpeg,image/gif,image/webp">
                    <div class="hint">Pilih fail imej dari device sendiri. Format disokong: PNG, JPG, GIF, WEBP. Maksimum 5MB.</div>
                </div>
                <div class="field">
                    <label for="password">Kata Laluan Baharu</label>
                    <input id="password" name="password" type="password">
                </div>
                <div class="field">
                    <label for="confirm_password">Sahkan Kata Laluan Baharu</label>
                    <input id="confirm_password" name="confirm_password" type="password">
                </div>
                <div class="btn-row">
                    <button class="btn btn-primary" type="submit">Simpan Perubahan</button>
                    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard">Kembali</a>
                </div>
            </form>
        </div>

        <div class="panel">
            <h2>Ringkasan Akaun</h2>
            <div class="summary-item">
                <strong>Status Akaun</strong>
                <span><%= request.getAttribute("status") != null ? request.getAttribute("status") : "-" %></span>
            </div>
            <div class="summary-item">
                <strong>Dicipta Pada</strong>
                <span><%= request.getAttribute("created_at") != null ? ((Timestamp) request.getAttribute("created_at")).toString() : "-" %></span>
            </div>
            <div class="summary-item">
                <strong>Nama Semasa</strong>
                <span><%= request.getAttribute("full_name") != null ? request.getAttribute("full_name") : "-" %></span>
            </div>
            <div class="summary-item">
                <strong>Nombor Telefon</strong>
                <span><%= request.getAttribute("phone_number") != null ? request.getAttribute("phone_number") : "-" %></span>
            </div>
            <div class="summary-item">
                <strong>Sijil Diluluskan</strong>
                <span><%= approvedCertificateCount != null ? approvedCertificateCount : 0 %></span>
            </div>
            <div class="summary-item" style="display:flex;justify-content:space-between;align-items:center;gap:12px;">
                <div>
                    <strong>Lihat Sijil</strong>
                    <span style="color:#60798b;font-size:13px;">Buka senarai sijil pendaftaran produk air yang telah diluluskan.</span>
                </div>
                <a class="btn btn-primary" href="#approvedCertificates">Lihat Sijil</a>
            </div>
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
    </div>

    <div class="panel" id="approvedCertificates" style="max-width:1080px;margin:0 20px 32px;">
        <h2>Sijil Pendaftaran Produk Air Diluluskan</h2>
        <p class="hint">Senarai ini memaparkan semua sijil yang telah diluluskan dan disimpan dalam sistem untuk rujukan serta cetakan semula.</p>
        <% if (approvedCertificates.isEmpty()) { %>
            <div class="message error" style="margin-top:10px;">Tiada sijil diluluskan ditemui buat masa ini.</div>
        <% } else { %>
            <div style="display:grid;gap:12px;">
                <% for (java.util.Map<String, Object> cert : approvedCertificates) {
                    String certNo = formatCertificateNumber(cert.get("certificate_number"));
                    String productName = cert.get("product_name") == null ? "-" : String.valueOf(cert.get("product_name"));
                    String companyName = cert.get("company_name") == null ? "-" : String.valueOf(cert.get("company_name"));
                    String standardName = cert.get("standard_name") == null ? "-" : String.valueOf(cert.get("standard_name"));
                    String validUntil = cert.get("valid_until") == null ? "-" : String.valueOf(cert.get("valid_until"));
                    String issuedAt = cert.get("issued_at") == null ? "-" : String.valueOf(cert.get("issued_at"));
                    int certAppId = ((Number) cert.get("id")).intValue();
                    boolean hasCertificateNumber = !"-".equals(certNo);
                %>
                <div class="summary-item" style="display:grid;grid-template-columns:1fr auto;gap:12px;align-items:center;">
                    <div>
                        <strong><%= certNo %> - <%= productName %></strong>
                        <div style="color:#60798b;font-size:13px;line-height:1.55;">
                            <div>Syarikat: <%= companyName %></div>
                            <div>Standard: <%= standardName %></div>
                            <div>Tarikh Dikeluarkan: <%= issuedAt %> | Sah Sehingga: <%= validUntil %></div>
                        </div>
                    </div>
                    <% if (hasCertificateNumber) { %>
                    <a class="btn btn-primary" href="${pageContext.request.contextPath}/certificate?id=<%= certAppId %>" target="_blank" rel="noopener noreferrer">Lihat Sijil</a>
                    <% } else { %>
                    <span class="btn btn-secondary" style="cursor:not-allowed;opacity:0.75;">Sijil Belum Dijana</span>
                    <% } %>
                </div>
                <% } %>
            </div>
        <% } %>
    </div>
<script>
(function() {
    var popup = document.getElementById('successPopup');
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


