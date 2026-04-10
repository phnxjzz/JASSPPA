<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                    .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Senarai Pengguna &ndash; SPPA Admin</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;800&display=swap');
        :root {
            --brand-blue: #0d5c8f;
            --brand-navy: #08334d;
            --brand-gold: #e7bf56;
            --surface: #ffffff;
            --surface-soft: #f3f8fc;
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
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; }
        .navbar a { color: white; text-decoration: none; margin-left: 10px; font-weight: 700; display: inline-flex; align-items: center; gap: 6px; padding: 8px 11px; border-radius: 8px; transition: background 0.18s ease; }
        .navbar a:hover { background: rgba(255,255,255,0.14); }
        .icon-inline { width: 16px; height: 16px; object-fit: contain; vertical-align: middle; }
        .container { max-width: 1200px; margin: 28px auto; padding: 0 20px 40px; }
        .page-header { margin-bottom: 20px; }
        .page-header h2 { margin: 0 0 4px; font-size: 26px; color: var(--brand-navy); }
        .page-header p { margin: 0; color: var(--muted); }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 14px; box-shadow: 0 8px 26px rgba(9, 53, 79, 0.07); padding: 22px; }
        .btn { padding: 10px 16px; border-radius: 10px; border: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; font-family: inherit; font-size: 14px; transition: transform 0.15s ease, box-shadow 0.15s ease; text-decoration: none; }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 5px 14px rgba(9,53,79,0.15); }
        .btn-primary { background: linear-gradient(180deg, #0f6fa8 0%, #0d5c8f 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
        .btn-danger { background: linear-gradient(180deg, #e05252 0%, #c0392b 100%); color: white; padding: 7px 13px; font-size: 13px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 11px 12px; border-bottom: 1px solid #e2ebf2; text-align: left; vertical-align: middle; }
        th { background: #f1f6fb; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: #547288; font-weight: 700; }
        tr:hover td { background: #f5f9fc; }
        .role-pill { display: inline-block; padding: 4px 11px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .role-admin { background: #fef3c7; color: #92400e; }
        .role-user { background: #dbeafe; color: #1e40af; }
        .status-pill { display: inline-block; padding: 4px 11px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .status-active { background: #dcfce7; color: #166534; }
        .status-inactive { background: #e2e8f0; color: #334155; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .empty { text-align: center; color: var(--muted); padding: 30px 0; font-size: 15px; }
        .alert { border-radius: 10px; padding: 11px 16px; font-size: 14px; margin-bottom: 16px; font-weight: 600; }
        .alert-success { background: #e7f9ec; color: #166534; border: 1px solid #b8e7c6; }
        .alert-error { background: #fff1f2; color: #b91c1c; border: 1px solid #fecdd3; }
        .user-count { font-size: 13px; color: var(--muted); float: right; margin-top: 4px; }
        /* Modal */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(8,51,77,0.45); z-index: 1000; align-items: center; justify-content: center; }
        .modal-overlay.active { display: flex; }
        .modal { background: white; border-radius: 16px; padding: 30px 32px; max-width: 420px; width: 90%; box-shadow: 0 24px 56px rgba(8,51,77,0.22); }
        .modal h3 { margin: 0 0 10px; color: var(--brand-navy); }
        .modal p { color: var(--muted); margin: 0 0 22px; }
        .modal-actions { display: flex; gap: 10px; justify-content: flex-end; }
        .btn-warning { background: linear-gradient(180deg, #f59e0b 0%, #d97706 100%); color: white; padding: 7px 13px; font-size: 13px; }
        .btn-info { background: linear-gradient(180deg, #3b82f6 0%, #2563eb 100%); color: white; padding: 7px 13px; font-size: 13px; }
        .btn-success { background: linear-gradient(180deg, #22c55e 0%, #16a34a 100%); color: white; padding: 7px 13px; font-size: 13px; }
        .action-group { display: flex; gap: 6px; flex-wrap: wrap; }
        @media (max-width: 768px) { .navbar { flex-direction: column; align-items: flex-start; } .navbar a { margin-left: 0; margin-right: 10px; } }
        .temp-pw-box { background: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 8px; padding: 12px 16px; font-family: monospace; font-size: 18px; text-align: center; letter-spacing: 2px; color: #0f172a; margin: 12px 0; word-break: break-all; }
    </style>
</head>
<body>

<div class="navbar">
    <div class="brand">
        <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
        <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
        <div>
            <h1>Dashboard Pentadbir</h1>
            <p>Senarai Pengguna Berdaftar</p>
        </div>
    </div>
    <div>
        <span>Selamat datang, <%= session.getAttribute("username") %></span>
        <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/products">Senarai Produk</a>
        <a href="${pageContext.request.contextPath}/logout" aria-label="Log Keluar" title="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" class="icon-inline" alt="Ikon keluar" style="filter:brightness(0) invert(1);"></a>
    </div>
</div>

<div class="container">

    <div class="page-header">
        <h2><img src="${pageContext.request.contextPath}/assets/images/User.png" style="width:28px;height:28px;object-fit:contain;vertical-align:middle;margin-right:8px;"> Senarai Pengguna</h2>
        <p>Urus akaun pengguna yang berdaftar dalam sistem SPPA.</p>
    </div>

    <%
        String deleted = request.getParameter("deleted");
        String toggled = request.getParameter("toggled");
        String reset   = request.getParameter("reset");
        String tempPw  = request.getParameter("tempPw");
        String error   = request.getParameter("error");
    %>
    <% if ("1".equals(deleted)) { %>
        <div class="alert alert-success">&#10003; Akaun pengguna berjaya dipadam.</div>
    <% } else if ("1".equals(toggled)) { %>
        <div class="alert alert-success">&#10003; Status pengguna berjaya dikemas kini.</div>
    <% } else if ("cannot_delete_self".equals(error)) { %>
        <div class="alert alert-error">&#10007; Anda tidak boleh memadam akaun anda sendiri.</div>
    <% } else if ("cannot_suspend_self".equals(error)) { %>
        <div class="alert alert-error">&#10007; Anda tidak boleh menggantung akaun anda sendiri.</div>
    <% } else if ("last_admin".equals(error)) { %>
        <div class="alert alert-error">&#10007; Tidak boleh memadam pentadbir terakhir dalam sistem.</div>
    <% } else if ("last_active_admin".equals(error)) { %>
        <div class="alert alert-error">&#10007; Tidak boleh menggantung pentadbir aktif terakhir dalam sistem.</div>
    <% } else if ("db_error".equals(error)) { %>
        <div class="alert alert-error">&#10007; Ralat semasa memproses permintaan. Sila cuba lagi.</div>
    <% } %>
    <% if ("1".equals(reset) && tempPw != null && !tempPw.isEmpty()) { %>
        <div id="resetSuccessModal" class="modal-overlay active">
            <div class="modal">
                <h3>&#128273; Kata Laluan Sementara</h3>
                <p>Kata laluan pengguna telah berjaya ditetapkan semula. Sila sampaikan kata laluan sementara ini kepada pengguna berkenaan.</p>
                <div class="temp-pw-box"><%= esc(tempPw) %></div>
                <div class="modal-actions">
                    <button type="button" class="btn btn-primary" onclick="document.getElementById('resetSuccessModal').classList.remove('active')">OK, Faham</button>
                </div>
            </div>
        </div>
    <% } %>

    <div class="panel">
        <%
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> users = (List<Map<String, Object>>) request.getAttribute("users");
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        %>
        <span class="user-count">Jumlah: <%= users != null ? users.size() : 0 %> pengguna</span>

        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Nama Penuh</th>
                    <th>Nama Pengguna</th>
                    <th>E-mel</th>
                    <th>Peranan</th>
                    <th>Status</th>
                    <th>Tarikh Daftar</th>
                    <th>Tindakan</th>
                </tr>
            </thead>
            <tbody>
            <% if (users == null || users.isEmpty()) { %>
                <tr><td colspan="8" class="empty">Tiada pengguna dijumpai.</td></tr>
            <% } else {
                int idx = 1;
                for (Map<String, Object> u : users) {
                    String userId    = String.valueOf(u.get("id"));
                    String fullName  = esc(String.valueOf(u.get("full_name")));
                    String username  = esc(String.valueOf(u.get("username")));
                    String email     = esc(String.valueOf(u.get("email")));
                    String role      = String.valueOf(u.get("role"));
                    String status    = String.valueOf(u.get("status"));
                    Timestamp createdAt = (Timestamp) u.get("created_at");
                    String dateStr   = createdAt != null ? sdf.format(createdAt) : "-";
                    String roleClass = "ADMIN".equals(role) ? "role-admin" : "role-user";
                    String statClass = "ACTIVE".equals(status) ? "status-active"
                                     : "SUSPENDED".equals(status) ? "status-suspended" : "status-inactive";
                    String toggleLabel = "SUSPENDED".equals(status) ? "Aktifkan" : "Gantung";
                    String toggleBtnClass = "SUSPENDED".equals(status) ? "btn btn-success" : "btn btn-warning";
            %>
                <tr>
                    <td><%= idx++ %></td>
                    <td><strong><%= fullName %></strong></td>
                    <td><%= username %></td>
                    <td><%= email %></td>
                    <td><span class="role-pill <%= roleClass %>"><%= role %></span></td>
                    <td><span class="status-pill <%= statClass %>"><%= status %></span></td>
                    <td class="subtle"><%= dateStr %></td>
                    <td>
                        <div class="action-group">
                            <form method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
                                <input type="hidden" name="action" value="toggle_status">
                                <input type="hidden" name="userId" value="<%= userId %>">
                                <button type="submit" class="<%= toggleBtnClass %>"><%= toggleLabel %></button>
                            </form>
                            <button type="button" class="btn btn-info"
                                    onclick="confirmReset('<%= userId %>', '<%= username %>')">
                                Reset Kata Laluan
                            </button>
                            <button type="button" class="btn btn-danger"
                                    onclick="confirmDelete('<%= userId %>', '<%= username %>')">
                                Padam
                            </button>
                        </div>
                    </td>
                </tr>
            <% } } %>
            </tbody>
        </table>
    </div>
</div>

<!-- Delete Confirmation Modal -->
<div class="modal-overlay" id="deleteModal">
    <div class="modal">
        <h3>&#9888; Padam Pengguna?</h3>
        <p id="modalMsg">Adakah anda pasti mahu memadam akaun ini? Tindakan ini tidak boleh dibatalkan.</p>
        <div class="modal-actions">
            <button type="button" class="btn btn-secondary" onclick="closeModal('deleteModal')">Batal</button>
            <form id="deleteForm" method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="userId" id="deleteUserId" value="">
                <button type="submit" class="btn btn-danger">Ya, Padam</button>
            </form>
        </div>
    </div>
</div>

<!-- Reset Password Confirmation Modal -->
<div class="modal-overlay" id="resetModal">
    <div class="modal">
        <h3>&#128273; Reset Kata Laluan?</h3>
        <p id="resetModalMsg">Kata laluan sedia ada pengguna ini akan digantikan dengan kata laluan sementara yang dijana secara rawak.</p>
        <div class="modal-actions">
            <button type="button" class="btn btn-secondary" onclick="closeModal('resetModal')">Batal</button>
            <form id="resetForm" method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
                <input type="hidden" name="action" value="reset_password">
                <input type="hidden" name="userId" id="resetUserId" value="">
                <button type="submit" class="btn btn-info">Ya, Reset</button>
            </form>
        </div>
    </div>
</div>

<script>
    function confirmDelete(userId, username) {
        document.getElementById('deleteUserId').value = userId;
        document.getElementById('modalMsg').textContent =
            'Adakah anda pasti mahu memadam akaun "' + username + '"? Tindakan ini tidak boleh dibatalkan.';
        document.getElementById('deleteModal').classList.add('active');
    }
    function confirmReset(userId, username) {
        document.getElementById('resetUserId').value = userId;
        document.getElementById('resetModalMsg').textContent =
            'Kata laluan sedia ada "' + username + '" akan digantikan dengan kata laluan sementara yang dijana secara rawak.';
        document.getElementById('resetModal').classList.add('active');
    }
    function closeModal(id) {
        document.getElementById(id).classList.remove('active');
    }
    ['deleteModal', 'resetModal'].forEach(function(id) {
        document.getElementById(id).addEventListener('click', function(e) {
            if (e.target === this) closeModal(id);
        });
    });
</script>

</body>
</html>
