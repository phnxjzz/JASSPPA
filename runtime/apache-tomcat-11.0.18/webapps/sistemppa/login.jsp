<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Log Masuk - Sistem Pendaftaran Pembekal dan Produk Air</title>
    <style>
:root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: inherit; background: url('${pageContext.request.contextPath}/assets/images/login-register-bg.jpg') center/cover no-repeat fixed; min-height: 100vh; display: grid; place-items: center; padding: 24px; position: relative; }
        body::before { content: ''; position: fixed; inset: 0; background: rgba(255,255,255,0.45); z-index: 0; pointer-events: none; }
        .login-shell { position: relative; z-index: 1; }
        .login-shell { display: grid; grid-template-columns: 1.05fr 0.95fr; width: 100%; max-width: 1080px; border-radius: 24px; overflow: hidden; box-shadow: 0 24px 60px rgba(6, 52, 79, 0.22); }
        .brand-panel { background: linear-gradient(180deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.08) 100%); color: white; padding: 40px; }
        .brand-panel .logo { width: 78px; height: 78px; border-radius: 18px; margin-bottom: 18px; object-fit: contain; padding: 6px; display: block; }
        .brand-panel h1 { font-size: 34px; margin-bottom: 10px; color: #000000; }
        .login-container { padding: 44px; background: rgba(255,255,255,0.95); }
        .login-header { margin-bottom: 30px; }
        .login-header h1 { color: #173040; font-size: 28px; margin-bottom: 8px; }
        .login-header p { color: #60798b; font-size: 14px; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 8px; color: #173040; font-weight: 700; }
        .form-group input { width: 100%; padding: 13px; border: 1px solid #d7e7ef; border-radius: 12px; font-size: 14px; }
        .form-group select { width: 100%; padding: 13px; border: 1px solid #d7e7ef; border-radius: 12px; font-size: 14px; }
        .form-group input:focus { outline: none; border-color: var(--brand-blue); }
        .form-group select:focus { outline: none; border-color: var(--brand-blue); }
        .login-btn { width: 100%; padding: 13px; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 100%); color: white; border: 1px solid #fff; border-radius: 12px; font-size: 16px; font-weight: 700; cursor: pointer; }
        .error-message { color: #d32f2f; padding: 12px; margin-bottom: 15px; background: #ffebee; border-radius: 10px; font-size: 14px; }
        .maintenance-notice {
            color: #7a4e1f;
            padding: 12px;
            margin-bottom: 15px;
            background: #fff4e6;
            border: 1px solid #f2c18b;
            border-radius: 10px;
            font-size: 14px;
        }
        .success-message { color: #166534; padding: 12px; margin-bottom: 15px; background: #dcfce7; border-radius: 10px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
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
        .success-title { font-size: 22px; line-height: 1.1; font-weight: 800; color: #0f5132; letter-spacing: 0.06em; text-transform: uppercase; text-align: center; }
        .success-text { display: none; }
        .success-ok { align-self: center; margin-top: 4px; border: 1px solid #0f5132 !important; background: #166534; color: #fff; border-radius: 10px; padding: 10px 24px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .portal-error-popup {
            border: 1px solid #fecaca;
            background: #ffffff;
            color: #991b1b;
            box-shadow: 0 16px 32px rgba(127, 29, 29, 0.22);
        }
        .portal-error-title { font-size: 22px; line-height: 1.2; font-weight: 800; color: #991b1b; letter-spacing: 0.02em; text-align: center; }
        .portal-error-ok { align-self: center; margin-top: 4px; border: 1px solid #7f1d1d !important; background: #b91c1c; color: #fff; border-radius: 10px; padding: 10px 24px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .portal-error-icon {
            width: 84px;
            height: 84px;
            object-fit: contain;
            background: transparent;
            border: none;
            filter: drop-shadow(0 3px 8px rgba(127, 29, 29, 0.24));
        }
        .success-message .success-gif {
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
        .register-link { text-align: center; margin-top: 20px; font-size: 14px; color: #60798b; }
        .register-link a { color: var(--brand-blue); text-decoration: none; font-weight: 700; }
        .forgot-link { text-align: right; margin-top: -10px; margin-bottom: 14px; }
        .forgot-link a { color: #146594; text-decoration: none; font-size: 13px; font-weight: 700; }
        .contact-box { margin-top: 16px; border: 1px solid #d7e7ef; border-radius: 12px; padding: 14px; background: #f8fcff; }
        .contact-box > strong { display: block; margin-bottom: 10px; color: #173040; font-size: 14px; }
        .contact-item { margin: 8px 0; color: #60798b; font-size: 13px; line-height: 1.45; }
        .contact-item .contact-label { display: block; font-weight: 700; color: #173040; margin-bottom: 2px; }
        .contact-item .contact-value { display: block; }
        .floating-home-btn { position: fixed; right: 16px; top: 16px; z-index: 20; display: inline-flex; align-items: center; justify-content: center; width: 38px; height: 38px; border-radius: 999px; border: 1px solid #fff; background: rgba(255, 255, 255, 0.18); }
        .floating-home-btn img { width: 18px; height: 18px; object-fit: contain; }
        @media (max-width: 920px) { .login-shell { grid-template-columns: 1fr; } .brand-panel { display:none; } }
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
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; display: inline-flex; align-items: center; gap: 8px; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; min-width: 0; }
        .jans-contact-section .contact-icon { width: 13px; height: 13px; object-fit: contain; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-line-hanging { margin-left: 21px; }
    </style>
</head>
<body>
    <% String selectedRole = (String) request.getAttribute("selected_role"); %>
    <% if (selectedRole == null) { selectedRole = ""; } %>
    <% boolean maintenanceMode = Boolean.TRUE.equals(request.getAttribute("maintenance_mode")); %>
    <% boolean userPortalLocked = maintenanceMode && "USER".equals(selectedRole); %>
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/icon/home.png" alt="Laman utama"></a>
    <div class="login-shell">
        <div class="brand-panel">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="logo" alt="Logo Jabatan Air Sabah">
            <h1>Sistem Pendaftaran Pembekal dan Produk Air</h1>
        </div>
        <div class="login-container">
            <div class="login-header">
                <h1>Log Masuk Sistem</h1>
                <p>Sistem Pendaftaran Pembekal dan Produk Air</p>
            </div>
        
        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="error-message"><%= error %></div>
        <% } %>
        <% if (userPortalLocked) { %>
            <div class="maintenance-notice">Portal Pemohon sedang dalam mod penyelenggaraan. Log masuk pemohon dinyahaktifkan sementara.</div>
        <% } %>
        <% String success = (String) request.getAttribute("success"); %>
        <% if (success != null) { %>
            <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
                <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
                <div class="success-popup-content">
                    <div class="success-title">BERJAYA!</div>
                    <div class="success-text"></div>
                    <button type="button" class="success-ok" data-close-success-popup>OK</button>
                </div>
            </div>
        <% } %>
        <% String portalError = (String) request.getAttribute("portal_error"); %>
        <% if (portalError != null) { %>
            <div id="portalErrorPopup" class="success-popup portal-error-popup show" role="dialog" aria-live="assertive" aria-label="Notifikasi portal salah">
                <img class="portal-error-icon" src="${pageContext.request.contextPath}/assets/images/salah.png" alt="Portal salah">
                <div class="success-popup-content">
                    <div class="portal-error-title"><%= portalError %></div>
                    <button type="button" class="portal-error-ok" data-close-portal-error-popup>OK</button>
                </div>
            </div>
        <% } %>
        
        <form method="POST" action="${pageContext.request.contextPath}/login">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <% if (!selectedRole.isEmpty()) { %>
                <input type="hidden" name="portal_role" value="<%= selectedRole %>">
            <% } %>

            <div class="form-group">
                <label for="username">Nama Pengguna</label>
                <input type="text" id="username" name="username" placeholder="Masukkan nama pengguna" required>
            </div>
            
            <div class="form-group">
                <label for="password">Kata Laluan</label>
                <input type="password" id="password" name="password" placeholder="Masukkan kata laluan" required>
            </div>

            <div class="forgot-link">
                <a href="${pageContext.request.contextPath}/forgot-password">Lupa kata laluan?</a>
            </div>
            
            <button type="submit" class="login-btn">Log Masuk</button>
        </form>
        
            <div class="register-link">
                Belum mempunyai akaun? <a href="${pageContext.request.contextPath}/register">Daftar di sini</a>
            </div>
            <div class="container" style="padding-top:0;">
                <div class="jans-contact-section">
                    <h3><img class="contact-icon" src="${pageContext.request.contextPath}/icon/contact.png" alt="Hubungi JAS"> Hubungi JAS</h3>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/address.png" alt="Alamat"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/phone.png" alt="Tel"><span>Tel: +60-88-232364 (HQ)</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/fax.png" alt="Fax"><span>Fax: +60-88-232396</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/email.png" alt="Email"><span>Email: jans.hq@sabah.gov.my</span></p></div>
            </div>
        </div>
    </div>
<script>
(function() {
    var popup = document.getElementById('successPopup');
    function closePopupElement(popupEl) {
        if (!popupEl) return;
        popupEl.classList.remove('show');
        window.setTimeout(function() {
            if (popupEl && popupEl.parentNode) popupEl.parentNode.removeChild(popupEl);
        }, 260);
    }

    if (popup) {
        var closeBtn = popup.querySelector('[data-close-success-popup]');
        if (closeBtn) closeBtn.addEventListener('click', function () { closePopupElement(popup); });
    }

    var portalErrorPopup = document.getElementById('portalErrorPopup');
    if (portalErrorPopup) {
        var closePortalBtn = portalErrorPopup.querySelector('[data-close-portal-error-popup]');
        if (closePortalBtn) closePortalBtn.addEventListener('click', function () { closePopupElement(portalErrorPopup); });
    }
})();
</script>
</body>
</html>



