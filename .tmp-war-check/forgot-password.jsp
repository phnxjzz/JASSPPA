<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lupa Kata Laluan - SPPA</title>
    <style>
        :root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; min-height: 100vh; display: grid; place-items: center; padding: 24px; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-yellow) 100%); }
        .card { width: 100%; max-width: 520px; background: #fff; border-radius: 18px; box-shadow: 0 22px 60px rgba(6, 52, 79, 0.25); padding: 28px; }
        h1 { margin: 0 0 8px; color: #173040; }
        .subtitle { margin: 0 0 20px; color: #60798b; }
        .field { margin-bottom: 14px; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: #173040; }
        .field input { width: 100%; padding: 12px; border-radius: 12px; border: 1px solid #d7e7ef; }
        .actions { display: flex; gap: 10px; margin-top: 8px; }
        .btn { border: 1px solid #fff; border-radius: 12px; padding: 12px 16px; font-weight: 700; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; justify-content: center; }
        .btn-primary { background: linear-gradient(135deg, var(--brand-navy), var(--brand-blue), var(--brand-green)); color: #fff; }
        .btn-secondary { background: #e5f2f9; color: #0F6BAE; }
        .error { padding: 11px 12px; border-radius: 10px; background: #ffe9e9; color: #b42318; margin-bottom: 14px; }
                        .contact-box { margin-top: 16px; border: 1px solid #d7e7ef; border-radius: 12px; padding: 12px; background: #f8fcff; }
                        .contact-box strong { display: block; margin-bottom: 6px; color: #173040; }
                        .contact-box p { margin: 3px 0; color: #60798b; font-size: 13px; }
                        .floating-home-btn { position: fixed; right: 16px; top: 16px; z-index: 20; display: inline-flex; align-items: center; justify-content: center; width: 38px; height: 38px; border-radius: 999px; border: 1px solid #fff; background: rgba(255,255,255,0.18); }
                        .floating-home-btn img { width: 18px; height: 18px; object-fit: contain; }
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
        }</style>
</head>
<body>
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/assets/images/icon-home.png" alt="Laman utama"></a>
    <div class="card">
        <h1>Lupa Kata Laluan</h1>
        <p class="subtitle">Masukkan maklumat akaun berdaftar anda untuk tetapkan kata laluan baharu.</p>

        <% if (request.getAttribute("error") != null) { %>
            <div class="error"><%= request.getAttribute("error") %></div>
        <% } %>

        <form method="post" action="${pageContext.request.contextPath}/forgot-password">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <div class="field">
                <label for="username">Nama Pengguna</label>
                <input id="username" name="username" type="text" required value="<%= request.getAttribute("username") == null ? "" : request.getAttribute("username") %>">
            </div>
            <div class="field">
                <label for="full_name">Nama Penuh</label>
                <input id="full_name" name="full_name" type="text" required placeholder="Seperti dalam kad pengenalan" value="<%= request.getAttribute("full_name") == null ? "" : request.getAttribute("full_name") %>">
            </div>
            <div class="field">
                <label for="email">Email Berdaftar</label>
                <input id="email" name="email" type="email" required value="<%= request.getAttribute("email") == null ? "" : request.getAttribute("email") %>">
            </div>
            <div class="field">
                <label for="new_password">Kata Laluan Baharu</label>
                <input id="new_password" name="new_password" type="password" required oninput="checkStrength(this.value)">
                <div id="pw-strength" style="margin-top:6px;font-size:12px;color:#60798b;"></div>
                <ul style="margin:4px 0 0 16px;padding:0;font-size:12px;color:#60798b;">
                    <li>Sekurang-kurangnya 8 aksara</li>
                    <li>Sekurang-kurangnya satu nombor (0-9)</li>
                    <li>Sekurang-kurangnya satu aksara khas (contoh: !@#$%)</li>
                </ul>
            </div>
            <div class="field">
                <label for="confirm_password">Sahkan Kata Laluan Baharu</label>
                <input id="confirm_password" name="confirm_password" type="password" required>
            </div>
            <div class="actions">
                <button class="btn btn-primary" type="submit">Set Semula Kata Laluan</button>
                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/login">Kembali Login</a>
            </div>
        </form>
        <script>
        function checkStrength(pw) {
            var el = document.getElementById('pw-strength');
            if (!pw) { el.textContent = ''; return; }
            var issues = [];
            if (pw.length < 8) issues.push('terlalu pendek');
            if (!/\d/.test(pw)) issues.push('tiada nombor');
            if (!/[!@#$%^&*()\-_=+\[\]{};':"\\|,.<>\/?]/.test(pw)) issues.push('tiada aksara khas');
            if (issues.length === 0) {
                el.textContent = 'Kata laluan kukuh';
                el.style.color = '#0a7c2e';
            } else {
                el.textContent = 'Lemah: ' + issues.join(', ');
                el.style.color = '#b42318';
            }
        }
        </script>
        <div class="contact-box">
            <strong>Hubungi JANS</strong>
            <p><strong>Alamat</strong><br>SABAH WATER DEPARTMENT / JABATAN AIR SABAH, Jalan Penampang, 88200 Kota Kinabalu, Sabah</p>
            <p><strong>Telefon</strong><br>+60-88-232364 (HQ)</p>
            <p><strong>Faks</strong><br>+60-88-232396</p>
            <p><strong>E-mel</strong><br>jans.hq@sabah.gov.my</p>
        </div>
    </div>
</body>
</html>
