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
    <title>Kemas Kini Profil - SPPA</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');
        :root {
            --brand-blue: #0d5c8f;
            --brand-navy: #08334d;
            --brand-gold: #e7bf56;
            --surface: #ffffff;
            --muted: #5d7484;
            --line: #d4e1ec;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif; background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%); color: #1a3040; }
        .navbar { background: linear-gradient(180deg, var(--brand-navy) 0%, #0c4569 100%); border-bottom: 3px solid var(--brand-gold); color: white; padding: 14px 26px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 12px 28px rgba(8, 51, 77, 0.2); }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 50px; height: 50px; border-radius: 14px; display: grid; place-items: center; color: var(--brand-navy); font-weight: 800; letter-spacing: 0.08em; }
        .brand h1 { margin: 0; font-size: 21px; letter-spacing: 0.02em; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; }
        .navbar a { color: white; text-decoration: none; margin-left: 10px; font-weight: 700; padding: 8px 11px; border-radius: 8px; transition: background 0.18s ease; }
        .navbar a:hover { background: rgba(255,255,255,0.14); }
        .icon-inline { width: 16px; height: 16px; object-fit: contain; vertical-align: middle; }
            .nav-dropdown { position: relative; display: inline-flex; align-items: center; margin-left: 10px; }
            .nav-dropdown-btn { background: transparent; border: none !important; box-shadow: none !important; color: white; font-weight: 700; font-family: inherit; font-size: 1em; cursor: pointer; padding: 8px 11px; border-radius: 8px; display: flex; align-items: center; gap: 4px; }
            .nav-dropdown-btn:hover { background: rgba(255,255,255,0.14); }
            .nav-dropdown-menu { display: none; position: absolute; top: 100%; right: 0; background: white; border-radius: 10px; box-shadow: 0 12px 28px rgba(6,52,79,0.18); min-width: 190px; z-index: 100; overflow: hidden; margin-top: 4px; }
            .nav-dropdown-menu a { display: block; padding: 10px 16px; color: #06344f !important; text-decoration: none; font-weight: 700; margin-left: 0 !important; border-bottom: 1px solid #e4edf4; }
            .nav-dropdown-menu a:last-child { border-bottom: none; }
            .nav-dropdown-menu a:hover { background: #eef5fb; }
            .nav-dropdown:hover .nav-dropdown-menu,
            .nav-dropdown:focus-within .nav-dropdown-menu { display: block; }
        .container { max-width: 1080px; margin: 28px auto; padding: 0 20px 32px; display: grid; grid-template-columns: 2fr 1fr; gap: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 14px; padding: 22px; box-shadow: 0 8px 26px rgba(9, 53, 79, 0.07); }
        .panel h2 { margin-top: 0; }
        .field { margin-bottom: 16px; }
        .field label { display: block; margin-bottom: 6px; color: var(--muted); font-size: 13px; font-weight: 700; }
        .field input { width: 100%; padding: 12px; border-radius: 12px; border: 1px solid var(--line); }
        .hint { color: var(--muted); font-size: 13px; margin-top: 6px; }
        .btn-row { display: flex; gap: 12px; margin-top: 10px; }
        .btn { padding: 11px 18px; border-radius: 10px; border: 1px solid #fff; font-weight: 700; cursor: pointer; text-decoration: none; transition: transform 0.16s ease, box-shadow 0.16s ease; }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(9,53,79,0.16); }
        .btn-primary { background: linear-gradient(180deg, #0f6fa8 0%, #0d5c8f 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
        .message { padding: 12px 14px; border-radius: 12px; margin-bottom: 16px; }
        .error { background: #fdecec; color: #b42318; }
        .success { background: #ebfff0; color: #0f7a3d; }
        .summary-item { padding: 14px; border-radius: 12px; background: #f3f8fc; border: 1px solid #dde8f2; margin-bottom: 12px; }
        .summary-item strong { display: block; margin-bottom: 4px; }
        .avatar-card { display: grid; grid-template-columns: 96px 1fr; gap: 14px; align-items: center; padding: 14px; border: 1px dashed var(--line); border-radius: 16px; margin-bottom: 18px; background: #f9fcff; }
        .avatar-preview, .avatar-placeholder { width: 96px; height: 96px; border-radius: 24px; object-fit: cover; border: 1px solid var(--line); background: linear-gradient(135deg, #d7f0ff 0%, #fff7b2 100%); display: flex; align-items: center; justify-content: center; font-size: 34px; font-weight: 800; color: var(--brand-navy); }
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
                <h1>Kemas Kini Profil Pemohon</h1>
                <p>Sistem Pendaftaran Produk Air</p>
            </div>
        </div>
        <div>
            <a href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/assets/images/icon-home.png" class="icon-inline" alt="Laman utama"></a>
            <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
            <div class="nav-dropdown">
                <button class="nav-dropdown-btn">Kemas Kini Profil &#9662;</button>
                <div class="nav-dropdown-menu">
                    <a href="${pageContext.request.contextPath}/profile">Tetapan</a>
                </div>
            </div>
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
                <div class="message success">Profil berjaya dikemas kini.</div>
            <% } %>

            <div class="avatar-card">
                <%
                    String fallbackInitial = request.getAttribute("full_name") != null && !String.valueOf(request.getAttribute("full_name")).isBlank()
                            ? String.valueOf(request.getAttribute("full_name")).substring(0, 1).toUpperCase()
                            : "P";
                %>
                <div style="position: relative; width: 96px; height: 96px;">
                    <% if (avatarValue != null && !avatarValue.isBlank()) { %>
                        <img class="avatar-preview" src="${pageContext.request.contextPath}/avatars/view?v=<%= avatarToken %>" alt="Gambar profil semasa" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                        <div class="avatar-placeholder" style="display:none; position:absolute; inset:0; padding:0; overflow:hidden;"><img src="${pageContext.request.contextPath}/assets/images/User.png" alt="Avatar lalai" style="width:100%;height:100%;object-fit:cover;"></div>
                    <% } else { %>
                        <div class="avatar-placeholder" style="position:absolute; inset:0; padding:0; overflow:hidden;"><img src="${pageContext.request.contextPath}/assets/images/User.png" alt="Avatar lalai" style="width:100%;height:100%;object-fit:cover;"></div>
                    <% } %>
                </div>
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
            <div class="summary-item">
                <strong><img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Hubungi" style="width:16px;height:16px;object-fit:contain;vertical-align:middle;margin-right:6px;">Hubungi JANS</strong>
                <span>Telefon: +60-88-232364 (HQ)</span><br>
                <span>Fax: +60-88-232396</span><br>
                <span>Email: jans.hq@sabah.gov.my</span>
            </div>
        </div>
    </div>
    <script>
        (function () {
            var idleLimitMs = 10 * 60 * 1000;
            var logoutUrl = '${pageContext.request.contextPath}/logout?timeout=1';
            var timerId;

            function triggerAutoLogout() {
                window.location.href = logoutUrl;
            }

            function resetTimer() {
                window.clearTimeout(timerId);
                timerId = window.setTimeout(triggerAutoLogout, idleLimitMs);
            }

            ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart', 'click'].forEach(function (eventName) {
                document.addEventListener(eventName, resetTimer, { passive: true });
            });

            resetTimer();
        })();
    </script>
</body>
</html>
