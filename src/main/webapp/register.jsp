<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar Pemohon - SPPA</title>
    <style>
        :root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-yellow) 100%); min-height: 100vh; display: grid; place-items: center; padding: 24px; }
        .shell { display: grid; grid-template-columns: 1fr 1fr; width: 100%; max-width: 1040px; border-radius: 24px; overflow: hidden; box-shadow: 0 22px 58px rgba(6, 52, 79, 0.2); }
        .info { background: linear-gradient(180deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.08) 100%); color: white; padding: 40px; }
        .info .logo { width: 78px; height: 78px; border-radius: 18px; margin-bottom: 18px; display: grid; place-items: center; color: var(--brand-navy); font-size: 22px; font-weight: 800; letter-spacing: 0.08em; }
        .info h1 { margin-bottom: 10px; font-size: 34px; }
        .info p { opacity: 0.94; margin-bottom: 20px; }
        .info .contact { width: 100%; border-radius: 18px; border: 1px solid rgba(255,255,255,0.25); padding: 14px; background: rgba(6, 52, 79, 0.28); }
        .info .contact strong { display: block; margin-bottom: 8px; }
        .info .contact p { margin: 4px 0; font-size: 13px; }
        .info .contact strong img { width: 22px; height: 22px; vertical-align: middle; margin-right: 8px; object-fit: contain; }
        .card { padding: 36px; }
        h2 { margin-bottom: 8px; color: #173040; }
        p.form-copy { color: #60798b; margin-bottom: 20px; }
        .field { margin-bottom: 16px; }
        label { display: block; margin-bottom: 6px; font-weight: 700; color: #173040; }
        input { width: 100%; padding: 12px; border: 1px solid #d7e7ef; border-radius: 12px; }
        .password-help { margin-top: 6px; font-size: 12px; color: #60798b; line-height: 1.5; }
        .error { margin-bottom: 14px; background: #fee2e2; color: #b91c1c; padding: 12px; border-radius: 10px; }
        .btn { width: 100%; border: 1px solid #fff; border-radius: 12px; padding: 13px; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 100%); color: white; font-weight: 700; cursor: pointer; }
        .footer { margin-top: 18px; text-align: center; color: #64748b; }
        .footer a { color: var(--brand-blue); text-decoration: none; font-weight: 700; }
        @media (max-width: 920px) { .shell { grid-template-columns: 1fr; } .info { display: none; } }
                    
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
        .floating-home-btn {
            position: static;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            margin-left: 12px;
            border-radius: 999px;
            border: 1px solid #fff;
            background: rgba(255, 255, 255, 0.12);
            text-decoration: none;
            vertical-align: middle;
        }
        .floating-home-btn img {
            width: 16px;
            height: 16px;
            object-fit: contain;
        }
        </style>
</head>
<body>
    <div class="shell">
        <div class="info">
            <div class="logo" aria-label="Logo Jabatan Air Sabah">JANS</div>
            <h1>Akaun Pemohon SPPA</h1>
            <p>Cipta akaun untuk mengisi borang PPP1 secara online, menyemak senarai produk berdaftar, dan memantau keputusan semakan pentadbir.</p>
            <div class="contact" aria-label="Maklumat hubungan Jabatan Air Sabah">
                <strong><img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Hubungi">Hubungi JANS</strong>
                <p>Telefon: +60-88-232364 (HQ)</p>
                <p>Fax: +60-88-232396</p>
                <p>Email: jans.hq@sabah.gov.my</p>
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
            <button class="btn" type="submit">Daftar Akaun</button>
        </form>

            <div class="footer">
                Sudah ada akaun? <a href="${pageContext.request.contextPath}/login">Log masuk di sini</a>
            </div>
        </div>
    </div>
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/assets/images/icon-home.png" alt="Laman utama"></a>
<script>
(function() {
    var form = document.querySelector('form[action$="/register"]');
    var passwordInput = document.getElementById('password');
    var confirmInput = document.getElementById('confirm_password');

    if (form && passwordInput && confirmInput) {
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
            }
        });

    }
})();
</script>
</body>
</html>
