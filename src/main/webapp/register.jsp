<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Daftar Pemohon - SPPPA</title>
    <style>
:root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
<<<<<<< HEAD
        body { font-family: inherit; background: url('${pageContext.request.contextPath}/assets/images/login-register-bg.jpg') center/cover no-repeat fixed; min-height: 100vh; display: grid; place-items: center; padding: 24px; position: relative; }
=======
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: url('${pageContext.request.contextPath}/assets/images/login-register-bg.jpg') center/cover no-repeat fixed; min-height: 100vh; display: grid; place-items: center; padding: 24px; position: relative; }
>>>>>>> origin/SPPPA
        body::before { content: ''; position: fixed; inset: 0; background: rgba(255,255,255,0.45); z-index: 0; pointer-events: none; }
        .shell { position: relative; z-index: 1; }
        .shell { display: grid; grid-template-columns: 1fr 1fr; width: 100%; max-width: 1040px; border-radius: 24px; overflow: hidden; box-shadow: 0 22px 58px rgba(6, 52, 79, 0.2); }
        .info { background: linear-gradient(180deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.08) 100%); color: white; padding: 40px; }
        .info .logo { width: 78px; height: 78px; border-radius: 18px; margin-bottom: 18px; display: grid; place-items: center; color: var(--brand-navy); font-size: 22px; font-weight: 800; letter-spacing: 0.08em; }
        .info h1 { margin-bottom: 10px; font-size: 34px; color: #000000; }
        .info p { opacity: 0.94; margin-bottom: 20px; }
        .info .contact { width: 100%; border-radius: 18px; border: 1px solid rgba(255,255,255,0.25); padding: 14px; background: rgba(6, 52, 79, 0.28); }
        .info .contact strong { display: block; margin-bottom: 8px; }
        .info .contact p { margin: 4px 0; font-size: 13px; }
        .info .contact strong img { width: 22px; height: 22px; vertical-align: middle; margin-right: 8px; object-fit: contain; }
        .card { padding: 36px; background: rgba(255,255,255,0.95); }
        h2 { margin-bottom: 8px; color: #173040; }
        p.form-copy { color: #60798b; margin-bottom: 20px; }
        .field { margin-bottom: 16px; }
        label { display: block; margin-bottom: 6px; font-weight: 700; color: #173040; }
        input { width: 100%; padding: 12px; border: 1px solid #d7e7ef; border-radius: 12px; }
        .password-help { margin-top: 6px; font-size: 12px; color: #60798b; line-height: 1.5; }
        .error { margin-bottom: 14px; background: #fee2e2; color: #b91c1c; padding: 12px; border-radius: 10px; }
        .btn { width: 100%; border: 1px solid #fff; border-radius: 12px; padding: 13px; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 100%); color: white; font-weight: 700; cursor: pointer; }
        .btn:disabled { opacity: 0.6; cursor: not-allowed; }
        .privacy-consent-box { margin: 14px 0 16px; padding: 12px 14px; background: #f5f8fb; border: 1px solid #d7e7ef; border-radius: 12px; }
        .privacy-consent-label { display: flex; align-items: flex-start; gap: 10px; margin: 0; font-weight: 600; color: #173040; line-height: 1.5; font-size: 14px; }
        .privacy-consent-label input[type="checkbox"] { width: 18px; height: 18px; margin-top: 2px; flex: 0 0 18px; }
<<<<<<< HEAD
        .privacy-consent-label span { display: block; text-align: justify; text-justify: inter-word; line-height: 1.65; letter-spacing: 0.01em; }
=======
>>>>>>> origin/SPPPA
        .footer { margin-top: 18px; text-align: center; color: #64748b; }
        .footer a { color: var(--brand-blue); text-decoration: none; font-weight: 700; }
        @media (max-width: 920px) { .shell { grid-template-columns: 1fr; } .info { display: none; } }
        @media (max-width: 576px) { .privacy-consent-label { gap: 8px; font-size: 13px; } .privacy-consent-label span { text-align: left; line-height: 1.55; letter-spacing: 0; } }
                    
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
        .top-home-btn {
            position: fixed;
            top: 18px;
            right: 18px;
            z-index: 20;
            width: 42px;
            height: 42px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            border: 1px solid rgba(255,255,255,0.45);
            background: rgba(15, 107, 174, 0.62);
            box-shadow: 0 8px 20px rgba(15, 30, 44, 0.28);
            text-decoration: none;
            transition: transform 0.16s ease, background 0.16s ease;
        }
        .top-home-btn img {
            width: 20px;
            height: 20px;
            object-fit: contain;
        }
<<<<<<< HEAD
        .top-home-btn:hover {
            transform: translateY(-1px) scale(1.03);
            background: rgba(15, 107, 174, 0.8);
        }
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; display: inline-flex; align-items: center; gap: 8px; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; font-size: 13px; color: #4e6a7c; line-height: 1.45; }
        .jans-contact-section .contact-icon { width: 13px; height: 13px; object-fit: contain; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-line-hanging { margin-left: 21px; }
=======
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; font-size: 13px; color: #4e6a7c; line-height: 1.45; }
        .jans-contact-section .contact-icon { display: inline-block; width: 10px; height: 10px; background: #0f6bae; border-radius: 2px; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
>>>>>>> origin/SPPPA
        </style>
</head>
<body>
    <a class="top-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/icon/home.png" alt="Laman utama"></a>
    <div class="shell">
        <div class="info">
<<<<<<< HEAD
            <h1>Daftar Akaun Sistem Pendaftaran Pembekal dan Produk Air</h1>
            <div class="container" style="padding-top:0;">
                <div class="jans-contact-section">
                    <h3><img class="contact-icon" src="${pageContext.request.contextPath}/icon/contact.png" alt="Hubungi JAS"> Hubungi JAS</h3>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/address.png" alt="Alamat"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/phone.png" alt="Tel"><span>Tel: +60-88-232364 (HQ)</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/fax.png" alt="Fax"><span>Fax: +60-88-232396</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/email.png" alt="Email"><span>Email: jans.hq@sabah.gov.my</span></p></div>
=======
            <h1>Daftar Akaun Sistem Pendaftaran Produk Air</h1>
            <div class="container" style="padding-top:0;">
                <div class="jans-contact-section">
                    <h3>Hubungi JANS</h3>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><span>Tel: +60-88-232364 (HQ) , Fax: +60-88-232396</span></p>
                <p class="contact-line"><span>Email: jans.hq@sabah.gov.my</span></p></div>
>>>>>>> origin/SPPPA
            </div>
        </div>
        <div class="card">
        <h2>Daftar Akaun Pemohon</h2>
        <p class="form-copy">Cipta akaun untuk mengisi borang PPP1 secara online dan memantau status permohonan.</p>

        <% if (request.getAttribute("error") != null) { %>
            <div class="error"><%= request.getAttribute("error") %></div>
        <% } %>

        <form method="post" action="${pageContext.request.contextPath}/register">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <div class="field">
                <label for="full_name">Nama Penuh</label>
                <input id="full_name" name="full_name" type="text" required>
            </div>
            <div class="field">
                <label for="username">Nama Pengguna</label>
                <input id="username" name="username" type="text" required>
            </div>
            <div class="field">
                <label for="phone_number">Nombor Telefon</label>
                <input id="phone_number" name="phone_number" type="tel" pattern="[0-9+()\-\s]{8,20}" inputmode="tel" required>
            </div>
            <div class="field">
                <label for="email">Email</label>
                <input id="email" name="email" type="email" required>
            </div>
            <div class="field">
                <label for="password">Kata Laluan</label>
                <input id="password" name="password" type="password" minlength="10" pattern="(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{10,}" autocomplete="new-password" required>
                <div class="password-help">Minimum 10 aksara, mesti ada huruf besar, huruf kecil, nombor dan simbol khas.</div>
            </div>
            <div class="field">
                <label for="confirm_password">Sahkan Kata Laluan</label>
                <input id="confirm_password" name="confirm_password" type="password" minlength="10" autocomplete="new-password" required>
            </div>
            <div class="privacy-consent-box">
                <label for="privacy_consent" class="privacy-consent-label">
                    <input id="privacy_consent" name="privacy_consent" type="checkbox" value="1" required>
<<<<<<< HEAD
                    <span>Segala maklumat yang dikemukakan semasa pendaftaran akan digunakan hanya bagi tujuan pendaftaran akaun. Maklumat peribadi akan dirahsiakan dan tidak akan didedahkan atau dikongsi dengan mana-mana pihak ketiga.</span>
=======
                    <span>Dengan mendaftar anda bersetuju bahawa maklumat anda hanya akan digunakan untuk tujuan pendaftaran akaun sahaja. Kami menjamin maklumat peribadi anda tidak akan didedahkan atau dikongsi kepada mana-mana pihak ketiga.</span>
>>>>>>> origin/SPPPA
                </label>
            </div>
            <button id="registerSubmitBtn" class="btn" type="submit" disabled>Daftar Akaun</button>
        </form>

            <div class="footer">
                Sudah ada akaun? <a href="${pageContext.request.contextPath}/login">Log masuk di sini</a>
            </div>
        </div>
    </div>
<script>
(function() {
    var form = document.querySelector('form[action$="/register"]');
    var passwordInput = document.getElementById('password');
    var confirmInput = document.getElementById('confirm_password');
    var consentCheckbox = document.getElementById('privacy_consent');
    var submitBtn = document.getElementById('registerSubmitBtn');

    function syncSubmitState() {
        if (!consentCheckbox || !submitBtn) return;
        submitBtn.disabled = !consentCheckbox.checked;
    }

    if (form && passwordInput && confirmInput) {
        syncSubmitState();
        if (consentCheckbox) {
            consentCheckbox.addEventListener('change', syncSubmitState);
        }

        form.addEventListener('submit', function (event) {
            var passwordValue = passwordInput.value || '';
            var rule = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{10,}$/;
            if (!rule.test(passwordValue)) {
                event.preventDefault();
                alert('Kata laluan mesti minimum 10 aksara serta mengandungi huruf besar, huruf kecil, nombor dan simbol khas.');
                passwordInput.focus();
                return;
            }
            if (passwordValue !== (confirmInput.value || '')) {
                event.preventDefault();
                alert('Pengesahan kata laluan tidak sepadan.');
                confirmInput.focus();
                return;
            }

            if (consentCheckbox && !consentCheckbox.checked) {
                event.preventDefault();
                alert('Sila tandakan persetujuan privasi sebelum daftar akaun.');
                consentCheckbox.focus();
            }
        });

    }
})();
</script>
</body>
</html>

<<<<<<< HEAD


=======
>>>>>>> origin/SPPPA
