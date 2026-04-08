<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Pemohon - SPPA</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');
        :root {
            --brand-blue: #0d5c8f;
            --brand-navy: #08334d;
            --brand-gold: #e7bf56;
            --surface: #ffffff;
            --surface-soft: #f2f7fb;
            --line: #d4e1ec;
            --text: #1a3040;
            --muted: #5d7484;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Source Sans 3', 'Trebuchet MS', sans-serif; background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(180deg, var(--brand-navy) 0%, #0c4569 100%); border-bottom: 3px solid var(--brand-gold); color: white; padding: 14px 26px; display: flex; justify-content: space-between; align-items: center; gap: 20px; box-shadow: 0 12px 28px rgba(8, 51, 77, 0.2); }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 52px; height: 52px; object-fit: contain; }
        .brand h1 { margin: 0; font-size: 21px; letter-spacing: 0.02em; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; letter-spacing: 0.02em; }
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
        .container { max-width: 1280px; margin: 24px auto; padding: 0 20px 30px; }
        .section { background: var(--surface); border: 1px solid var(--line); padding: 20px; margin-bottom: 18px; border-radius: 14px; box-shadow: 0 8px 26px rgba(9, 53, 79, 0.07); }
        .profile-card { display: grid; grid-template-columns: auto 1fr; gap: 16px; align-items: center; }
        .avatar { width: 72px; height: 72px; border-radius: 16px; object-fit: cover; background: linear-gradient(135deg, var(--brand-blue), var(--brand-navy)); color: white; display: grid; place-items: center; font-size: 26px; font-weight: 700; box-shadow: 0 6px 20px rgba(13, 92, 143, 0.24); }
        .profile-meta strong { font-size: 20px; display: block; }
        .profile-meta span { color: var(--muted); }
        .stat-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 16px; margin-bottom: 20px; }
        .stat-card { background: linear-gradient(180deg, #ffffff 0%, #f8fbff 100%); border: 1px solid #d3e1ed; border-radius: 14px; padding: 18px; box-shadow: 0 8px 22px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: #557286; }
        .stat-card .number { font-size: 31px; font-weight: 800; color: var(--brand-navy); line-height: 1.1; }
        .actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 18px; }
        .btn { padding: 11px 16px; border-radius: 10px; border: 1px solid #fff; text-decoration: none; font-weight: 700; cursor: pointer; transition: transform 0.16s ease, box-shadow 0.16s ease; }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(9,53,79,0.16); }
        .btn-primary { background: linear-gradient(180deg, #0f6fa8 0%, #0d5c8f 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
        .notice { margin-bottom: 16px; padding: 13px 16px; border-radius: 12px; background: #ebf7ff; color: #16537a; border: 1px solid #cce5f5; }
        .layout { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 12px 12px; text-align: left; border-bottom: 1px solid #e2ebf2; vertical-align: top; }
        th { background: #f1f6fb; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: #547288; }
        tr:hover { background: #f5f9fc; }
        .status-badge { display: inline-block; padding: 5px 12px; border-radius: 999px; font-size: 12px; font-weight: 700; }
        .status-pending { background: #fff3cd; color: #9a6700; }
        .status-approved { background: #dcfce7; color: #166534; }
        .status-rejected { background: #fee2e2; color: #b91c1c; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .status-draft { background: #e2e8f0; color: #334155; }
        .mini-title { margin-top: 0; margin-bottom: 12px; font-size: 22px; color: #0f405d; }
        .supplier { color: var(--muted); font-size: 13px; margin-top: 4px; }
        .empty { padding: 28px 0; text-align: center; color: var(--muted); }
        @media (max-width: 980px) { .hero, .layout, .stat-grid { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; } .navbar a { margin-left: 0; margin-right: 16px; } }
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
            <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Dashboard Pemohon</h1>
                <p>Sistem Pendaftaran Produk Air - Jabatan Air Negeri Sabah</p>
            </div>
        </div>
        <div>
            <span>Selamat datang, <%= session.getAttribute("username") %></span>
            <a href="${pageContext.request.contextPath}/" aria-label="Laman utama" title="Laman utama"><img src="${pageContext.request.contextPath}/assets/images/icon-home.png" class="icon-inline" alt="Laman utama"></a>
            <a href="${pageContext.request.contextPath}/products">Senarai Produk</a>
            <div class="nav-dropdown">
                <button class="nav-dropdown-btn">Kemas Kini Profil &#9662;</button>
                <div class="nav-dropdown-menu">
                    <a href="${pageContext.request.contextPath}/profile">Tetapan</a>
                    <a href="${pageContext.request.contextPath}/profile">Kemas Kini Portal</a>
                </div>
            </div>
            <a href="${pageContext.request.contextPath}/logout" aria-label="Log Keluar" title="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" class="icon-inline" alt="Ikon log keluar"></a>
        </div>
    </div>

    <div class="container">
        <div class="section">
            <div class="profile-card">
                    <%
                        String avatarUrl = request.getAttribute("avatar_url") == null ? null : String.valueOf(request.getAttribute("avatar_url"));
                        String fullName = request.getAttribute("full_name") != null ? String.valueOf(request.getAttribute("full_name")) : String.valueOf(session.getAttribute("username"));
                        String initial = fullName.isEmpty() ? "P" : fullName.substring(0, 1).toUpperCase();
                    %>
                    <div style="position: relative; width: 72px; height: 72px;">
                        <% if (avatarUrl != null && !avatarUrl.isBlank()) { %>
                            <img class="avatar" src="${pageContext.request.contextPath}/avatars/view?v=<%= avatarUrl.hashCode() %>" alt="Avatar profil" onerror="this.style.display='none'; this.nextElementSibling.style.display='grid';">
                            <div class="avatar" style="display:none; position:absolute; inset:0; padding:0; overflow:hidden;"><img src="${pageContext.request.contextPath}/assets/images/User.png" alt="Avatar lalai" style="width:100%;height:100%;object-fit:cover;"></div>
                        <% } else { %>
                            <div class="avatar" style="position:absolute; inset:0; padding:0; overflow:hidden;"><img src="${pageContext.request.contextPath}/assets/images/User.png" alt="Avatar lalai" style="width:100%;height:100%;object-fit:cover;"></div>
                        <% } %>
                    </div>
                    <div class="profile-meta">
                        <strong><%= fullName %></strong>
                        <span><%= request.getAttribute("email") != null ? request.getAttribute("email") : "-" %></span>
                    </div>
                </div>
                <div class="actions">
                    <a class="btn btn-primary" href="${pageContext.request.contextPath}/profile">Kemas Kini Profil</a>
                    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/applications/new">Permohonan Baharu</a>
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
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nama Produk</th>
                                <th>Syarikat</th>
                                <th>Status</th>
                                <th>Maklum Balas Pentadbir</th>
                                <th>Tarikh Penghantaran</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                List<Map<String, Object>> applications = (List<Map<String, Object>>) request.getAttribute("applications");
                                if (applications == null || applications.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="6" class="empty">Tiada permohonan lagi.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> applicationRow : applications) {
                                    Timestamp submittedAt = (Timestamp) applicationRow.get("submitted_at");
                                    String status = String.valueOf(applicationRow.get("status"));
                                    String adminNotes = applicationRow.get("admin_notes") == null ? "" : String.valueOf(applicationRow.get("admin_notes"));
                            %>
                            <tr>
                                <td><strong>#<%= applicationRow.get("id") %></strong></td>
                                <td><%= applicationRow.get("product_name") %></td>
                                <td><%= applicationRow.get("company_name") %></td>
                                <td><span class="status-badge status-<%= status.toLowerCase() %>"><%= status %></span></td>
                                <td>
                                    <%
                                        String feedback = "-";
                                        if ("REJECTED".equals(status)) {
                                            feedback = !adminNotes.isBlank() ? adminNotes : "Permohonan ditolak tanpa sebab direkodkan.";
                                        } else if ("SUSPENDED".equals(status)) {
                                            feedback = !adminNotes.isBlank() ? adminNotes : "Permohonan digantung.";
                                        }
                                    %>
                                    <%= feedback %>
                                </td>
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
                    <h2 class="mini-title">Permohonan Diarkib</h2>
                    <p style="margin:6px 0;color:var(--muted);">Semak permohonan anda yang telah diarkibkan oleh pentadbir.</p>
                    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard?status=ARCHIVED" style="display:inline-block;margin-top:8px;">Lihat Permohonan Diarkib</a>
                </div>
                <div class="section">
                    <h2 class="mini-title"><img src="${pageContext.request.contextPath}/assets/images/icon-hubungi.png" alt="Hubungi" style="width:16px;height:16px;object-fit:contain;vertical-align:middle;margin-right:6px;">Hubungi JANS</h2>
                    <p style="margin:6px 0;color:var(--muted);">Telefon: +60-88-232364 (HQ)</p>
                    <p style="margin:6px 0;color:var(--muted);">Fax: +60-88-232396</p>
                    <p style="margin:6px 0;color:var(--muted);">Email: jans.hq@sabah.gov.my</p>
                </div>
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
