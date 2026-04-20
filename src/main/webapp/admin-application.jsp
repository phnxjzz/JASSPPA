<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Semakan Permohonan - SPPA</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(180deg, #eff8ff 0%, #f7fbfd 100%); margin: 0; color: #1e293b; }
        .navbar { background: linear-gradient(130deg, #0F6BAE 0%, #2A9D8F 30%, #6DBE45 58%, #CDE11D 80%, #F2F72E 100%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 48px; height: 48px; border-radius: 14px; object-fit: contain; padding: 3px; }
        .brand strong { display: block; }
        .brand span { font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; }
        .container { max-width: 1200px; margin: 28px auto; padding: 0 20px; }
        .panel { border-radius: 12px; box-shadow: 0 10px 30px rgba(15, 23, 42, 0.08); padding: 24px; margin-bottom: 20px; }
        .grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
        .full { grid-column: 1 / -1; }
        .label { font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: #64748b; margin-bottom: 4px; }
        .value { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; min-height: 44px; }
        .docs table { width: 100%; border-collapse: collapse; }
        .docs th, .docs td { padding: 12px; border-bottom: 1px solid #e2e8f0; text-align: left; }
        textarea { width: 100%; min-height: 110px; border: 1px solid #cbd5e1; border-radius: 8px; padding: 12px; }
        .actions { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 12px; }
        .btn { border: 1px solid #fff; border-radius: 8px; padding: 12px 18px; cursor: pointer; color: white; font-weight: 700; }
        .approve { background: #15803d; }
        .reject { background: #b91c1c; }
        .suspend { background: #9a3412; }
        .secondary { background: #475569; text-decoration: none; display: inline-block; }
        .status { font-weight: 700; }
        .alert-error { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; border-radius: 10px; padding: 12px; margin-bottom: 14px; }
        .contact-card { width: 100%; max-width: 420px; border-radius: 12px; border: 1px solid #e2e8f0; background: #f8fbff; padding: 14px; color: #475569; }
        .contact-card strong { display: block; margin-bottom: 8px; color: #0f172a; }
        .contact-card p { margin: 4px 0; }
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
        }
        .icon-inline { width: 20px; height: 20px; object-fit: contain; vertical-align: middle; }
        .icon-link { width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.38); transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 4px; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: rgba(255,255,255,0.26); }</style>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <strong>SPPA - Semakan Permohonan</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div>
            <a href="${pageContext.request.contextPath}/dashboard">Kembali ke Dashboard</a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/assets/images/home.png" alt="Home"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
        </div>
    </div>

    <div class="container">
        <%
            Map<String, Object> applicationData = (Map<String, Object>) request.getAttribute("application");
            Map<String, Object> detail = (Map<String, Object>) request.getAttribute("applicationDetail");
            List<Map<String, Object>> documents = (List<Map<String, Object>>) request.getAttribute("documents");
        %>
        <div class="panel">
            <h2>Permohonan <%= String.format("PPP%03d", ((Number)applicationData.get("id")).intValue()) %></h2>
            <p>Status semasa: <span class="status"><%= applicationData.get("status") %></span></p>
            <div class="grid">
                <div>
                    <div class="label">Pemohon</div>
                    <div class="value"><%= applicationData.get("full_name") %></div>
                </div>
                <div>
                    <div class="label">Email Pemohon</div>
                    <div class="value"><%= applicationData.get("user_email") %></div>
                </div>
                <div>
                    <div class="label">Syarikat</div>
                    <div class="value"><%= applicationData.get("company_name") %></div>
                </div>
                <div>
                    <div class="label">Kategori Produk</div>
                    <div class="value"><%= applicationData.get("product_category") %></div>
                </div>
                <div>
                    <div class="label">Nama Produk</div>
                    <div class="value"><%= applicationData.get("product_name") %></div>
                </div>
                <div>
                    <div class="label">Dihantar Pada</div>
                    <div class="value"><%= applicationData.get("submitted_at") %></div>
                </div>
                <div class="full">
                    <div class="label">Ringkasan Permohonan</div>
                    <div class="value"><pre style="margin:0;white-space:pre-wrap;font-family:inherit;"><%= applicationData.get("product_description") %></pre></div>
                </div>
            </div>
        </div>

        <div class="panel">
            <h3>Butiran PPP1</h3>
            <div class="grid">
                <div><div class="label">Jenis Permohonan</div><div class="value"><%= detail.get("application_type") %></div></div>
                <div><div class="label">Telefon Pembekal</div><div class="value"><%= detail.get("supplier_phone") %></div></div>
                <div class="full"><div class="label">Alamat Pembekal</div><div class="value"><%= detail.get("supplier_address") %></div></div>
                <div><div class="label">Pengilang</div><div class="value"><%= detail.get("manufacturer_name") %></div></div>
                <div><div class="label">Telefon Pengilang</div><div class="value"><%= detail.get("manufacturer_phone") %></div></div>
                <div class="full"><div class="label">Alamat Pengilang</div><div class="value"><%= detail.get("manufacturer_address") %></div></div>
                <div><div class="label">Prinsipal</div><div class="value"><%= detail.get("principal_name") %></div></div>
                <div><div class="label">Telefon Prinsipal</div><div class="value"><%= detail.get("principal_phone") %></div></div>
                <div class="full"><div class="label">Alamat Prinsipal</div><div class="value"><%= detail.get("principal_address") %></div></div>
                <div><div class="label">Standard</div><div class="value"><%= detail.get("standard_name") %></div></div>
                <div><div class="label">No. Lesen Persijilan</div><div class="value"><%= detail.get("certification_license") %></div></div>
                <div><div class="label">Sah Sehingga</div><div class="value"><%= detail.get("certification_valid_until") %></div></div>
                <div><div class="label">No. Laporan Ujian</div><div class="value"><%= detail.get("test_report_reference") %></div></div>
                <div><div class="label">Tarikh Laporan Ujian</div><div class="value"><%= detail.get("test_report_date") %></div></div>
                <div><div class="label">Jaminan Produk</div><div class="value"><%= detail.get("warranty_years") %></div></div>
                <div><div class="label">Wakil Sabah</div><div class="value"><%= detail.get("sabah_rep_name") %></div></div>
                <div><div class="label">Telefon Wakil Sabah</div><div class="value"><%= detail.get("sabah_rep_phone") %></div></div>
                <div class="full"><div class="label">Alamat Wakil Sabah</div><div class="value"><%= detail.get("sabah_rep_address") %></div></div>
            </div>
        </div>

        <div class="panel docs">
            <h3>Dokumen Lampiran</h3>
            <table>
                <thead>
                    <tr>
                        <th>Jenis Dokumen</th>
                        <th>Nama Fail</th>
                        <th>Saiz</th>
                        <th>Tindakan</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (documents == null || documents.isEmpty()) { %>
                    <tr><td colspan="4">Tiada dokumen dimuat naik.</td></tr>
                    <% } else { for (Map<String, Object> doc : documents) { %>
                    <tr>
                        <td><%= doc.get("document_type") %></td>
                        <td><%= doc.get("original_filename") %></td>
                        <td><%= doc.get("file_size") %> bytes</td>
                        <td><a href="${pageContext.request.contextPath}/documents/download?id=<%= doc.get("id") %>">Muat Turun</a></td>
                    </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>

        <div class="panel">
            <h3>Tindakan Pentadbir</h3>
            <%
                String adminError = request.getAttribute("error") == null ? null : String.valueOf(request.getAttribute("error"));
                if (adminError != null && !adminError.isBlank()) {
            %>
            <div class="alert-error"><%= adminError %></div>
            <% } %>
            <form method="post" action="${pageContext.request.contextPath}/admin/application" id="adminActionForm">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="id" value="<%= applicationData.get("id") %>">
                <div class="label">Sebab Penolakan / Nota Pentadbir (wajib jika Tolak)</div>
                <textarea name="admin_notes" id="adminNotes"><%= applicationData.get("admin_notes") != null ? applicationData.get("admin_notes") : "" %></textarea>
                <div class="actions">
                    <button class="btn approve" type="submit" name="action" value="approve">Luluskan</button>
                    <button class="btn reject" type="submit" name="action" value="reject" onclick="return validateRejectReason();">Tolak</button>
                    <button class="btn suspend" type="submit" name="action" value="suspend_application">Gantung Permohonan</button>
                    <button class="btn suspend" type="submit" name="action" value="suspend_user">Gantung Pengguna</button>
                    <a class="btn secondary" href="${pageContext.request.contextPath}/dashboard">Kembali</a>
                </div>
            </form>
        </div>

        <div class="panel">
            <h3>Hubungan Rasmi</h3>
            <div class="contact-card" aria-label="Maklumat hubungan Jabatan Air Sabah">
                <strong>Hubungi JANS</strong>
                <p>Telefon: 088-326888</p>
                <p>Email: info@jwater.gov.my</p>
                <p>Kota Kinabalu, Sabah</p>
            </div>
        </div>
    </div>
    <script>
        function validateRejectReason() {
            var notesField = document.getElementById('adminNotes');
            if (!notesField) {
                return true;
            }
            var reason = notesField.value == null ? '' : notesField.value.trim();
            if (reason.length === 0) {
                alert('Sila isi sebab penolakan sebelum menolak permohonan.');
                notesField.focus();
                return false;
            }
            return true;
        }
    </script>
</body>
</html>




