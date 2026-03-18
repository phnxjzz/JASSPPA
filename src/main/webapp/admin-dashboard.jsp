<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Pentadbir - SPPA</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-yellow: #fff212;
            --surface: #ffffff;
            --surface-soft: #f7fbff;
            --line: #d9e7f1;
            --text: #183244;
            --muted: #637d8d;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(180deg, #f4fbff 0%, #f9fcfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 76%, var(--brand-yellow) 190%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 54px; height: 54px; background: white; border-radius: 16px; display: grid; place-items: center; color: var(--brand-navy); font-weight: 800; letter-spacing: 0.08em; }
        .brand h1 { margin: 0; font-size: 20px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; font-weight: 600; }
        .container { max-width: 1320px; margin: 28px auto; padding: 0 20px 32px; }
        .hero { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 20px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; max-width: 760px; }
        .metric-strip { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .metric-chip { background: var(--surface-soft); border: 1px solid var(--line); padding: 10px 14px; border-radius: 999px; font-weight: 700; }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); padding: 14px; background: #f7fbff; }
        .contact-image strong { display: block; margin-bottom: 8px; color: var(--brand-navy); }
        .contact-image p { margin: 4px 0; color: var(--muted); font-size: 14px; }
        .stats { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 16px; margin-bottom: 20px; }
        .stat-card { background: var(--surface); padding: 18px; border-radius: 18px; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        .stat-card .number { font-size: 30px; font-weight: 800; color: var(--brand-navy); }
        .layout { display: grid; grid-template-columns: 1.9fr 1fr; gap: 20px; }
        .toolbar { display: grid; grid-template-columns: 2fr 1fr auto auto auto; gap: 12px; align-items: end; margin-bottom: 16px; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); }
        .btn { padding: 11px 15px; border-radius: 12px; border: none; text-decoration: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .btn-accent { background: #fff7b0; color: #6a5a00; }
        .section-stack { display: grid; gap: 18px; }
        .table-card h3 { margin-top: 0; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 13px 12px; border-bottom: 1px solid #e4edf4; text-align: left; vertical-align: top; }
        th { background: #f8fcff; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        tr:hover { background: #f7fcff; }
        .status-pill { display: inline-block; padding: 5px 12px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .status-pending { background: #fff3cd; color: #9a6700; }
        .status-approved { background: #dcfce7; color: #166534; }
        .status-rejected { background: #fee2e2; color: #b91c1c; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .status-draft { background: #e2e8f0; color: #334155; }
        .subtle { color: var(--muted); font-size: 13px; }
        .empty { text-align: center; color: var(--muted); padding: 26px 0; }
        .section-title { margin-top: 0; margin-bottom: 14px; }
        @media (max-width: 1100px) { .hero, .layout, .stats, .toolbar { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; } .navbar a { margin-left: 0; margin-right: 16px; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <div class="brand-logo" aria-label="Logo Jabatan Air Sabah">JANS</div>
            <div>
                <h1>Dashboard Pentadbir</h1>
                <p>Pusat kawalan permohonan, produk, dan laporan SPPA</p>
            </div>
        </div>
        <div>
            <span>Selamat datang, <%= session.getAttribute("username") %></span>
            <a href="${pageContext.request.contextPath}/products">Senarai Produk</a>
            <a href="${pageContext.request.contextPath}/profile">Kemaskini Portal</a>
            <a href="${pageContext.request.contextPath}/logout">Log Keluar</a>
        </div>
    </div>

    <div class="container">
        <div class="hero">
            <div class="panel">
                <h2>Pemantauan pentadbiran dengan carian, tapisan, dan eksport</h2>
                <div class="metric-strip">
                    <div class="metric-chip">Rekod dipaparkan: <%= request.getAttribute("filtered_application_count") != null ? request.getAttribute("filtered_application_count") : "0" %></div>
                    <div class="metric-chip">Produk dalam MySQL: <%= request.getAttribute("total_products") != null ? request.getAttribute("total_products") : "0" %></div>
                    <div class="metric-chip">Pengguna aktif: <%= request.getAttribute("active_users") != null ? request.getAttribute("active_users") : "0" %></div>
                    <div class="metric-chip">Jumlah pengguna berdaftar: <%= request.getAttribute("registered_users") != null ? request.getAttribute("registered_users") : "0" %></div>
                    <div class="metric-chip">Pengguna baharu (30 hari): <%= request.getAttribute("new_registered_users") != null ? request.getAttribute("new_registered_users") : "0" %></div>
                </div>
            </div>
            <div class="panel">
                <div class="contact-image" aria-label="Maklumat hubungan Jabatan Air Sabah">
                    <strong>Hubungi JANS</strong>
                    <p>Telefon: 088-326888</p>
                    <p>Email: info@jwater.gov.my</p>
                    <p>Kota Kinabalu, Sabah</p>
                </div>
            </div>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Jumlah Permohonan</h3>
                <div class="number"><%= request.getAttribute("total_applications") != null ? request.getAttribute("total_applications") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Menunggu</h3>
                <div class="number"><%= request.getAttribute("pending_count") != null ? request.getAttribute("pending_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Diluluskan</h3>
                <div class="number"><%= request.getAttribute("approved_count") != null ? request.getAttribute("approved_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Ditolak</h3>
                <div class="number"><%= request.getAttribute("rejected_count") != null ? request.getAttribute("rejected_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Produk Berdaftar</h3>
                <div class="number"><%= request.getAttribute("total_products") != null ? request.getAttribute("total_products") : "0" %></div>
            </div>
        </div>

        <div class="layout">
            <div class="panel table-card">
                <h3 class="section-title">Permohonan Terkini</h3>
                <form method="get" action="${pageContext.request.contextPath}/dashboard" class="toolbar">
                    <div class="field">
                        <label for="q">Carian</label>
                        <input id="q" name="q" type="text" value="<%= request.getAttribute("search_query") %>" placeholder="Cari syarikat, produk, pemohon atau email">
                    </div>
                    <div class="field">
                        <label for="status">Status</label>
                        <select id="status" name="status">
                            <option value="">Semua status</option>
                            <option value="PENDING" <%= "PENDING".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>PENDING</option>
                            <option value="APPROVED" <%= "APPROVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>APPROVED</option>
                            <option value="REJECTED" <%= "REJECTED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>REJECTED</option>
                            <option value="SUSPENDED" <%= "SUSPENDED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>SUSPENDED</option>
                            <option value="DRAFT" <%= "DRAFT".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DRAFT</option>
                        </select>
                    </div>
                    <button class="btn btn-primary" type="submit">Tapis</button>
                    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/export?format=xlsx&q=<%= java.net.URLEncoder.encode(String.valueOf(request.getAttribute("search_query")), "UTF-8") %>&status=<%= java.net.URLEncoder.encode(String.valueOf(request.getAttribute("selected_status")), "UTF-8") %>">Export Excel</a>
                    <a class="btn btn-accent" href="${pageContext.request.contextPath}/admin/export?format=pdf&q=<%= java.net.URLEncoder.encode(String.valueOf(request.getAttribute("search_query")), "UTF-8") %>&status=<%= java.net.URLEncoder.encode(String.valueOf(request.getAttribute("selected_status")), "UTF-8") %>">Export PDF</a>
                </form>

                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nama Syarikat</th>
                            <th>Kategori Produk</th>
                            <th>Status</th>
                            <th>Tarikh Penghantaran</th>
                            <th>Tindakan</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            List<Map<String, Object>> applications = (List<Map<String, Object>>) request.getAttribute("pending_applications");
                            if (applications == null || applications.isEmpty()) {
                        %>
                        <tr>
                            <td colspan="6" class="empty">Tiada permohonan ditemui untuk penapis ini.</td>
                        </tr>
                        <% } else {
                            for (Map<String, Object> applicationRow : applications) {
                                Timestamp submittedAt = (Timestamp) applicationRow.get("submitted_at");
                                String status = String.valueOf(applicationRow.get("status")).toLowerCase();
                        %>
                        <tr>
                            <td><strong>#<%= applicationRow.get("id") %></strong></td>
                            <td>
                                <strong><%= applicationRow.get("company_name") %></strong><br>
                                <span class="subtle">Pemohon: <%= applicationRow.get("full_name") %><br>Email: <%= applicationRow.get("user_email") %></span>
                            </td>
                            <td>
                                <strong><%= applicationRow.get("product_category") %></strong><br>
                                <span class="subtle"><%= applicationRow.get("product_name") %></span>
                            </td>
                            <td><span class="status-pill status-<%= status %>"><%= applicationRow.get("status") %></span></td>
                            <td><%= submittedAt != null ? submittedAt.toString() : "Belum dihantar" %></td>
                            <td>
                                <a class="btn btn-primary" href="${pageContext.request.contextPath}/admin/application?id=<%= applicationRow.get("id") %>">Semak</a>
                            </td>
                        </tr>
                        <%      }
                           }
                        %>
                    </tbody>
                </table>
            </div>

            <div>
                <div class="section-stack">
                <div class="panel table-card" id="senarai-pengguna-berdaftar">
                    <h3 class="section-title">Senarai Pengguna Berdaftar Dalam Sistem</h3>
                    <div class="subtle" style="margin-bottom:12px;">Paparan ini menunjukkan semua akaun berperanan USER (pengguna berdaftar), bukan pemohon yang telah menghantar borang sahaja.</div>
                    <div style="margin-bottom:12px;display:flex;gap:10px;flex-wrap:wrap;">
                        <a class="btn btn-accent" href="${pageContext.request.contextPath}/admin/export?format=pdf&scope=users">Muat Turun PDF Pemohon Berdaftar</a>
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/export?format=xlsx&scope=users">Muat Turun Excel Pemohon Berdaftar</a>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nama Pengguna</th>
                                <th>Nama Penuh</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Tarikh Daftar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> users = (List<Map<String, Object>>) request.getAttribute("registered_users_list");
                                if (users == null || users.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="6" class="empty">Tiada pemohon berdaftar ditemui.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> userRow : users) {
                                    Timestamp createdAt = (Timestamp) userRow.get("created_at");
                            %>
                            <tr>
                                <td><%= userRow.get("id") %></td>
                                <td><strong><%= userRow.get("username") %></strong></td>
                                <td><%= userRow.get("full_name") %></td>
                                <td><%= userRow.get("email") %></td>
                                <td><span class="status-pill status-approved"><%= userRow.get("status") %></span></td>
                                <td><%= createdAt == null ? "-" : createdAt.toString() %></td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                </div>

                <div class="panel table-card" id="senarai-pengguna-baharu">
                    <h3 class="section-title">Senarai Pengguna Baharu (30 Hari)</h3>
                    <div style="margin-bottom:12px;display:flex;gap:10px;flex-wrap:wrap;">
                        <a class="btn btn-accent" href="${pageContext.request.contextPath}/admin/export?format=pdf&scope=users&recent=1">Muat Turun PDF Pemohon Baharu</a>
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/export?format=xlsx&scope=users&recent=1">Muat Turun Excel Pemohon Baharu</a>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nama Pengguna</th>
                                <th>Nama Penuh</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Tarikh Daftar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> newUsers = (List<Map<String, Object>>) request.getAttribute("new_registered_users_list");
                                if (newUsers == null || newUsers.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="6" class="empty">Tiada pemohon baharu ditemui.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> userRow : newUsers) {
                                    Timestamp createdAt = (Timestamp) userRow.get("created_at");
                            %>
                            <tr>
                                <td><%= userRow.get("id") %></td>
                                <td><strong><%= userRow.get("username") %></strong></td>
                                <td><%= userRow.get("full_name") %></td>
                                <td><%= userRow.get("email") %></td>
                                <td><span class="status-pill status-approved"><%= userRow.get("status") %></span></td>
                                <td><%= createdAt == null ? "-" : createdAt.toString() %></td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                </div>

                <div class="panel">
                    <h3 class="section-title">Pratonton Produk MySQL</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>No.</th>
                                <th>Produk</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> products = (List<Map<String, Object>>) request.getAttribute("product_catalog");
                                if (products == null || products.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="2" class="empty">Tiada produk ditemui.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> product : products) {
                            %>
                            <tr>
                                <td><%= product.get("no") %></td>
                                <td>
                                    <strong><%= product.get("product_materials") %></strong><br>
                                    <span class="subtle"><%= product.get("brand") == null ? "-" : product.get("brand") %> • <%= product.get("classification") %></span>
                                </td>
                            </tr>
                            <%      }
                                }
                            %>
                        </tbody>
                    </table>
                    <div style="margin-top:16px;">
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/products">Buka Senarai Produk Penuh</a>
                    </div>
                </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
