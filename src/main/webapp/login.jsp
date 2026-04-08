<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log Masuk - Sistem Pendaftaran Produk Air</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #06344f 0%, #0097d9 58%, #fff9b8 150%); min-height: 100vh; display: grid; place-items: center; padding: 24px; }
        .login-shell { display: grid; grid-template-columns: 1.05fr 0.95fr; width: 100%; max-width: 1080px; border-radius: 24px; overflow: hidden; box-shadow: 0 24px 60px rgba(6, 52, 79, 0.22); }
        .brand-panel { background: linear-gradient(180deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.08) 100%); color: white; padding: 40px; }
        .brand-panel .logo { width: 78px; height: 78px; border-radius: 18px; margin-bottom: 18px; object-fit: contain; padding: 6px; display: block; }
        .brand-panel h1 { font-size: 34px; margin-bottom: 10px; }
        .brand-panel p { max-width: 420px; line-height: 1.7; }
        .login-container { padding: 44px; }
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
        .success-message { color: #166534; padding: 12px; margin-bottom: 15px; background: #dcfce7; border-radius: 10px; font-size: 14px; }
        .register-link { text-align: center; margin-top: 20px; font-size: 14px; color: #60798b; }
        .register-link a { color: var(--brand-blue); text-decoration: none; font-weight: 700; }
        .forgot-link { text-align: right; margin-top: -10px; margin-bottom: 14px; }
        .forgot-link a { color: #146594; text-decoration: none; font-size: 13px; font-weight: 700; }
        .contact-box { margin-top: 16px; border: 1px solid #d7e7ef; border-radius: 12px; padding: 12px; background: #f8fcff; }
        .contact-box strong { display: block; margin-bottom: 6px; color: #173040; }
        .contact-box p { margin: 3px 0; color: #60798b; font-size: 13px; }
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
        }</style>
</head>
<body>
    <% String selectedRole = (String) request.getAttribute("selected_role"); %>
    <% if (selectedRole == null) { selectedRole = ""; } %>
    <a class="floating-home-btn" href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/assets/images/icon-home.png" alt="Laman utama"></a>
    <div class="login-shell">
        <div class="brand-panel">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="logo" alt="Logo Jabatan Air Sabah">
            <h1>SPPA</h1>
            <p>Portal rasmi Jabatan Air Negeri Sabah untuk pendaftaran produk air, semakan permohonan, dan rujukan produk yang telah berdaftar.</p>
        </div>
        <div class="login-container">
            <div class="login-header">
                <h1>Log Masuk Sistem</h1>
                <p>Sistem Pendaftaran Produk Air</p>
            </div>
        
        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="error-message"><%= error %></div>
        <% } %>
        <% String success = (String) request.getAttribute("success"); %>
        <% if (success != null) { %>
            <div class="success-message"><%= success %></div>
        <% } %>
        
        <form method="POST" action="${pageContext.request.contextPath}/login">
            <div class="form-group">
                <label for="portal_role">Portal</label>
                <select id="portal_role" name="portal_role" required>
                    <option value="" <%= selectedRole.isEmpty() ? "selected" : "" %>>Pilih Portal</option>
                    <option value="ADMIN" <%= "ADMIN".equals(selectedRole) ? "selected" : "" %>>Portal Admin</option>
                    <option value="USER" <%= "USER".equals(selectedRole) ? "selected" : "" %>>Portal Pemohon</option>
                </select>
            </div>

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
            <div class="contact-box">
                <strong><img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Hubungi" style="width:16px;height:16px;object-fit:contain;vertical-align:middle;margin-right:6px;">Hubungi JANS</strong>
                <p>Telefon: +60-88-232364 (HQ)</p>
                <p>Fax: +60-88-232396</p>
                <p>Email: jans.hq@sabah.gov.my</p>
            </div>
        </div>
    </div>
</body>
</html>
