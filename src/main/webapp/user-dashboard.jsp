<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Pemohon - SPPA</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-yellow: #fff212;
            --surface: #ffffff;
            --surface-soft: #f5fbff;
            --line: #d8e8f1;
            --text: #173040;
            --muted: #678090;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: radial-gradient(circle at top left, #fffcd8 0%, #ebf8ff 34%, #f7fbfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 75%, var(--brand-yellow) 190%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand img { width: 54px; background: white; border-radius: 16px; padding: 6px; }
        .brand h1 { margin: 0; font-size: 20px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; font-weight: 600; }
        .container { max-width: 1280px; margin: 28px auto; padding: 0 20px 30px; }
        .hero { display: grid; grid-template-columns: 1.7fr 1fr; gap: 20px; margin-bottom: 20px; }
        .section { background: var(--surface); border: 1px solid var(--line); padding: 22px; margin-bottom: 20px; border-radius: 20px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); }
        .hero-card { position: relative; overflow: hidden; }
        .hero-card::after { content: ""; position: absolute; inset: auto -60px -60px auto; width: 180px; height: 180px; border-radius: 50%; background: rgba(255, 242, 18, 0.32); }
        .hero-card h2 { margin-top: 0; margin-bottom: 8px; font-size: 30px; }
        .hero-card p { color: var(--muted); line-height: 1.7; max-width: 720px; }
        .badge-row { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .badge { display: inline-flex; align-items: center; gap: 8px; background: var(--surface-soft); border: 1px solid var(--line); border-radius: 999px; padding: 10px 14px; font-weight: 700; }
        .profile-card { display: grid; grid-template-columns: auto 1fr; gap: 16px; align-items: center; }
        .avatar { width: 72px; height: 72px; border-radius: 22px; object-fit: cover; background: linear-gradient(135deg, var(--brand-blue), var(--brand-navy)); color: white; display: grid; place-items: center; font-size: 26px; font-weight: 700; }
        .profile-meta strong { font-size: 18px; display: block; }
        .profile-meta span { color: var(--muted); }
        .stat-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 16px; margin-bottom: 20px; }
        .stat-card { background: var(--surface); border: 1px solid var(--line); border-radius: 18px; padding: 18px; box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        .stat-card .number { font-size: 30px; font-weight: 800; color: var(--brand-navy); }
        .actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 18px; }
        .btn { padding: 11px 16px; border-radius: 12px; border: none; text-decoration: none; font-weight: 700; cursor: pointer; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .notice { margin-bottom: 16px; padding: 13px 16px; border-radius: 12px; background: #ebf7ff; color: #16537a; border: 1px solid #cce5f5; }
        .layout { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 13px 12px; text-align: left; border-bottom: 1px solid #e7f0f5; vertical-align: top; }
        th { background: #f8fcff; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        tr:hover { background: #f8fcff; }
        .status-badge { display: inline-block; padding: 5px 12px; border-radius: 999px; font-size: 12px; font-weight: 700; }
        .status-pending { background: #fff3cd; color: #9a6700; }
        .status-approved { background: #dcfce7; color: #166534; }
        .status-rejected { background: #fee2e2; color: #b91c1c; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .status-draft { background: #e2e8f0; color: #334155; }
        .mini-title { margin-top: 0; margin-bottom: 14px; font-size: 20px; }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); margin-top: 12px; }
        .supplier { color: var(--muted); font-size: 13px; margin-top: 4px; }
        .empty { padding: 28px 0; text-align: center; color: var(--muted); }
        @media (max-width: 980px) { .hero, .layout, .stat-grid { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; } .navbar a { margin-left: 0; margin-right: 16px; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Dashboard Pemohon</h1>
                <p>Sistem Pendaftaran Produk Air • Jabatan Air Negeri Sabah</p>
            </div>
        </div>
        <div>
            <span>Selamat datang, <%= session.getAttribute("username") %></span>
            <a href="${pageContext.request.contextPath}/products">Senarai Produk</a>
            <a href="${pageContext.request.contextPath}/logout">Log Keluar</a>
        </div>
    </div>

    <div class="container">
        <div class="hero">
            <div class="section hero-card">
                <h2>Portal pemohon yang bersambung terus ke rekod MySQL</h2>
                <p>Paparan ini membolehkan pemohon mengurus profil sebenar, menghantar permohonan PPP1 secara online, dan menyemak produk berdaftar yang sudah ada dalam pangkalan data.</p>
                <div class="badge-row">
                    <div class="badge">Akaun: <%= request.getAttribute("account_status") != null ? request.getAttribute("account_status") : "ACTIVE" %></div>
                    <div class="badge">Produk tersedia: <%= request.getAttribute("product_count") != null ? request.getAttribute("product_count") : "0" %></div>
                </div>
            </div>
            <div class="section">
                <div class="profile-card">
                    <%
                        String avatarUrl = request.getAttribute("avatar_url") == null ? null : String.valueOf(request.getAttribute("avatar_url"));
                        String fullName = request.getAttribute("full_name") != null ? String.valueOf(request.getAttribute("full_name")) : String.valueOf(session.getAttribute("username"));
                        String initial = fullName.isEmpty() ? "P" : fullName.substring(0, 1).toUpperCase();
                    %>
                    <% if (avatarUrl != null && !avatarUrl.isBlank()) { %>
                        <img class="avatar" src="<%= avatarUrl %>" alt="Avatar profil">
                    <% } else { %>
                        <div class="avatar"><%= initial %></div>
                    <% } %>
                    <div class="profile-meta">
                        <strong><%= fullName %></strong>
                        <span><%= request.getAttribute("email") != null ? request.getAttribute("email") : "-" %></span>
                    </div>
                </div>
                <div class="actions">
                    <a class="btn btn-primary" href="${pageContext.request.contextPath}/profile">Kemaskini Profil</a>
                    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/applications/new">Permohonan Baharu</a>
                </div>
            </div>
        </div>

        <div class="stat-grid">
            <div class="stat-card">
                <h3>Jumlah Permohonan</h3>
                <div class="number"><%= request.getAttribute("application_count") != null ? request.getAttribute("application_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Status Akaun</h3>
                <div class="number" style="font-size:22px;"><%= request.getAttribute("account_status") != null ? request.getAttribute("account_status") : "ACTIVE" %></div>
            </div>
            <div class="stat-card">
                <h3>Produk Berdaftar</h3>
                <div class="number"><%= request.getAttribute("product_count") != null ? request.getAttribute("product_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Rujukan Profil</h3>
                <div class="number" style="font-size:22px;"><%= request.getAttribute("username") != null ? request.getAttribute("username") : session.getAttribute("username") %></div>
            </div>
        </div>

        <div class="layout">
            <div>
                <div class="section">
                    <h2 class="mini-title">Permohonan Saya</h2>
                    <div class="notice">Permohonan online ini menggantikan pengisian manual PPP1. Dokumen sokongan masih perlu dimuat naik dalam format PDF mengikut PPP2 dan garis panduan JANS.</div>
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nama Produk</th>
                                <th>Syarikat</th>
                                <th>Status</th>
                                <th>Tarikh Penghantaran</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> applications = (List<Map<String, Object>>) request.getAttribute("applications");
                                if (applications == null || applications.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="5" class="empty">Tiada permohonan lagi.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> applicationRow : applications) {
                                    Timestamp submittedAt = (Timestamp) applicationRow.get("submitted_at");
                            %>
                            <tr>
                                <td><strong>#<%= applicationRow.get("id") %></strong></td>
                                <td><%= applicationRow.get("product_name") %></td>
                                <td><%= applicationRow.get("company_name") %></td>
                                <td><span class="status-badge status-<%= String.valueOf(applicationRow.get("status")).toLowerCase() %>"><%= applicationRow.get("status") %></span></td>
                                <td><%= submittedAt != null ? submittedAt.toString() : "Belum dihantar" %></td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>

            <div>
                <div class="section">
                    <h2 class="mini-title">Produk Air Berdaftar</h2>
                    <p style="color:#678090;margin-top:0;">Paparan ringkas daripada jadual <strong>water_products</strong> dalam MySQL.</p>
                    <table>
                        <thead>
                            <tr>
                                <th>No.</th>
                                <th>Produk</th>
                                <th>Jenama</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> products = (List<Map<String, Object>>) request.getAttribute("product_catalog");
                                if (products == null || products.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="3" class="empty">Tiada data produk.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> product : products) {
                            %>
                            <tr>
                                <td><%= product.get("no") %></td>
                                <td>
                                    <strong><%= product.get("product_materials") %></strong>
                                    <div class="supplier"><%= product.get("product_type") %></div>
                                </td>
                                <td><%= product.get("brand") == null ? "-" : product.get("brand") %></td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                    <div class="actions">
                        <a class="btn btn-primary" href="${pageContext.request.contextPath}/products">Lihat Semua Produk</a>
                    </div>
                </div>

                <div class="section">
                    <h2 class="mini-title">Hubungi Jabatan Air Sabah</h2>
                    <p style="color:#678090;">Maklumat hubungan rasmi dimasukkan terus pada portal untuk rujukan pemohon.</p>
                    <img class="contact-image" src="${pageContext.request.contextPath}/assets/images/contact-jans.png" alt="Maklumat hubungan Jabatan Air Sabah">
                </div>
            </div>
        </div>
    </div>
</body>
</html>
