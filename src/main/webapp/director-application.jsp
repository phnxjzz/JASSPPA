<%-- NOTA ALIRAN KOD: Fail director-application.jsp. Halaman ini biasa dipanggil terus melalui UI atau navigation ke /director-application.jsp. Tujuan nota ni supaya orang seterusnya terus nampak konteks fail ni. --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.Timestamp" %>
<%!
    private String esc(Object value) {
        if (value == null) return "";
        String text = String.valueOf(value);
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String formatDateTimeValue(Object value) {
        if (value instanceof java.sql.Timestamp) {
            java.time.LocalDateTime dateTime = ((java.sql.Timestamp) value).toLocalDateTime();
            return dateTime.format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm:ss"));
        }
        if (value instanceof java.sql.Date) {
            java.time.LocalDate date = ((java.sql.Date) value).toLocalDate();
            return date.format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
        }
        if (value != null) {
            return esc(value);
        }
        return "-";
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tindakan Pengarah - SPPA</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <style>
        body { margin: 0; font-family: inherit; background: #f3f4f6; color: #1f2937; }
        .navbar { display: flex; justify-content: space-between; align-items: center; padding: 18px 24px; background: #0f6bae; color: white; }
        .navbar a { color: white; text-decoration: none; }
        .nav-icon-link {
            width: 54px;
            height: 54px;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border: 2px solid #0b3f72;
            background: #0f4f8f;
            color: #ffffff;
            text-decoration: none;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22);
            transition: background 0.18s ease;
        }
        .nav-icon-link:hover { background: #1263b5; }
        .nav-icon-svg {
            width: 30px;
            height: 30px;
            display: block;
            color: #ffffff;
        }
        .container { max-width: 1080px; margin: 24px auto; padding: 0 16px; }
        .panel { background: #ffffff; border-radius: 16px; box-shadow: 0 18px 50px rgba(15, 23, 42, 0.08); padding: 24px; }
        .section { margin-bottom: 24px; }
        .section h2 { margin: 0 0 12px; font-size: 20px; color: #0f172a; }
        .grid { display: grid; gap: 16px; grid-template-columns: repeat(2, minmax(0, 1fr)); }
        .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px; }
        .label { display: block; font-size: 12px; font-weight: 700; text-transform: uppercase; color: #475569; margin-bottom: 6px; }
        .value { font-size: 15px; color: #0f172a; white-space: pre-wrap; }
        .actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 8px; }
        .btn { border: none; border-radius: 999px; padding: 12px 20px; cursor: pointer; font-weight: 700; color: white; }
        .btn-approve { background: #15803d; }
        .btn-reject { background: #b91c1c; }
        .btn-suspend { background: #f59e0b; }
        .btn-cancel { background: #475569; }
        .notice { border-radius: 12px; padding: 16px; margin-bottom: 18px; }
        .notice-success { background: #ecfdf5; color: #166534; border: 1px solid #a7f3d0; }
        .notice-error { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
        textarea { width: 100%; min-height: 120px; padding: 12px; border: 1px solid #cbd5e1; border-radius: 12px; resize: vertical; }
        .footer { font-size: 13px; color: #475569; margin-top: 20px; }
        .top-links { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 16px; }
    </style>
</head>
<body>
    <div class="navbar">
        <div>
            <strong>Sistem Pendaftaran Pembekal dan Bekalan Produk Air</strong>
            <div>Modul Pengarah</div>
        </div>
        <div class="top-links">
            <a class="nav-icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar">
                <svg class="nav-icon-svg" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                    <path d="M10 5H5v14h5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M13 12h8" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 8l4 4-4 4" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
            </a>
        </div>
    </div>
    <div class="container">
        <div class="panel">
            <% if (request.getAttribute("director_error") != null) { %>
            <div class="notice notice-error"><%= esc(request.getAttribute("director_error")) %></div>
            <% } else if (request.getParameter("director_error") != null) { %>
            <div class="notice notice-error"><%= esc(request.getParameter("director_error")) %></div>
            <% } %>
            <% if (request.getParameter("director_updated") != null) {
                    String directorResult = request.getParameter("director_result");
                    String successMessage = "Keputusan Pengarah berjaya disimpan.";
                    if ("initial_accepted".equalsIgnoreCase(directorResult)) {
                        String appId = (request.getAttribute("application") != null)
                            ? String.valueOf(((java.util.Map<?,?>)request.getAttribute("application")).get("id")) : "";
                        successMessage = "Permohonan diterima. ID Permohonan: PPP"
                            + String.format("%03d", Integer.parseInt(appId.isBlank() ? "0" : appId))
                            + ". Permohonan telah dihantar ke Dashboard Admin untuk semakan.";
                    } else if ("initial_rejected".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan telah ditolak. Pemohon akan dimaklumkan melalui emel.";
                    } else if ("initial_suspended".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan telah digantung. Pemohon akan dimaklumkan melalui emel.";
                    } else if ("initial_cancelled".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan telah dibatalkan. Pemohon akan dimaklumkan melalui emel.";
                    } else if ("final_approved".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan diluluskan (Keputusan Akhir). Permohonan telah dikembalikan ke Dashboard Admin untuk pengeluaran sijil.";
                    } else if ("final_rejected".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan telah ditolak (Keputusan Akhir). Pemohon akan dimaklumkan.";
                    } else if ("final_suspended".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan telah digantung (Keputusan Akhir). Pemohon akan dimaklumkan.";
                    } else if ("final_cancelled".equalsIgnoreCase(directorResult)) {
                        successMessage = "Permohonan telah dibatalkan (Keputusan Akhir). Pemohon akan dimaklumkan.";
                    }
            %>
            <div class="notice notice-success"><%= esc(successMessage) %></div>
            <% } %>

            <section class="section">
                <h2>Permohonan Sedia Untuk Tindakan</h2>
                <%
                    @SuppressWarnings("unchecked")
                    Map<String, Object> applicationData = (Map<String, Object>) request.getAttribute("application");
                    String reviewType = String.valueOf(request.getAttribute("director_review_type"));
                    boolean isFinalReview = "FINAL".equalsIgnoreCase(reviewType);
                    String reviewLabel = isFinalReview ? "Keputusan Akhir" : "Semakan Awal";
                %>
                <p style="font-size:13px;color:#475569;">Mod semakan: <strong><%= esc(reviewLabel) %></strong></p>
                <div class="grid">
                    <div class="card">
                        <span class="label">Status Semasa</span>
                        <div class="value"><%= esc(applicationData.get("status")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Tarikh Hantar</span>
                        <div class="value"><%= formatDateTimeValue(applicationData.get("submitted_at")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Tarikh Semakan</span>
                        <div class="value"><%= formatDateTimeValue(applicationData.get("reviewed_at")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Jenis Permohonan</span>
                        <div class="value"><%= esc(applicationData.get("application_type")) %></div>
                    </div>
                </div>
            </section>

            <section class="section">
                <h2>Maklumat Pemohon</h2>
                <div class="grid">
                    <div class="card">
                        <span class="label">Nama Pemohon</span>
                        <div class="value"><%= esc(applicationData.get("user_full_name")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Email Pemohon</span>
                        <div class="value"><%= esc(applicationData.get("user_email")) %></div>
                    </div>
                    <div class="card full">
                        <span class="label">Syarikat</span>
                        <div class="value"><strong><%= esc(applicationData.get("company_name")) %></strong><br><%= esc(applicationData.get("company_address")) %></div>
                    </div>
                </div>
            </section>

            <section class="section">
                <h2>Maklumat Produk</h2>
                <div class="grid">
                    <div class="card">
                        <span class="label">Produk</span>
                        <div class="value"><%= esc(applicationData.get("product_name")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Kategori</span>
                        <div class="value"><%= esc(applicationData.get("product_category")) %></div>
                    </div>
                    <div class="card full">
                        <span class="label">Butiran Produk</span>
                        <div class="value"><%= esc(applicationData.get("product_description")) %></div>
                    </div>
                </div>
            </section>

            <section class="section">
                <h2>Maklumat Sokongan</h2>
                <div class="grid">
                    <div class="card">
                        <span class="label">Pembekal</span>
                        <div class="value"><%= esc(applicationData.get("supplier_name")) %><br><%= esc(applicationData.get("supplier_phone")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Pengilang</span>
                        <div class="value"><%= esc(applicationData.get("manufacturer_name")) %><br><%= esc(applicationData.get("manufacturer_phone")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Prinsipal</span>
                        <div class="value"><%= esc(applicationData.get("principal_name")) %><br><%= esc(applicationData.get("principal_phone")) %></div>
                    </div>
                </div>
            </section>

            <section class="section">
                <h2>Sijil & Dokumen</h2>
                <div class="grid">
                    <div class="card">
                        <span class="label">Standard</span>
                        <div class="value"><%= esc(applicationData.get("standard_name")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">No. Sijil</span>
                        <div class="value"><%= esc(applicationData.get("certification_license")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Sijil Sah Hingga</span>
                        <div class="value"><%= formatDateTimeValue(applicationData.get("certification_valid_until")) %></div>
                    </div>
                    <div class="card full">
                        <span class="label">Rujukan Laporan Ujian</span>
                        <div class="value"><%= esc(applicationData.get("test_report_reference")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Tarikh Laporan Jualan</span>
                        <div class="value"><%= formatDateTimeValue(applicationData.get("test_report_date")) %></div>
                    </div>
                    <div class="card">
                        <span class="label">Tempoh Waranti</span>
                        <div class="value"><%= esc(applicationData.get("warranty_years")) %></div>
                    </div>
                </div>
            </section>

            <section class="section">
                <h2>Ulasan / Sebab Keputusan</h2>
                <form id="directorActionForm" method="post" action="${pageContext.request.contextPath}/director/application">
                    <input type="hidden" name="_csrf" value="${csrf_token}">
                    <input type="hidden" name="application_id" value="<%= esc(applicationData.get("id")) %>">
                    <div class="card full">
                        <span class="label">Ulasan Untuk Gagal / Gantung / Batal</span>
                        <textarea name="director_notes" id="director_notes" placeholder="Masukkan alasan jika memilih Gagal, Gantung atau Batal"></textarea>
                    </div>
                    <div class="actions">
                        <% if (isFinalReview) { %>
                        <button type="submit" class="btn btn-approve" name="director_action" value="accept_application">Lulus</button>
                        <% } else { %>
                        <button type="submit" class="btn btn-approve" name="director_action" value="accept_application">Terima</button>
                        <% } %>
                        <button type="submit" class="btn btn-reject" name="director_action" value="reject_application">Tolak</button>
                        <button type="submit" class="btn btn-suspend" name="director_action" value="suspend_application">Gantung</button>
                        <button type="submit" class="btn btn-cancel" name="director_action" value="cancel_application">Batal</button>
                    </div>
                </form>
            </section>

            <div class="footer">
                <p>Pengarah boleh mengubah keputusan dengan segera selepas membuka pautan permohonan.</p>
            </div>
        </div>
    </div>
    <script>
        document.getElementById('directorActionForm').addEventListener('submit', function (event) {
            var action = document.activeElement.value;
            var notes = document.getElementById('director_notes').value.trim();
            if ((action === 'reject_application' || action === 'suspend_application' || action === 'cancel_application') && !notes) {
                event.preventDefault();
                alert('Sila masukkan sebab keputusan sebelum menghantar.');
            }
        });

        (function () {
            var successNotice = document.querySelector('.notice-success');
            if (!successNotice) {
                return;
            }
            var message = (successNotice.textContent || '').trim();
            if (!message) {
                return;
            }

            var popup = document.createElement('div');
            popup.setAttribute('role', 'status');
            popup.setAttribute('aria-live', 'polite');
            popup.style.position = 'fixed';
            popup.style.top = '20px';
            popup.style.right = '20px';
            popup.style.zIndex = '9999';
            popup.style.maxWidth = '360px';
            popup.style.padding = '14px 16px';
            popup.style.borderRadius = '12px';
            popup.style.border = '1px solid #a7f3d0';
            popup.style.background = '#ecfdf5';
            popup.style.color = '#065f46';
            popup.style.boxShadow = '0 12px 28px rgba(6, 95, 70, 0.18)';
            popup.style.fontSize = '14px';
            popup.style.lineHeight = '1.5';
            popup.innerHTML = '<strong style="display:block;margin-bottom:4px;">Berjaya!</strong>'
                + '<span>' + message.replace(/</g, '&lt;').replace(/>/g, '&gt;') + '</span>';

            document.body.appendChild(popup);
            setTimeout(function () {
                if (popup && popup.parentNode) {
                    popup.parentNode.removeChild(popup);
                }
            }, 3200);
        })();
    </script>
</body>
</html>

