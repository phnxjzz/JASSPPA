<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.regex.Matcher" %>
<%@ page import="java.util.regex.Pattern" %>
<%!
    private String escapeHtml(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private List<String> extractUrls(String input) {
        List<String> urls = new ArrayList<>();
        if (input == null || input.isBlank()) {
            return urls;
        }

        Pattern pattern = Pattern.compile("https?://[^\\s\\\"|]+", Pattern.CASE_INSENSITIVE);
        Matcher matcher = pattern.matcher(input);
        while (matcher.find()) {
            String url = matcher.group().trim();
            if (!urls.contains(url)) {
                urls.add(url);
            }
        }
        return urls;
    }

    private String safeText(Object value) {
        if (value == null) {
            return "-";
        }
        String text = String.valueOf(value).trim();
        if (text.isEmpty() || "null".equalsIgnoreCase(text)) {
            return "-";
        }
        return text;
    }

    private String formatValidDate(Object value) {
        if (value == null) {
            return "-";
        }
        if (value instanceof Date) {
            return new SimpleDateFormat("dd-MM-yyyy").format((Date) value);
        }
        String raw = String.valueOf(value).trim();
        if (raw.isEmpty() || "null".equalsIgnoreCase(raw)) {
            return "-";
        }
        return raw;
    }

    private String[] splitSupplierInfo(String supplierAgent) {
        if (supplierAgent == null || supplierAgent.isBlank()) {
            return new String[]{"-", "-"};
        }
        String cleaned = supplierAgent.trim().replaceAll("\\s+", " ");
        int comma = cleaned.indexOf(',');
        if (comma > 0 && comma < cleaned.length() - 1) {
            return new String[]{cleaned.substring(0, comma).trim(), cleaned.substring(comma + 1).trim()};
        }
        return new String[]{cleaned, cleaned};
    }
%>
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
        .brand-logo { width: 52px; height: 52px; border-radius: 14px; object-fit: contain; background: white; padding: 4px; }
        .brand h1 { margin: 0; font-size: 20px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.88; }
        .nav-links a { color: white; text-decoration: none; margin-left: 16px; font-weight: 600; }
        .container { max-width: 1280px; margin: 26px auto; padding: 0 20px 32px; }
        .hero { display: grid; grid-template-columns: 2fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--panel); border: 1px solid var(--line); border-radius: 18px; box-shadow: 0 18px 44px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; }
        .metric { display: inline-flex; align-items: center; gap: 8px; padding: 8px 12px; background: var(--brand-sky); border-radius: 999px; font-weight: 700; }
        .contact-image { width: 100%; border-radius: 14px; border: 1px solid var(--line); padding: 14px; background: #f7fbff; }
        .contact-image strong { display: block; margin-bottom: 8px; color: var(--brand-navy); }
        .contact-image p { margin: 4px 0; color: var(--muted); font-size: 14px; }
        .filters { display: grid; grid-template-columns: 2fr 1fr auto; gap: 12px; align-items: end; margin-bottom: 18px; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); background: white; }
        .btn { padding: 12px 16px; border-radius: 12px; border: none; cursor: pointer; text-decoration: none; font-weight: 700; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .btn-attachment { background: #e7f4fb; color: #0b4d71; border: 1px solid #b9dcee; padding: 7px 10px; border-radius: 10px; font-weight: 700; cursor: pointer; }
        .table-wrap { width: 100%; overflow-x: auto; border-radius: 16px; }
        table { width: 100%; min-width: 1120px; border-collapse: collapse; table-layout: fixed; }
        th, td { padding: 13px 12px; border-bottom: 1px solid #e5f0f6; text-align: left; vertical-align: top; word-break: break-word; overflow-wrap: anywhere; }
        th { font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        tr:hover { background: #f7fcff; }
        .tag { display: inline-block; padding: 4px 10px; border-radius: 999px; background: #eef7fb; color: var(--brand-navy); font-size: 12px; font-weight: 700; }
        .source-link { color: var(--brand-blue); font-weight: 700; text-decoration: none; }
        .supplier-name { display: block; font-weight: 700; margin-bottom: 5px; }
        .supplier-address { color: var(--muted); font-size: 13px; line-height: 1.5; }
        .cell-tight { white-space: normal; line-height: 1.5; }
        .import-note { margin-top: 10px; color: var(--muted); font-size: 13px; }
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(4, 24, 38, 0.72); z-index: 9999; align-items: center; justify-content: center; padding: 16px; }
        .modal-overlay.open { display: flex; }
        .modal-card { width: min(1000px, 96vw); height: min(88vh, 760px); background: #fff; border-radius: 16px; overflow: hidden; display: grid; grid-template-rows: auto 1fr; }
        .modal-header { display: flex; justify-content: space-between; align-items: center; padding: 12px 14px; border-bottom: 1px solid #e5f0f6; }
        .modal-title { font-size: 15px; font-weight: 700; }
        .modal-close { border: none; background: #eff4f8; border-radius: 10px; padding: 7px 10px; font-weight: 700; cursor: pointer; }
        .modal-body { display: grid; grid-template-columns: 240px 1fr; min-height: 0; }
        .attachment-list { border-right: 1px solid #e5f0f6; padding: 10px; overflow: auto; }
        .attachment-list button { width: 100%; margin-bottom: 8px; text-align: left; border: 1px solid #d6e7f2; background: #f8fbfe; border-radius: 9px; padding: 9px; cursor: pointer; }
        .attachment-list button.active { background: #e8f7ff; border-color: #8acde9; }
        .viewer { min-height: 0; display: grid; grid-template-rows: 1fr auto; }
        .viewer iframe { width: 100%; height: 100%; min-height: 420px; border: 0; }
        .viewer-empty { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--muted); }
        @media (max-width: 980px) { .hero, .filters { grid-template-columns: 1fr; } .navbar { flex-direction: column; align-items: flex-start; } .nav-links a { margin-left: 0; margin-right: 16px; } }
        @media (max-width: 780px) { .modal-body { grid-template-columns: 1fr; } .attachment-list { border-right: 0; border-bottom: 1px solid #e5f0f6; max-height: 180px; } }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png" class="brand-logo" alt="Logo Jabatan Air Sabah">
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
                <p class="import-note">Saved <%= request.getAttribute("product_total") %> records to data\water_products.json and data\water_products.csv</p>
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

        <div class="panel">
            <form method="get" action="${pageContext.request.contextPath}/products" class="filters">
                <div class="field">
                    <label for="q">Carian</label>
                    <input id="q" name="q" type="text" value="<%= request.getAttribute("search_query") %>" placeholder="Cari supplier/ejen, jenama, produk/material, atau tarikh sah (contoh 21-01-2028)">
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

            <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th style="width:70px;">No.</th>
                        <th style="width:250px;">Supplier Name &amp; Address</th>
                        <th style="width:220px;">Product / Materials</th>
                        <th style="width:160px;">Category</th>
                        <th style="width:150px;">Type</th>
                        <th style="width:120px;">Brand</th>
                        <th style="width:120px;">Valid Date</th>
                        <th style="width:150px;">Attachment</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        List<Map<String, Object>> products = (List<Map<String, Object>>) request.getAttribute("products");
                        if (products == null || products.isEmpty()) {
                    %>
                    <tr>
                        <td colspan="8" style="text-align:center;color:#5f7686;padding:32px;">Tiada produk ditemui untuk carian ini.</td>
                    </tr>
                    <% } else {
                        for (Map<String, Object> product : products) {
                            String[] supplierInfo = splitSupplierInfo(String.valueOf(product.get("supplier_agent")));
                            String productMaterials = safeText(product.get("product_materials"));
                            String category = safeText(product.get("product_type"));
                            String itemType = safeText(product.get("classification"));
                            String brand = safeText(product.get("brand"));
                            String validDate = formatValidDate(product.get("supplier_valid_until"));
                            List<String> attachments = extractUrls(String.valueOf(product.get("attachment_urls")));
                            String attachmentPayload = escapeHtml(String.join("||", attachments));
                    %>
                    <tr>
                        <td><strong><%= product.get("no") %></strong></td>
                        <td class="cell-tight">
                            <span class="supplier-name"><%= escapeHtml(supplierInfo[0]) %></span>
                            <span class="supplier-address"><%= escapeHtml(supplierInfo[1]) %></span>
                        </td>
                        <td class="cell-tight"><%= escapeHtml(productMaterials) %></td>
                        <td><span class="tag"><%= escapeHtml(category) %></span></td>
                        <td class="cell-tight"><%= escapeHtml(itemType) %></td>
                        <td class="cell-tight"><%= escapeHtml(brand) %></td>
                        <td><%= escapeHtml(validDate) %></td>
                        <td>
                            <% if (attachments.isEmpty()) { %>
                                -
                            <% } else { %>
                                <button type="button" class="btn-attachment open-attachment" data-attachments="<%= attachmentPayload %>">Lihat Lampiran (<%= attachments.size() %>)</button>
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
    </div>

    <div id="attachmentModal" class="modal-overlay" aria-hidden="true">
        <div class="modal-card" role="dialog" aria-modal="true" aria-label="Lampiran Produk">
            <div class="modal-header">
                <div class="modal-title">Lampiran Produk</div>
                <button type="button" id="closeAttachmentModal" class="modal-close">Tutup</button>
            </div>
            <div class="modal-body">
                <div class="attachment-list" id="attachmentList"></div>
                <div class="viewer" id="attachmentViewer">
                    <div class="viewer-empty">Tiada lampiran dipilih.</div>
                </div>
            </div>
        </div>
    </div>

    <script>
        (function () {
            const modal = document.getElementById('attachmentModal');
            const closeBtn = document.getElementById('closeAttachmentModal');
            const attachmentList = document.getElementById('attachmentList');
            const attachmentViewer = document.getElementById('attachmentViewer');
            const openButtons = document.querySelectorAll('.open-attachment');

            function escapeHtml(text) {
                return String(text)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/\"/g, '&quot;')
                    .replace(/'/g, '&#39;');
            }

            function buildProxyUrl(url) {
                return '${pageContext.request.contextPath}/product-attachments/view?url=' + encodeURIComponent(url);
            }

            function showViewer(url) {
                const proxyUrl = buildProxyUrl(url);
                attachmentViewer.innerHTML = ''
                    + '<iframe title="Lampiran Produk" src="' + escapeHtml(proxyUrl) + '"></iframe>'
                    + '<div style="padding:12px 14px;border-top:1px solid #e5f0f6;background:#f8fbfe;display:flex;gap:10px;flex-wrap:wrap;">'
                    + '<a class="source-link" href="' + escapeHtml(proxyUrl) + '" target="_blank" rel="noopener noreferrer">Buka lampiran</a>'
                    + '<a class="source-link" href="' + escapeHtml(url) + '" target="_blank" rel="noopener noreferrer">Sumber asal</a>'
                    + '</div>';
            }

            function openModal(urls) {
                attachmentList.innerHTML = '';
                attachmentViewer.innerHTML = '<div class="viewer-empty">Memuat lampiran...</div>';

                urls.forEach(function (url, index) {
                    const btn = document.createElement('button');
                    btn.type = 'button';
                    btn.textContent = 'Lampiran ' + (index + 1);
                    btn.addEventListener('click', function () {
                        attachmentList.querySelectorAll('button').forEach(function (b) { b.classList.remove('active'); });
                        btn.classList.add('active');
                        showViewer(url);
                    });
                    attachmentList.appendChild(btn);
                });

                const first = attachmentList.querySelector('button');
                if (first) {
                    first.classList.add('active');
                    showViewer(urls[0]);
                } else {
                    attachmentViewer.innerHTML = '<div class="viewer-empty">Tiada lampiran dijumpai.</div>';
                }

                modal.classList.add('open');
                modal.setAttribute('aria-hidden', 'false');
            }

            function closeModal() {
                modal.classList.remove('open');
                modal.setAttribute('aria-hidden', 'true');
                attachmentList.innerHTML = '';
                attachmentViewer.innerHTML = '<div class="viewer-empty">Tiada lampiran dipilih.</div>';
            }

            openButtons.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    const payload = btn.getAttribute('data-attachments') || '';
                    const urls = payload.split('||').map(function (x) { return x.trim(); }).filter(Boolean);
                    openModal(urls);
                });
            });

            closeBtn.addEventListener('click', closeModal);
            modal.addEventListener('click', function (event) {
                if (event.target === modal) {
                    closeModal();
                }
            });
            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape' && modal.classList.contains('open')) {
                    closeModal();
                }
            });
        })();
    </script>
</body>
</html>