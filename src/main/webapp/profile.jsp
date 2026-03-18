<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Timestamp" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kemaskini Profil - SPPA</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-yellow: #fff212;
            --surface: #ffffff;
            --muted: #60798b;
            --line: #d7e7ef;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: radial-gradient(circle at top left, #fffcd4 0%, #edf8ff 35%, #f7fbfd 100%); color: #183244; }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 76%, var(--brand-yellow) 180%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand img { width: 50px; background: white; border-radius: 14px; padding: 6px; }
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
        .btn { padding: 12px 18px; border-radius: 12px; border: none; font-weight: 700; cursor: pointer; text-decoration: none; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .message { padding: 12px 14px; border-radius: 12px; margin-bottom: 16px; }
        .error { background: #fdecec; color: #b42318; }
        .success { background: #ebfff0; color: #0f7a3d; }
        .summary-item { padding: 14px; border-radius: 14px; background: #f6fbff; margin-bottom: 12px; }
        .summary-item strong { display: block; margin-bottom: 4px; }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); }
        @media (max-width: 900px) { .container { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; gap: 12px; } .navbar a { margin-left: 0; margin-right: 16px; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Kemaskini Profil Pemohon</h1>
                <p>Sistem Pendaftaran Produk Air</p>
            </div>
        </div>
        <div>
            <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
            <a href="${pageContext.request.contextPath}/logout">Log Keluar</a>
        </div>
    </div>

    <div class="container">
        <div class="panel">
            <h2>Maklumat Akaun</h2>
            <p style="color:#60798b;">Kemaskini maklumat pemohon sebenar, termasuk nama paparan, email, pautan gambar profil, dan kata laluan.</p>

            <% if (request.getAttribute("error") != null) { %>
                <div class="message error"><%= request.getAttribute("error") %></div>
            <% } %>
            <% if (request.getParameter("updated") != null) { %>
                <div class="message success">Profil berjaya dikemaskini.</div>
            <% } %>

            <form method="post" action="${pageContext.request.contextPath}/profile">
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
                    <label for="avatar_url">Pautan Gambar Profil</label>
                    <input id="avatar_url" name="avatar_url" type="url" value="<%= request.getAttribute("avatar_url") != null ? request.getAttribute("avatar_url") : "" %>">
                    <div class="hint">Pilihan. Masukkan URL imej jika anda mahu paparan profil lebih rasmi.</div>
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
            <img class="contact-image" src="${pageContext.request.contextPath}/assets/images/contact-jans.png" alt="Maklumat hubungan Jabatan Air Sabah">
        </div>
    </div>
</body>
</html>