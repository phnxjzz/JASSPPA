<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar Pemohon - SPPA</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #06344f 0%, #0097d9 58%, #fff9b8 150%); min-height: 100vh; display: grid; place-items: center; padding: 24px; }
        .shell { display: grid; grid-template-columns: 1fr 1fr; width: 100%; max-width: 1040px; border-radius: 24px; overflow: hidden; box-shadow: 0 22px 58px rgba(6, 52, 79, 0.2); }
        .info { background: linear-gradient(180deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0.08) 100%); color: white; padding: 40px; }
        .info .logo { width: 78px; height: 78px; background: white; border-radius: 18px; margin-bottom: 18px; display: grid; place-items: center; color: var(--brand-navy); font-size: 22px; font-weight: 800; letter-spacing: 0.08em; }
        .info h1 { margin-bottom: 10px; font-size: 34px; }
        .info p { opacity: 0.94; margin-bottom: 20px; }
        .info .contact { width: 100%; border-radius: 18px; border: 1px solid rgba(255,255,255,0.25); padding: 14px; background: rgba(6, 52, 79, 0.28); }
        .info .contact strong { display: block; margin-bottom: 8px; }
        .info .contact p { margin: 4px 0; font-size: 13px; }
        .card { background: white; padding: 36px; }
        h2 { margin-bottom: 8px; color: #173040; }
        p.form-copy { color: #60798b; margin-bottom: 20px; }
        .field { margin-bottom: 16px; }
        label { display: block; margin-bottom: 6px; font-weight: 700; color: #173040; }
        input { width: 100%; padding: 12px; border: 1px solid #d7e7ef; border-radius: 12px; }
        .error { margin-bottom: 14px; background: #fee2e2; color: #b91c1c; padding: 12px; border-radius: 10px; }
        .btn { width: 100%; border: none; border-radius: 12px; padding: 13px; background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 100%); color: white; font-weight: 700; cursor: pointer; }
        .footer { margin-top: 18px; text-align: center; color: #64748b; }
        .footer a { color: var(--brand-blue); text-decoration: none; font-weight: 700; }
        @media (max-width: 920px) { .shell { grid-template-columns: 1fr; } .info { display: none; } }
    </style>
</head>
<body>
    <div class="shell">
        <div class="info">
            <div class="logo" aria-label="Logo Jabatan Air Sabah">JANS</div>
            <h1>Akaun Pemohon SPPA</h1>
            <p>Cipta akaun untuk mengisi borang PPP1 secara online, menyemak senarai produk berdaftar, dan memantau keputusan semakan pentadbir.</p>
            <div class="contact" aria-label="Maklumat hubungan Jabatan Air Sabah">
                <strong>Hubungi JANS</strong>
                <p>Telefon: 088-326888</p>
                <p>Email: info@jwater.gov.my</p>
                <p>Kota Kinabalu, Sabah</p>
            </div>
        </div>
        <div class="card">
        <h2>Daftar Akaun Pemohon</h2>
        <p class="form-copy">Cipta akaun untuk mengisi borang PPP1 secara online dan memantau status permohonan.</p>

        <% if (request.getAttribute("error") != null) { %>
            <div class="error"><%= request.getAttribute("error") %></div>
        <% } %>

        <form method="post" action="${pageContext.request.contextPath}/register">
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
                <input id="password" name="password" type="password" required>
            </div>
            <div class="field">
                <label for="confirm_password">Sahkan Kata Laluan</label>
                <input id="confirm_password" name="confirm_password" type="password" required>
            </div>
            <button class="btn" type="submit">Daftar Akaun</button>
        </form>

            <div class="footer">
                Sudah ada akaun? <a href="${pageContext.request.contextPath}/login">Log masuk di sini</a>
            </div>
        </div>
    </div>
</body>
</html>