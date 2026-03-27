<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Timestamp" %>
<%
    String avatarValue = request.getAttribute("avatar_url") == null ? null : String.valueOf(request.getAttribute("avatar_url"));
    String avatarToken = avatarValue == null ? "0" : String.valueOf(avatarValue.hashCode());
%>
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
        }</style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <div class="brand-logo" aria-label="Logo Jabatan Air Sabah">JANS</div>
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

            <% if (request.getAttribute("error") != null) { %>
                <div class="message error"><%= request.getAttribute("error") %></div>
            <% } %>
            <% if (request.getParameter("updated") != null) { %>
                <div class="message success">Profil berjaya dikemaskini.</div>
            <% } %>

            <div class="avatar-card">
                <% if (avatarValue != null && !avatarValue.isBlank()) { %>
                    <img class="avatar-preview" src="${pageContext.request.contextPath}/avatars/view?v=<%= avatarToken %>" alt="Gambar profil semasa">
                <% } else { %>
                    <div class="avatar-placeholder"><%= request.getAttribute("full_name") != null && !String.valueOf(request.getAttribute("full_name")).isBlank() ? String.valueOf(request.getAttribute("full_name")).substring(0, 1).toUpperCase() : "P" %></div>
                <% } %>
            </div>

            <form method="post" action="${pageContext.request.contextPath}/profile" enctype="multipart/form-data">
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
            <div class="contact-image" aria-label="Maklumat hubungan Jabatan Air Sabah">
                <strong>Hubungi JANS</strong>
                <p>Telefon: 088-326888</p>
                <p>Email: info@jwater.gov.my</p>
                <p>Kota Kinabalu, Sabah</p>
            </div>
        </div>
    </div>
</body>
</html>




