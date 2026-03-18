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
        .brand-panel img.logo { width: 78px; background: white; border-radius: 18px; padding: 8px; margin-bottom: 18px; }
        .brand-panel h1 { font-size: 34px; margin-bottom: 10px; }
        .brand-panel p { max-width: 420px; line-height: 1.7; }
        .brand-panel img.contact { width: 100%; max-width: 360px; margin-top: 24px; border-radius: 18px; border: 1px solid rgba(255,255,255,0.25); }
        .login-container { background: white; padding: 44px; }
        .login-header { margin-bottom: 30px; }
        .login-header h1 { color: #173040; font-size: 28px; margin-bottom: 8px; }
        .login-header p { color: #60798b; font-size: 14px; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 8px; color: #173040; font-weight: 700; }
        .form-group input { width: 100%; padding: 13px; border: 1px solid #d7e7ef; border-radius: 12px; font-size: 14px; }
        .form-group input:focus { outline: none; border-color: var(--brand-blue); }
        .login-btn { width: 100%; padding: 13px; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 100%); color: white; border: none; border-radius: 12px; font-size: 16px; font-weight: 700; cursor: pointer; }
        .error-message { color: #d32f2f; padding: 12px; margin-bottom: 15px; background: #ffebee; border-radius: 10px; font-size: 14px; }
        .success-message { color: #166534; padding: 12px; margin-bottom: 15px; background: #dcfce7; border-radius: 10px; font-size: 14px; }
        .register-link { text-align: center; margin-top: 20px; font-size: 14px; color: #60798b; }
        .register-link a { color: var(--brand-blue); text-decoration: none; font-weight: 700; }
        @media (max-width: 920px) { .login-shell { grid-template-columns: 1fr; } .brand-panel { display:none; } }
    </style>
</head>
<body>
    <div class="login-shell">
        <div class="brand-panel">
            <img class="logo" src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" alt="Logo Jabatan Air Sabah">
            <h1>SPPA</h1>
            <p>Portal rasmi Jabatan Air Negeri Sabah untuk pendaftaran produk air, semakan permohonan, dan rujukan produk yang telah berdaftar.</p>
            <img class="contact" src="${pageContext.request.contextPath}/assets/images/contact-jans.png" alt="Maklumat hubungan Jabatan Air Sabah">
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
                <label for="username">Nama Pengguna</label>
                <input type="text" id="username" name="username" placeholder="Masukkan nama pengguna" required>
            </div>
            
            <div class="form-group">
                <label for="password">Kata Laluan</label>
                <input type="password" id="password" name="password" placeholder="Masukkan kata laluan" required>
            </div>
            
            <button type="submit" class="login-btn">Log Masuk</button>
        </form>
        
            <div class="register-link">
                Belum mempunyai akaun? <a href="${pageContext.request.contextPath}/register">Daftar di sini</a>
            </div>
        </div>
    </div>
</body>
</html>
