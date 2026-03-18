<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Senarai Produk Berdaftar - SPPA</title>
    <style>
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-sky: #e8f7ff;
            --brand-yellow: #fff212;
            --text: #183244;
            --muted: #5f7686;
            --panel: #ffffff;
            --line: #d6e7f2;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(180deg, #eff9ff 0%, #f8fbfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 72%, var(--brand-yellow) 180%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand img { width: 52px; height: auto; background: white; border-radius: 14px; padding: 6px; }
        .brand h1 { margin: 0; font-size: 20px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.88; }
        .nav-links a { color: white; text-decoration: none; margin-left: 16px; font-weight: 600; }
        .container { max-width: 1280px; margin: 26px auto; padding: 0 20px 32px; }
        .hero { display: grid; grid-template-columns: 2fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--panel); border: 1px solid var(--line); border-radius: 18px; box-shadow: 0 18px 44px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; }
        .metric { display: inline-flex; align-items: center; gap: 8px; padding: 8px 12px; background: var(--brand-sky); border-radius: 999px; font-weight: 700; }
        .contact-image { width: 100%; border-radius: 14px; border: 1px solid var(--line); }
        .filters { display: grid; grid-template-columns: 2fr 1fr auto; gap: 12px; align-items: end; margin-bottom: 18px; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); background: white; }
        .btn { padding: 12px 16px; border-radius: 12px; border: none; cursor: pointer; text-decoration: none; font-weight: 700; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 13px 12px; border-bottom: 1px solid #e5f0f6; text-align: left; vertical-align: top; }
        th { font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        tr:hover { background: #f7fcff; }
        .tag { display: inline-block; padding: 4px 10px; border-radius: 999px; background: #eef7fb; color: var(--brand-navy); font-size: 12px; font-weight: 700; }
        .source-link { color: var(--brand-blue); font-weight: 700; text-decoration: none; }
        @media (max-width: 980px) { .hero, .filters { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; } .nav-links a { margin-left: 0; margin-right: 16px; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Senarai Produk Berdaftar</h1>
                <p>Sistem Pendaftaran Produk Air • Jabatan Air Negeri Sabah</p>
            </div>
        </div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
            <a href="${pageContext.request.contextPath}/logout">Log Keluar</a>
        </div>
    </div>

    <div class="container">
        <div class="hero">
            <div class="panel">
                <div class="metric"><span><%= request.getAttribute("product_total") %></span> produk ditemui</div>
                <h2>Rujukan produk air yang telah berdaftar</h2>
                <p>Halaman ini mengambil data terus daripada jadual MySQL rasmi dalam sistem. Pemohon boleh menyemak jenama, kategori, klasifikasi, dan pembekal sebelum menghantar permohonan baharu.</p>
            </div>
            <div class="panel">
                <img class="contact-image" src="${pageContext.request.contextPath}/assets/images/contact-jans.png" alt="Maklumat hubungan Jabatan Air Sabah">
            </div>
        </div>

        <div class="panel">
            <form method="get" action="${pageContext.request.contextPath}/products" class="filters">
                <div class="field">
                    <label for="q">Carian</label>
                    <input id="q" name="q" type="text" value="<%= request.getAttribute("search_query") %>" placeholder="Cari jenama, pembekal atau bahan produk">
                </div>
                <div class="field">
                    <label for="type">Jenis / Kumpulan</label>
                    <select id="type" name="type">
                        <option value="">Semua jenis</option>
                        <%
                            List<String> productTypes = (List<String>) request.getAttribute("product_types");
                            String selectedType = String.valueOf(request.getAttribute("selected_type"));
                            if (productTypes != null) {
                                for (String type : productTypes) {
                        %>
                        <option value="<%= type %>" <%= type.equals(selectedType) ? "selected" : "" %>><%= type %></option>
                        <%      }
                            }
                        %>
                    </select>
                </div>
                <div>
                    <button class="btn btn-primary" type="submit">Cari Produk</button>
                </div>
            </form>

            <table>
                <thead>
                    <tr>
                        <th>No.</th>
                        <th>Produk / Jenama</th>
                        <th>Pembekal / Ejen</th>
                        <th>Kumpulan</th>
                        <th>Klasifikasi</th>
                        <th>Sah Sehingga</th>
                        <th>Sumber</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        List<Map<String, Object>> products = (List<Map<String, Object>>) request.getAttribute("products");
                        if (products == null || products.isEmpty()) {
                    %>
                    <tr>
                        <td colspan="7" style="text-align:center;color:#5f7686;padding:32px;">Tiada produk ditemui untuk carian ini.</td>
                    </tr>
                    <% } else {
                        for (Map<String, Object> product : products) {
                    %>
                    <tr>
                        <td><strong><%= product.get("no") %></strong></td>
                        <td>
                            <strong><%= product.get("product_materials") %></strong><br>
                            <span class="tag"><%= product.get("brand") == null || "null".equals(String.valueOf(product.get("brand"))) ? "Tanpa jenama" : product.get("brand") %></span>
                        </td>
                        <td><%= product.get("supplier_agent") %></td>
                        <td><%= product.get("product_type") %></td>
                        <td><%= product.get("classification") %></td>
                        <td><%= product.get("supplier_valid_until") == null ? "-" : product.get("supplier_valid_until") %></td>
                        <td>
                            <% if (product.get("source_url") != null) { %>
                                <a class="source-link" href="<%= product.get("source_url") %>" target="_blank">Lihat Sumber</a>
                            <% } else { %>
                                -
                            <% } %>
                        </td>
                    </tr>
                    <%  }
                       }
                    %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>