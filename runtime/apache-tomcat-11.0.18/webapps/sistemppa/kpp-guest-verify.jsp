<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.lang.String" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Akses Khas Ketua Penolong Pengarah</title>
    <style>
* { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: inherit;
            background: linear-gradient(145deg, #e7f0f8, #f8fbff);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #0f172a;
        }
        .card {
            width: min(96%, 520px);
            background: #ffffff;
            border: 1px solid #dbe7f3;
            border-radius: 14px;
            box-shadow: 0 16px 38px rgba(8, 47, 73, 0.12);
            padding: 24px;
        }
        h1 {
            margin: 0 0 8px;
            font-size: 1.35rem;
        }
        p {
            margin: 0 0 14px;
            line-height: 1.55;
            color: #334155;
        }
        .meta {
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 10px;
            padding: 10px 12px;
            margin: 0 0 14px;
            font-size: 0.95rem;
        }
        label {
            display: block;
            font-weight: 600;
            margin-bottom: 6px;
        }
        input[type="email"] {
            width: 100%;
            border: 1px solid #bfd1e3;
            border-radius: 10px;
            padding: 11px 12px;
            font-size: 0.95rem;
            margin-bottom: 12px;
        }
        button {
            width: 100%;
            border: 0;
            border-radius: 10px;
            background: #0b5cab;
            color: #fff;
            font-weight: 700;
            font-size: 0.98rem;
            padding: 12px;
            cursor: pointer;
        }
        .error {
            border: 1px solid #fecaca;
            background: #fff1f2;
            color: #b91c1c;
            border-radius: 10px;
            padding: 10px 12px;
            margin-bottom: 12px;
            font-size: 0.93rem;
        }
    </style>
</head>
<body>
<%
    String token = request.getAttribute("kppToken") == null ? "" : String.valueOf(request.getAttribute("kppToken"));
    String verifyError = request.getAttribute("kppVerifyError") == null ? "" : String.valueOf(request.getAttribute("kppVerifyError"));
%>
<div class="card">
    <h1>Akses Guest Ketua Penolong Pengarah</h1>
    <p>Pautan khas ini hanya untuk penerima emel yang ditetapkan oleh admin. Sila masukkan emel yang sama untuk teruskan ke borang digital.</p>

    <div class="meta">
        Masukkan emel penerima untuk pengesahan akses.
    </div>

    <% if (!verifyError.isBlank()) { %>
    <div class="error"><%= verifyError %></div>
    <% } %>

    <form method="post" action="<%=request.getContextPath()%>/kpp/guest-access">
        <input type="hidden" name="flow_action" value="verify_email">
        <input type="hidden" name="token" value="<%= token %>">
        <input type="hidden" name="_csrf" value="${csrf_token}">
        <label for="email">Emel Penerima</label>
        <input id="email" name="access_email" type="email" autocomplete="email" required>
        <button type="submit">Sahkan dan Teruskan</button>
    </form>
</div>
</body>
</html>
