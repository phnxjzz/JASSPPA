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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Senarai Pengguna &ndash; SPPPA Admin</title>
    <style>
:root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-gold: #F2F72E;
            --surface: #ffffff;
            --surface-soft: #f3f8fc;
            --line: #d4e1ec;
            --text: #1a3040;
            --muted: #5d7484;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: inherit; background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(135deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-gold) 100%); border-bottom: 3px solid var(--brand-gold); color: white; padding: 14px 26px; display: flex; justify-content: space-between; align-items: center; gap: 20px; box-shadow: 0 12px 28px rgba(8, 51, 77, 0.2); }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 52px; height: 52px; object-fit: contain; }
        .brand h1 { margin: 0; font-size: 21px; letter-spacing: 0.02em; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; }
        .navbar a { color: white; text-decoration: none; margin-left: 10px; font-weight: 700; display: inline-flex; align-items: center; gap: 6px; padding: 8px 11px; border-radius: 8px; transition: background 0.18s ease; }
        .navbar a:hover { background: rgba(255,255,255,0.14); }
        .icon-inline { width: 16px; height: 16px; object-fit: contain; vertical-align: middle; }
        .icon-link { width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.38); transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 4px; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: rgba(255,255,255,0.26); }
        .container { max-width: 1200px; margin: 28px auto; padding: 0 20px 40px; }
        .page-header { margin-bottom: 20px; }
        .page-header h2 { margin: 0 0 4px; font-size: 26px; color: var(--brand-navy); }
        .page-header p { margin: 0; color: var(--muted); }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 14px; box-shadow: 0 8px 26px rgba(9, 53, 79, 0.07); padding: 22px; }
        .users-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            margin-bottom: 12px;
            flex-wrap: wrap;
        }
        .search-form {
            display: flex;
            align-items: center;
            gap: 8px;
            background: #f6fbff;
            border: 1px solid #d4e1ec;
            border-radius: 12px;
            padding: 6px;
        }
        .search-form-icon {
            width: 20px;
            height: 20px;
            object-fit: contain;
            opacity: 0.9;
            margin-left: 4px;
        }
        .search-form input[type="text"] {
            min-width: 280px;
            border: 1px solid #d0deea;
            border-radius: 8px;
            padding: 9px 10px;
            font-family: inherit;
            font-size: 14px;
            color: var(--text);
            background: #ffffff;
        }
        .search-form input[type="text"]:focus {
            outline: none;
            border-color: #8fb6d2;
            box-shadow: 0 0 0 2px rgba(15, 107, 174, 0.12);
        }
        .search-form .btn {
            padding: 9px 12px;
            border-radius: 8px;
            box-shadow: none;
        }
        .btn { padding: 10px 16px; border-radius: 10px; border: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; font-family: inherit; font-size: 14px; transition: transform 0.15s ease, box-shadow 0.15s ease; text-decoration: none; }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 5px 14px rgba(9,53,79,0.15); }
        .btn-primary { background: linear-gradient(180deg, var(--brand-navy) 0%, var(--brand-blue) 55%, var(--brand-green) 100%); color: white; }
        .btn-secondary { background: #e2edf5; color: var(--brand-navy); }
        .btn-danger { background: linear-gradient(180deg, #e05252 0%, #c0392b 100%); color: white; padding: 7px 13px; font-size: 13px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 11px 12px; border-bottom: 1px solid #e2ebf2; text-align: left; vertical-align: middle; }
        th { background: #f1f6fb; font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: #547288; font-weight: 700; }
        tr:hover td { background: #f5f9fc; }
        .role-pill { display: inline-block; padding: 4px 11px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .role-admin { background: #fef3c7; color: #92400e; }
        .role-user { background: #dbeafe; color: #1e40af; }
        .role-staff { background: #dcfce7; color: #166534; }
        .status-pill { display: inline-block; padding: 4px 11px; border-radius: 999px; font-weight: 700; font-size: 12px; }
        .status-active { background: #dcfce7; color: #166534; }
        .status-inactive { background: #e2e8f0; color: #334155; }
        .status-suspended { background: #ffe4d6; color: #9a3412; }
        .empty { text-align: center; color: var(--muted); padding: 30px 0; font-size: 15px; }
        .alert { border-radius: 10px; padding: 11px 16px; font-size: 14px; margin-bottom: 16px; font-weight: 600; }
        .alert-success { background: #e7f9ec; color: #166534; border: 1px solid #b8e7c6; }
        .alert-error { background: #fff1f2; color: #b91c1c; border: 1px solid #fecdd3; }
        .alert-with-gif { display: flex; align-items: center; gap: 10px; }
        .success-popup {
            position: fixed;
            top: 50%;
            left: 50%;
            z-index: 1300;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 16px;
            min-width: 280px;
            max-width: min(94vw, 420px);
            padding: 28px 24px;
            border-radius: 16px;
            border: 1px solid #b8e7c6;
            background: #ffffff;
            color: #166534;
            font-size: 16px;
            line-height: 1.6;
            box-shadow: 0 16px 32px rgba(10, 64, 38, 0.2);
            transform: translate(-50%, -58%) scale(0.97);
            opacity: 0;
            pointer-events: none;
            transition: transform 0.22s ease, opacity 0.22s ease;
        }
        .success-popup.show {
            transform: translate(-50%, -50%) scale(1);
            opacity: 1;
            pointer-events: auto;
        }
        .success-popup-content { display: flex; flex-direction: column; gap: 8px; align-items: center; }
        .success-title { font-size: 22px; line-height: 1.1; font-weight: 800; color: #0f5132; letter-spacing: 0.06em; text-transform: uppercase; text-align: center; }
        .success-text { display: none; }
        .success-ok { align-self: center; margin-top: 4px; border: 1px solid #0f5132 !important; background: #166534; color: #fff; border-radius: 10px; padding: 10px 24px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .success-gif {
            width: 84px;
            height: 84px;
            padding: 0;
            object-fit: contain;
            flex-shrink: 0;
            background: transparent;
            border-radius: 0;
            border: none;
            mix-blend-mode: normal;
            filter: drop-shadow(0 3px 8px rgba(22, 101, 52, 0.22)) saturate(1.05);
            transform-origin: center;
            animation: successGifPop 420ms ease-out 1, successGifPulse 1.9s ease-in-out infinite 520ms;
        }
        @keyframes successGifPop {
            0% { transform: scale(0.72) translateY(3px); opacity: 0.65; }
            70% { transform: scale(1.14) translateY(-1px); opacity: 1; }
            100% { transform: scale(1); opacity: 1; }
        }
        @keyframes successGifPulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.06); }
        }
        .user-count { font-size: 13px; color: var(--muted); float: right; margin-top: 4px; }
        .table-wrap {
            width: 100%;
            overflow-x: auto;
            border: 1px solid #d9e5ef;
            border-radius: 12px;
            background: #fff;
        }
        .table-wrap table {
            min-width: 1050px;
            margin: 0;
            border-collapse: collapse;
        }
        .table-wrap th,
        .table-wrap td {
            white-space: nowrap;
        }
        .table-wrap td:nth-child(3),
        .table-wrap td:nth-child(4),
        .table-wrap td:nth-child(5) {
            white-space: normal;
            word-break: break-word;
            overflow-wrap: anywhere;
        }
        .table-wrap td:nth-child(10) {
            white-space: nowrap;
        }
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
        .table-actions { white-space: nowrap; }
        .action-menu { position: relative; display: inline-block; }
        .action-trigger {
            min-width: 98px;
            justify-content: space-between;
            background: #eef4f9;
            color: #1e3a4f;
            border: 1px solid #c8d8e5;
            box-shadow: none;
        }
        .action-trigger:hover { background: #e1edf6; }
        .action-trigger::after { content: "▾"; font-size: 12px; opacity: 0.85; }
        .action-dropdown {
            display: none;
            position: absolute;
            right: 0;
            top: calc(100% + 6px);
            z-index: 25;
            min-width: 210px;
            background: #fff;
            border: 1px solid #d7e3ee;
            border-radius: 12px;
            box-shadow: 0 14px 26px rgba(9, 53, 79, 0.16);
            padding: 6px;
        }
        .action-menu.open .action-dropdown { display: block; }
        .action-item {
            display: block;
            width: 100%;
            border: none;
            background: transparent;
            text-align: left;
            color: #20435b;
            border-radius: 8px;
            padding: 9px 10px;
            font-size: 13px;
            font-weight: 700;
            font-family: inherit;
            cursor: pointer;
        }
        .action-item:hover { background: #eff6fb; }
        .action-item-danger { color: #b91c1c; }
        .action-item-danger:hover { background: #fff1f2; }
        @media (max-width: 768px) { .navbar { flex-direction: column; align-items: flex-start; } .navbar a { margin-left: 0; margin-right: 10px; } }
        @media (max-width: 768px) {
            .search-form { width: 100%; }
            .search-form input[type="text"] { min-width: 0; width: 100%; }
            .user-count { float: none; width: 100%; text-align: right; }
            .panel { padding: 16px; }
        }
        .temp-pw-box { background: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 8px; padding: 12px 16px; font-family: inherit; font-size: 18px; text-align: center; letter-spacing: 2px; color: #0f172a; margin: 12px 0; word-break: break-all; }
        .audit-panel { margin-top: 18px; }
        .audit-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 9px; }
        .audit-item { border: 1px solid #d8e5ef; border-radius: 10px; background: #f8fbff; padding: 10px 12px; }
        .audit-item strong { display: block; color: #0f3f61; font-size: 13px; margin-bottom: 3px; }
        .audit-item p { margin: 0; color: #486376; font-size: 12px; }
        .audit-meta { margin-top: 6px; display: flex; justify-content: space-between; gap: 8px; color: #708798; font-size: 11px; }
        .audit-panel-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 8px; }
        .audit-toggle-btn { width: 34px; height: 34px; border: 1px solid #c9dcea; border-radius: 8px; background: #f7fbff; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; padding: 0; }
        .audit-toggle-btn img { width: 18px; height: 18px; object-fit: contain; }
        .audit-content.is-hidden { display: none; }
        .kpp-panel { margin-top: 18px; }
        .kpp-form { display: grid; grid-template-columns: 1.1fr 1fr 1fr auto; gap: 10px; margin-bottom: 12px; align-items: end; }
        .kpp-field label { display: block; font-size: 12px; font-weight: 700; color: #4b6477; margin-bottom: 6px; }
        .kpp-field input { width: 100%; border: 1px solid #cbd8e4; border-radius: 10px; padding: 10px 11px; font-family: inherit; font-size: 13px; }
        .kpp-table-wrap { border: 1px solid #d9e5ef; border-radius: 12px; overflow: auto; }
        .kpp-table th, .kpp-table td { padding: 10px 11px; border-bottom: 1px solid #e6edf4; }
        .kpp-table th { background: #f4f8fc; font-size: 12px; color: #5a7488; text-transform: uppercase; letter-spacing: 0.04em; }
        .kpp-empty { text-align: center; color: #6e8394; padding: 16px 10px; }
        @media (max-width: 980px) {
            .kpp-form { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="brand">
        <img src="${pageContext.request.contextPath}/assets/images/sabah-logo.png" class="brand-logo" alt="Logo Sabah">
        <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
        <div>
            <h1 data-i18n="admin.title">Dashboard Pentadbir</h1>
            <p data-i18n="adm_users.title">Senarai Pengguna Berdaftar</p>
        </div>
    </div>
    <div>
        <span>Selamat datang, <%= session.getAttribute("username") %></span>
        <a class="icon-link" href="${pageContext.request.contextPath}/dashboard" title="Dashboard" aria-label="Dashboard"><img src="${pageContext.request.contextPath}/icon/dashboard.png" alt="Dashboard"></a>
        <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/assets/images/home.png" alt="Home"></a>
        <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
    </div>
</div>

<div class="container">

    <div class="page-header">
        <h2><img src="${pageContext.request.contextPath}/assets/images/User.png" style="width:28px;height:28px;object-fit:contain;vertical-align:middle;margin-right:8px;"> Senarai Pengguna</h2>
        <p>Urus akaun pengguna yang berdaftar dalam sistem SPPPA.</p>
    </div>

    <%
        String deleted = request.getParameter("deleted");
        String toggled = request.getParameter("toggled");
        String reset   = request.getParameter("reset");
        String roleUpdated = request.getParameter("role_updated");
        String phoneUpdated = request.getParameter("phone_updated");
        String emailUpdated = request.getParameter("email_updated");
<<<<<<< HEAD
        String kppAdded = request.getParameter("kpp_added");
        String kppDeleted = request.getParameter("kpp_deleted");
=======
>>>>>>> origin/SPPPA
        String tempPw  = request.getParameter("tempPw");
        String error   = request.getParameter("error");
    %>
    <% if ("1".equals(deleted)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
    <% } else if ("1".equals(toggled)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
    <% } else if ("1".equals(roleUpdated)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
    <% } else if ("1".equals(phoneUpdated)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
    <% } else if ("1".equals(emailUpdated)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
<<<<<<< HEAD
    <% } else if ("1".equals(kppAdded)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
    <% } else if ("1".equals(kppDeleted)) { %>
        <div id="successPopup" class="success-popup show" role="dialog" aria-live="polite" aria-label="Notifikasi berjaya">
            <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
            <div class="success-popup-content">
                <div class="success-title">BERJAYA!</div>
                <div class="success-text"></div>
                <button type="button" class="success-ok" data-close-success-popup>OK</button>
            </div>
        </div>
=======
>>>>>>> origin/SPPPA
    <% } else if ("cannot_delete_self".equals(error)) { %>
        <div class="alert alert-error">&#10007; Anda tidak boleh memadam akaun anda sendiri.</div>
    <% } else if ("cannot_suspend_self".equals(error)) { %>
        <div class="alert alert-error">&#10007; Anda tidak boleh menggantung akaun anda sendiri.</div>
    <% } else if ("cannot_change_own_role".equals(error)) { %>
        <div class="alert alert-error">&#10007; Anda tidak boleh menukar peranan akaun anda sendiri.</div>
    <% } else if ("last_admin".equals(error)) { %>
        <div class="alert alert-error">&#10007; Tidak boleh memadam pentadbir terakhir dalam sistem.</div>
    <% } else if ("last_active_admin".equals(error)) { %>
        <div class="alert alert-error">&#10007; Tidak boleh menggantung pentadbir aktif terakhir dalam sistem.</div>
    <% } else if ("invalid_role".equals(error)) { %>
        <div class="alert alert-error">&#10007; Peranan pengguna tidak sah.</div>
    <% } else if ("user_not_found".equals(error)) { %>
        <div class="alert alert-error">&#10007; Pengguna tidak ditemui.</div>
    <% } else if ("invalid_phone_number".equals(error)) { %>
        <div class="alert alert-error">&#10007; Nombor telefon tidak sah. Gunakan 8 hingga 20 aksara (nombor/simbol +()- sahaja).</div>
    <% } else if ("invalid_email".equals(error)) { %>
        <div class="alert alert-error">&#10007; Format e-mel tidak sah.</div>
    <% } else if ("email_exists".equals(error)) { %>
        <div class="alert alert-error">&#10007; E-mel sudah digunakan oleh pengguna lain.</div>
<<<<<<< HEAD
    <% } else if ("kpp_invalid".equals(error)) { %>
        <div class="alert alert-error">&#10007; Maklumat KPP tidak lengkap atau tidak sah.</div>
    <% } else if ("kpp_invalid_email".equals(error)) { %>
        <div class="alert alert-error">&#10007; E-mel KPP tidak sah.</div>
    <% } else if ("kpp_email_exists".equals(error)) { %>
        <div class="alert alert-error">&#10007; E-mel KPP sudah wujud dalam senarai.</div>
    <% } else if ("kpp_not_found".equals(error)) { %>
        <div class="alert alert-error">&#10007; Rekod KPP tidak ditemui.</div>
=======
>>>>>>> origin/SPPPA
    <% } else if ("db_error".equals(error)) { %>
        <div class="alert alert-error">&#10007; Ralat semasa memproses permintaan. Sila cuba lagi.</div>
    <% } %>
    <% if ("1".equals(reset) && tempPw != null && !tempPw.isEmpty()) { %>
        <div id="resetSuccessModal" class="modal-overlay active">
            <div class="modal">
                <h3 class="alert-with-gif" style="margin-bottom:12px;">
                    <img class="success-gif" src="${pageContext.request.contextPath}/assets/images/success.png" alt="Berjaya">
                    <span>&#128273; Kata Laluan Sementara</span>
                </h3>
                <p>Kata laluan pengguna telah berjaya ditetapkan semula. Sila sampaikan kata laluan sementara ini kepada pengguna berkenaan.</p>
                <div class="temp-pw-box"><%= esc(tempPw) %></div>
                <div class="modal-actions">
                    <button type="button" class="btn btn-primary" onclick="document.getElementById('resetSuccessModal').classList.remove('active')">OK</button>
                </div>
            </div>
        </div>
    <% } %>

    <div class="panel">
        <%
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> users = (List<Map<String, Object>>) request.getAttribute("users");
            List<Map<String, Object>> adminAuditLogs = (List<Map<String, Object>>) request.getAttribute("admin_audit_logs");
            String searchQuery = String.valueOf(request.getAttribute("search") == null ? "" : request.getAttribute("search"));
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        %>
        <div class="users-toolbar">
            <form class="search-form" method="get" action="${pageContext.request.contextPath}/admin/users">
                <img class="search-form-icon" src="${pageContext.request.contextPath}/icon/search.png" alt="Cari pengguna">
                <input type="text" name="search" value="<%= esc(searchQuery) %>" placeholder="Cari nama, username atau e-mel">
                <button type="submit" class="btn btn-secondary">Cari</button>
                <% if (searchQuery != null && !searchQuery.isBlank()) { %>
                    <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/users">Reset</a>
                <% } %>
            </form>
            <span class="user-count">Jumlah: <%= users != null ? users.size() : 0 %> pengguna</span>
        </div>

        <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>ID Pengguna</th>
                    <th>Nama Penuh</th>
                    <th>Nama Pengguna</th>
                    <th>E-mel</th>
                    <th>Nombor Telefon</th>
                    <th>Peranan</th>
                    <th>Status</th>
                    <th>Tarikh Daftar</th>
                    <th>Tindakan</th>
                </tr>
            </thead>
            <tbody>
            <% if (users == null || users.isEmpty()) { %>
<<<<<<< HEAD
                <tr><td colspan="10" class="empty">Tiada pengguna dijumpai.</td></tr>
=======
                <tr><td colspan="9" class="empty">Tiada pengguna dijumpai.</td></tr>
>>>>>>> origin/SPPPA
            <% } else {
                int idx = 1;
                for (Map<String, Object> u : users) {
                    String userId    = String.valueOf(u.get("id"));
                    String displayId = esc(String.valueOf(u.get("display_id") == null ? "-" : u.get("display_id")));
                    String fullName  = esc(String.valueOf(u.get("full_name")));
                    String username  = esc(String.valueOf(u.get("username")));
                    String email     = esc(String.valueOf(u.get("email")));
                    String phoneNumber = esc(String.valueOf(u.get("phone_number") == null ? "" : u.get("phone_number")));
                    String role      = String.valueOf(u.get("role"));
                    String status    = String.valueOf(u.get("status"));
                    Timestamp createdAt = (Timestamp) u.get("created_at");
                    String dateStr   = createdAt != null ? sdf.format(createdAt) : "-";
                        String roleClass = "ADMIN".equals(role) ? "role-admin"
                            : "STAFF".equals(role) ? "role-staff"
                            : "role-user";
                    String statClass = "ACTIVE".equals(status) ? "status-active"
                                     : "SUSPENDED".equals(status) ? "status-suspended" : "status-inactive";
                    boolean isActive = "ACTIVE".equals(status);
            %>
                <tr>
                    <td><%= idx++ %></td>
                    <td><strong><%= displayId %></strong></td>
                    <td><strong><%= fullName %></strong></td>
                    <td><%= username %></td>
                    <td><%= email %></td>
                    <td><%= phoneNumber.isEmpty() ? "-" : phoneNumber %></td>
                    <td><span class="role-pill <%= roleClass %>"><%= role %></span></td>
                    <td><span class="status-pill <%= statClass %>"><%= status %></span></td>
                    <td class="subtle"><%= dateStr %></td>
                    <td class="table-actions">
                        <div class="action-menu">
                            <button type="button" class="btn action-trigger" onclick="toggleActionMenu(event, this)">Tindakan</button>
                            <div class="action-dropdown">
                                <button type="button" class="action-item"
                                        onclick="confirmRole('<%= userId %>', '<%= username %>', '<%= role %>')">
                                    Edit Peranan
                                </button>
                                <button type="button" class="action-item"
                                        onclick="confirmReset('<%= userId %>', '<%= username %>')">
                                    Reset Kata Laluan
                                </button>
                                <button type="button" class="action-item"
                                        onclick="confirmPhone('<%= userId %>', '<%= username %>', '<%= phoneNumber %>')">
                                    Edit Nombor Telefon
                                </button>
                                <button type="button" class="action-item"
                                        onclick="confirmEmail('<%= userId %>', '<%= username %>', '<%= email %>')">
                                    Edit E-mel
                                </button>
                                <form method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
                                    <input type="hidden" name="_csrf" value="${csrf_token}">
<<<<<<< HEAD
                                    <input type="hidden" name="action" value="set_status">
                                    <input type="hidden" name="status" value="ACTIVE">
                                    <input type="hidden" name="userId" value="<%= userId %>">
                                    <button type="submit" class="action-item" <%= isActive ? "disabled" : "" %>>Aktifkan</button>
                                </form>
                                <form method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
                                    <input type="hidden" name="_csrf" value="${csrf_token}">
                                    <input type="hidden" name="action" value="set_status">
                                    <input type="hidden" name="status" value="SUSPENDED">
                                    <input type="hidden" name="userId" value="<%= userId %>">
                                    <button type="submit" class="action-item" <%= !isActive ? "disabled" : "" %>>Nyahaktifkan</button>
=======
                                    <input type="hidden" name="action" value="toggle_status">
                                    <input type="hidden" name="userId" value="<%= userId %>">
                                    <button type="submit" class="action-item"><%= toggleLabel %></button>
>>>>>>> origin/SPPPA
                                </form>
                                <button type="button" class="action-item action-item-danger"
                                        onclick="confirmDelete('<%= userId %>', '<%= username %>')">
                                    Padam Pengguna
                                </button>
                            </div>
                        </div>
                    </td>
                </tr>
            <% } } %>
            </tbody>
        </table>
        </div>
    </div>

    <div class="panel kpp-panel">
        <h3 style="margin:0 0 10px;color:#0f6bae;">Urus Senarai KPP (Tindakan Ketua Penolong Pengarah)</h3>
        <p style="margin:0 0 12px;color:#5b7384;font-size:13px;">Tambah atau buang nama KPP, e-mel dan cawangan. Senarai ini akan digunakan pada panel Tindakan Ketua Penolong Pengarah.</p>
        <form class="kpp-form" method="post" action="${pageContext.request.contextPath}/admin/users">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" name="action" value="add_kpp_contact">
            <div class="kpp-field">
                <label for="kppNameInput">Nama KPP</label>
                <input id="kppNameInput" name="kpp_name" type="text" placeholder="Contoh: Ahmad bin Ali" required>
            </div>
            <div class="kpp-field">
                <label for="kppBranchInput">Cawangan</label>
                <input id="kppBranchInput" name="kpp_branch" type="text" placeholder="Contoh: Cawangan Kota Kinabalu" required>
            </div>
            <div class="kpp-field">
                <label for="kppEmailInput">E-mel</label>
                <input id="kppEmailInput" name="kpp_email" type="email" placeholder="contoh@domain.com" required>
            </div>
            <div>
                <button type="submit" class="btn btn-primary">Tambah KPP</button>
            </div>
        </form>

        <%
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> kppContacts = (List<Map<String, Object>>) request.getAttribute("kpp_contacts");
        %>
        <div class="kpp-table-wrap">
            <table class="kpp-table">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th>Nama KPP</th>
                        <th>Cawangan</th>
                        <th>E-mel</th>
                        <th style="width:130px;">Tindakan</th>
                    </tr>
                </thead>
                <tbody>
                <% if (kppContacts == null || kppContacts.isEmpty()) { %>
                    <tr><td colspan="5" class="kpp-empty">Belum ada senarai KPP. Tambah rekod pertama menggunakan borang di atas.</td></tr>
                <% } else {
                    for (Map<String, Object> kpp : kppContacts) {
                        String kppId = String.valueOf(kpp.get("id"));
                %>
                    <tr>
                        <td><strong><%= esc(kppId) %></strong></td>
                        <td><strong><%= esc(String.valueOf(kpp.get("name"))) %></strong></td>
                        <td><%= esc(String.valueOf(kpp.get("branch"))) %></td>
                        <td><%= esc(String.valueOf(kpp.get("email"))) %></td>
                        <td>
                            <form method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;" onsubmit="return confirm('Padam rekod KPP ini?');">
                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                <input type="hidden" name="action" value="delete_kpp_contact">
                                <input type="hidden" name="kpp_id" value="<%= esc(kppId) %>">
                                <button type="submit" class="btn btn-danger">Padam</button>
                            </form>
                        </td>
                    </tr>
                <%  }
                   } %>
                </tbody>
            </table>
        </div>
    </div>

    <div class="panel audit-panel">
        <div class="audit-panel-header">
            <h3 style="margin:0;color:#0f6bae;">Notes: Rekod Tindakan Admin</h3>
            <button type="button" class="audit-toggle-btn" id="toggleAuditBtnUsers" aria-expanded="true" aria-controls="adminAuditContentUsers" title="Sembunyi rekod tindakan admin">
                <img id="toggleAuditIconUsers" src="${pageContext.request.contextPath}/icon/hide.png" alt="Sembunyikan rekod tindakan admin">
            </button>
        </div>
        <div id="adminAuditContentUsers" class="audit-content">
        <ul class="audit-list">
            <% if (adminAuditLogs != null && !adminAuditLogs.isEmpty()) {
                for (Map<String, Object> auditRow : adminAuditLogs) {
                    String actorName = auditRow.get("full_name") == null
                            ? String.valueOf(auditRow.get("username") == null ? "Admin" : auditRow.get("username"))
                            : String.valueOf(auditRow.get("full_name"));
                    String actorDisplayId = String.valueOf(auditRow.get("display_user_id") == null ? "-" : auditRow.get("display_user_id"));
                    String action = String.valueOf(auditRow.get("action") == null ? "-" : auditRow.get("action"));
                    String actionDisplay = action.replace('_', ' ').replaceAll("\\s+", " ").trim();
                    String details = String.valueOf(auditRow.get("details") == null ? "Tiada perincian." : auditRow.get("details"));
                    Timestamp actionAt = (Timestamp) auditRow.get("created_at");
            %>
            <li class="audit-item">
                <strong><%= esc(actorName) %> (<%= esc(actorDisplayId) %>) · <%= esc(actionDisplay) %></strong>
                <p><%= esc(details) %></p>
                <div class="audit-meta">
                    <span><%= actionAt != null ? sdf.format(actionAt) : "Masa tidak direkod" %></span>
                </div>
            </li>
            <%      }
               } else { %>
            <li class="audit-item">
                <strong>Belum ada rekod tindakan</strong>
                <p>Log tindakan admin akan muncul di sini secara automatik.</p>
            </li>
            <% } %>
        </ul>
        </div>
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
                <input type="hidden" name="_csrf" value="${csrf_token}">
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
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="action" value="reset_password">
                <input type="hidden" name="userId" id="resetUserId" value="">
                <button type="submit" class="btn btn-info">Ya, Reset</button>
            </form>
        </div>
    </div>
</div>

<!-- Edit Role Modal -->
<div class="modal-overlay" id="roleModal">
    <div class="modal">
        <h3>&#9881; Edit Peranan Pengguna</h3>
        <p id="roleModalMsg">Pilih peranan baharu untuk pengguna.</p>
        <form id="roleForm" method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" name="action" value="update_role">
            <input type="hidden" name="userId" id="roleUserId" value="">
            <div class="field" style="margin-bottom:14px;">
                <label for="roleSelect" style="display:block;font-weight:700;margin-bottom:8px;color:#334155;">Peranan</label>
                <select id="roleSelect" name="role" style="width:100%;padding:11px 12px;border:1px solid #cbd5e1;border-radius:8px;font-family:inherit;font-size:14px;">
                    <option value="USER">USER (Pengguna)</option>
<<<<<<< HEAD
                    <option value="STAFF">STAFF (Staf Dalaman)</option>
=======
>>>>>>> origin/SPPPA
                    <option value="ADMIN">ADMIN (Pentadbir)</option>
                </select>
            </div>
            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal('roleModal')">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan Peranan</button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Phone Number Modal -->
<div class="modal-overlay" id="phoneModal">
    <div class="modal">
        <h3>&#9742; Edit Nombor Telefon</h3>
        <p id="phoneModalMsg">Kemaskini nombor telefon pengguna.</p>
        <form id="phoneForm" method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" name="action" value="update_phone_number">
            <input type="hidden" name="userId" id="phoneUserId" value="">
            <div class="field" style="margin-bottom:14px;">
                <label for="phoneInput" style="display:block;font-weight:700;margin-bottom:8px;color:#334155;">Nombor Telefon</label>
                <input id="phoneInput" name="phone_number" type="tel" pattern="[0-9+()\-\s]{8,20}" style="width:100%;padding:11px 12px;border:1px solid #cbd5e1;border-radius:8px;font-family:inherit;font-size:14px;" required>
            </div>
            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal('phoneModal')">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan Nombor</button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Email Modal -->
<div class="modal-overlay" id="emailModal">
    <div class="modal">
        <h3>&#9993; Edit E-mel Pengguna</h3>
        <p id="emailModalMsg">Kemaskini e-mel pengguna.</p>
        <form id="emailForm" method="post" action="${pageContext.request.contextPath}/admin/users" style="margin:0;">
            <input type="hidden" name="_csrf" value="${csrf_token}">
            <input type="hidden" name="action" value="update_email">
            <input type="hidden" name="userId" id="emailUserId" value="">
            <div class="field" style="margin-bottom:14px;">
                <label for="emailInput" style="display:block;font-weight:700;margin-bottom:8px;color:#334155;">E-mel</label>
                <input id="emailInput" name="email" type="email" style="width:100%;padding:11px 12px;border:1px solid #cbd5e1;border-radius:8px;font-family:inherit;font-size:14px;" required>
            </div>
            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" onclick="closeModal('emailModal')">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan E-mel</button>
            </div>
        </form>
    </div>
</div>

<script>
    function closeAllActionMenus(exceptMenu) {
        document.querySelectorAll('.action-menu.open').forEach(function(menu) {
            if (!exceptMenu || menu !== exceptMenu) {
                menu.classList.remove('open');
            }
        });
    }
    function toggleActionMenu(event, triggerBtn) {
        event.stopPropagation();
        var menu = triggerBtn.closest('.action-menu');
        if (!menu) return;
        var shouldOpen = !menu.classList.contains('open');
        closeAllActionMenus();
        if (shouldOpen) {
            menu.classList.add('open');
        }
    }
    function confirmDelete(userId, username) {
        closeAllActionMenus();
        document.getElementById('deleteUserId').value = userId;
        document.getElementById('modalMsg').textContent =
            'Adakah anda pasti mahu memadam akaun "' + username + '"? Tindakan ini tidak boleh dibatalkan.';
        document.getElementById('deleteModal').classList.add('active');
    }
    function confirmReset(userId, username) {
        closeAllActionMenus();
        document.getElementById('resetUserId').value = userId;
        document.getElementById('resetModalMsg').textContent =
            'Kata laluan sedia ada "' + username + '" akan digantikan dengan kata laluan sementara yang dijana secara rawak.';
        document.getElementById('resetModal').classList.add('active');
    }
    function confirmRole(userId, username, currentRole) {
        closeAllActionMenus();
        document.getElementById('roleUserId').value = userId;
        document.getElementById('roleModalMsg').textContent =
            'Pilih peranan baharu untuk pengguna "' + username + '".';
<<<<<<< HEAD
        document.getElementById('roleSelect').value =
            currentRole === 'ADMIN' ? 'ADMIN' : (currentRole === 'STAFF' ? 'STAFF' : 'USER');
=======
        document.getElementById('roleSelect').value = currentRole === 'ADMIN' ? 'ADMIN' : 'USER';
>>>>>>> origin/SPPPA
        document.getElementById('roleModal').classList.add('active');
    }
    function confirmPhone(userId, username, currentPhone) {
        closeAllActionMenus();
        document.getElementById('phoneUserId').value = userId;
        document.getElementById('phoneModalMsg').textContent =
            'Kemaskini nombor telefon untuk pengguna "' + username + '".';
        document.getElementById('phoneInput').value = currentPhone || '';
        document.getElementById('phoneModal').classList.add('active');
    }
    function confirmEmail(userId, username, currentEmail) {
        closeAllActionMenus();
        document.getElementById('emailUserId').value = userId;
        document.getElementById('emailModalMsg').textContent =
            'Kemaskini e-mel untuk pengguna "' + username + '".';
        document.getElementById('emailInput').value = currentEmail || '';
        document.getElementById('emailModal').classList.add('active');
    }
    function closeModal(id) {
        document.getElementById(id).classList.remove('active');
    }
    ['deleteModal', 'resetModal', 'roleModal', 'phoneModal', 'emailModal'].forEach(function(id) {
        document.getElementById(id).addEventListener('click', function(e) {
            if (e.target === this) closeModal(id);
        });
    });
    document.addEventListener('click', function() {
        closeAllActionMenus();
    });
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeAllActionMenus();
        }
    });
</script>
<script>
(function() {
    var popup = document.getElementById('successPopup');
    if (!popup) return;
    function closePopup() {
        popup.classList.remove('show');
        window.setTimeout(function() {
            if (popup && popup.parentNode) popup.parentNode.removeChild(popup);
        }, 260);
    }
    var closeBtn = popup.querySelector('[data-close-success-popup]');
    if (closeBtn) closeBtn.addEventListener('click', closePopup);
})();

(function initAdminAuditToggleUsers() {
    var button = document.getElementById('toggleAuditBtnUsers');
    var content = document.getElementById('adminAuditContentUsers');
    var icon = document.getElementById('toggleAuditIconUsers');
    if (!button || !content || !icon) return;

    function setState(hidden) {
        content.classList.toggle('is-hidden', hidden);
        button.setAttribute('aria-expanded', hidden ? 'false' : 'true');
        button.setAttribute('title', hidden ? 'Paparkan rekod tindakan admin' : 'Sembunyi rekod tindakan admin');
        icon.src = hidden ? '${pageContext.request.contextPath}/icon/unhide.png' : '${pageContext.request.contextPath}/icon/hide.png';
        icon.alt = hidden ? 'Paparkan rekod tindakan admin' : 'Sembunyikan rekod tindakan admin';
    }

    button.addEventListener('click', function() {
        setState(!content.classList.contains('is-hidden'));
    });

    setState(false);
})();
</script>

</body>
</html>

