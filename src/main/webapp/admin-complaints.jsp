<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
<%!
    private static final String[] SECTION_E_QUESTIONS = new String[] {
            "Adakah Prosedur Operasi Standard (SOP) penghantaran dan pengendalian produk dari kilang ke tapak bina dipatuhi?",
            "Adakah produk memenuhi spesifikasi seperti dalam sijil pendaftaran produk yang berdaftar dengan JANS?",
            "Adakah Factory Acceptance Test (FAT) telah dijalankan?",
            "Adakah pemeriksaan produk dibuat sebelum pemasangan?",
            "Apakah tahap prestasi Perkhidmatan Selepas Jualan (After Sales Service)?",
            "Lain-lain perkara berkaitan (jika ada)"
    };

    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String formatComplaintDisplayId(Object idValue) {
        int id = 0;
        if (idValue instanceof Number) {
            id = ((Number) idValue).intValue();
        } else if (idValue != null) {
            try {
                id = Integer.parseInt(String.valueOf(idValue));
            } catch (NumberFormatException ignored) {
                id = 0;
            }
        }
        return String.format("A%04d", Math.max(0, id));
    }

    private String humanizeAnswer(String value) {
        if (value == null) {
            return "-";
        }
        String cleaned = value.trim();
        if (cleaned.isEmpty() || "-".equals(cleaned)) {
            return "-";
        }
        return cleaned.replace('_', ' ');
    }

    private String formatComplaintDetails(String rawDetails) {
        if (rawDetails == null || rawDetails.trim().isEmpty()) {
            return "-";
        }

        String normalized = rawDetails.replace("\r\n", "\n").replace('\r', '\n');
        int sectionStart = normalized.indexOf("===== BAHAGIAN E =====");
        String mainDetails = sectionStart >= 0 ? normalized.substring(0, sectionStart).trim() : normalized.trim();
        String sectionDetails = sectionStart >= 0 ? normalized.substring(sectionStart).trim() : "";

        StringBuilder out = new StringBuilder();
        if (!mainDetails.isEmpty()) {
            out.append("Butiran Aduan Utama:\n").append(mainDetails);
        }

        if (!sectionDetails.isEmpty()) {
            String[] lines = sectionDetails.split("\\n");
            String[] answers = new String[6];
            String[] notes = new String[6];
            String renewalRating = "-";
            String renewalReview = "-";

            for (String line : lines) {
                if (line == null) {
                    continue;
                }
                String trimmed = line.trim();
                if (trimmed.isEmpty() || trimmed.startsWith("===== BAHAGIAN E")) {
                    continue;
                }
                if (trimmed.startsWith("Q") && trimmed.contains(":")) {
                    int colonPos = trimmed.indexOf(':');
                    String qKey = trimmed.substring(1, colonPos).trim();
                    int qNum;
                    try {
                        qNum = Integer.parseInt(qKey);
                    } catch (NumberFormatException ex) {
                        qNum = -1;
                    }
                    if (qNum >= 1 && qNum <= 6) {
                        String remainder = trimmed.substring(colonPos + 1).trim();
                        String answerPart = remainder;
                        String notePart = "-";
                        int notePos = remainder.indexOf("| Catatan:");
                        if (notePos >= 0) {
                            answerPart = remainder.substring(0, notePos).trim();
                            notePart = remainder.substring(notePos + "| Catatan:".length()).trim();
                        }
                        answers[qNum - 1] = humanizeAnswer(answerPart);
                        notes[qNum - 1] = humanizeAnswer(notePart);
                    }
                    continue;
                }
                if (trimmed.startsWith("Penilaian Pembaharuan:")) {
                    String value = trimmed.substring("Penilaian Pembaharuan:".length()).trim();
                    renewalRating = humanizeAnswer(value);
                    continue;
                }
                if (trimmed.startsWith("Ulasan Pembaharuan:")) {
                    String value = trimmed.substring("Ulasan Pembaharuan:".length()).trim();
                    renewalReview = humanizeAnswer(value);
                }
            }

            if (out.length() > 0) {
                out.append("\n\n");
            }
            out.append("Bahagian E - Soalan dan Jawapan:");
            for (int i = 0; i < SECTION_E_QUESTIONS.length; i++) {
                out.append("\n").append(i + 1).append(". ").append(SECTION_E_QUESTIONS[i])
                        .append("\n   Jawapan: ").append(answers[i] == null ? "-" : answers[i])
                        .append("\n   Catatan: ").append(notes[i] == null ? "-" : notes[i]);
            }
            out.append("\n\nPenilaian Pembaharuan: ").append(renewalRating)
                    .append("\nUlasan Pembaharuan: ").append(renewalReview);
        }

        return out.toString();
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Senarai Aduan Diterima - Admin</title>
    <style>
:root {
            --brand-blue: #0f6bae;
            --brand-navy: #06344f;
            --surface: #ffffff;
            --line: #d9e7f1;
            --muted: #637d8d;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: inherit;
            background: linear-gradient(180deg, #f4fbff 0%, #f9fcfd 100%);
            color: #183244;
        }
        .topbar {
            background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 76%, #fff212 190%);
            color: #ffffff;
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
        }
        .topbar-brand {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .topbar-logo {
            width: 48px;
            height: 48px;
            object-fit: contain;
            border-radius: 10px;
            background: rgba(255, 255, 255, 0.15);
            padding: 4px;
        }
        .topbar h1 {
            margin: 0;
            font-size: 20px;
        }
        .topbar p {
            margin: 4px 0 0;
            font-size: 12px;
            opacity: 0.9;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border: 1px solid #ffffff;
            border-radius: 999px;
            text-decoration: none;
            font-weight: 700;
            padding: 9px 14px;
            background: rgba(255, 255, 255, 0.14);
            color: #ffffff;
        }
        .btn-icon {
            width: 42px;
            height: 42px;
            padding: 0;
            border-radius: 999px;
        }
        .btn-icon img {
            width: 22px;
            height: 22px;
            object-fit: contain;
        }
        .container {
            max-width: 1180px;
            margin: 20px auto;
            padding: 0 14px 28px;
        }
        .summary {
            margin-bottom: 12px;
            padding: 12px;
            border: 1px solid var(--line);
            border-radius: 12px;
            background: #ffffff;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .new-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 26px;
            height: 26px;
            padding: 0 8px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
            background: #ffe4e4;
            color: #b91c1c;
        }
        .complaint-list {
            list-style: none;
            margin: 0;
            padding: 0;
            display: grid;
            gap: 10px;
        }
        .complaint-item {
            border: 1px solid var(--line);
            border-radius: 12px;
            background: #ffffff;
            padding: 12px;
        }
        .complaint-head {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 10px;
        }
        .complaint-title {
            margin: 0;
            color: #0d4f80;
            font-size: 15px;
        }
        .complaint-meta {
            margin-top: 5px;
            color: #567183;
            font-size: 13px;
            line-height: 1.45;
        }
        .status-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            padding: 4px 10px;
        }
        .status-new { background: #dbeafe; color: #1e40af; }
        .status-under_review { background: #e0f2fe; color: #0369a1; }
        .status-in_progress { background: #ede9fe; color: #7c3aed; }
        .status-resolved { background: #dcfce7; color: #166534; }
        .urgency-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 800;
            padding: 4px 10px;
            margin-bottom: 6px;
        }
        .urgency-rendah { background: #e8f5e9; color: #166534; }
        .urgency-sederhana { background: #fff8e1; color: #8a5a00; }
        .urgency-tinggi { background: #ffebee; color: #b71c1c; }
        .urgency-kritikal { background: #4a0014; color: #ffffff; }
        .actions {
            margin-top: 8px;
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
        }
        .actions form { margin: 0; }
        .actions button {
            border: 1px solid #d4e4ef;
            border-radius: 8px;
            padding: 7px 10px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            background: #f0f7fd;
            color: #1f4f71;
        }
        .actions button.primary {
            background: #0f6bae;
            border-color: #0f6bae;
            color: #ffffff;
        }
        .actions button.semakan-btn {
            background: #0a7fbf;
            border-color: #0a7fbf;
            color: #ffffff;
        }
        .empty {
            margin: 0;
            border: 1px dashed #cdddea;
            border-radius: 12px;
            padding: 16px;
            background: #ffffff;
            color: var(--muted);
        }
        .complaint-modal {
            position: fixed;
            inset: 0;
            background: rgba(6, 25, 40, 0.52);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2000;
            padding: 14px;
        }
        .complaint-modal.show { display: flex; }
        .complaint-modal-card {
            width: min(900px, 100%);
            max-height: calc(100vh - 28px);
            overflow: auto;
            background: #ffffff;
            border-radius: 14px;
            border: 1px solid #d5e5f1;
            box-shadow: 0 24px 54px rgba(3, 30, 54, 0.28);
            padding: 14px;
        }
        .complaint-modal-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            margin-bottom: 8px;
        }
        .complaint-modal-head h3 {
            margin: 0;
            color: #0d4f80;
            font-size: 18px;
        }
        .complaint-modal-close {
            border: 1px solid #d3e2ee;
            background: #f4f9fd;
            color: #1f4f71;
            border-radius: 8px;
            padding: 7px 10px;
            font-weight: 700;
            cursor: pointer;
        }
        .complaint-modal-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 10px;
            margin-bottom: 10px;
        }
        .modal-field {
            border: 1px solid #deebf4;
            border-radius: 10px;
            background: #f9fcff;
            padding: 8px;
        }
        .modal-field strong {
            display: block;
            font-size: 12px;
            color: #4f6f83;
            margin-bottom: 3px;
            text-transform: uppercase;
        }
        .modal-field span {
            display: block;
            font-size: 14px;
            color: #15384e;
            white-space: pre-wrap;
            line-height: 1.5;
        }
        .modal-field.full { grid-column: 1 / -1; }
        @media (max-width: 860px) {
            .topbar { flex-direction: column; align-items: flex-start; }
            .complaint-modal-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="topbar">
        <div class="topbar-brand">
            <img src="${pageContext.request.contextPath}/icon/logo-jans-2025-main.png" class="topbar-logo" alt="Logo Jabatan Air Sabah">
            <div>
            <h1>ADUAN PEMBEKAL DAN PRODUK AIR</h1>
            <p>Paparan aduan yang dihantar melalui Portal Staff</p>
            </div>
        </div>
        <a class="btn btn-icon" href="${pageContext.request.contextPath}/dashboard" title="Kembali ke Dashboard" aria-label="Kembali ke Dashboard">
            <img src="${pageContext.request.contextPath}/icon/dashboard.png" alt="Kembali ke Dashboard">
        </a>
    </div>

    <div class="container">
        <%
            int newCount = request.getAttribute("staff_complaint_new_count") instanceof Number
                    ? ((Number) request.getAttribute("staff_complaint_new_count")).intValue() : 0;
            List<Map<String, Object>> staffComplaints = (List<Map<String, Object>>) request.getAttribute("staff_complaints");
        %>

        <div class="summary">
            <strong>Jumlah aduan baharu belum disemak</strong>
            <span class="new-badge"><%= newCount %> NEW</span>
        </div>

        <% if (staffComplaints == null || staffComplaints.isEmpty()) { %>
            <p class="empty">Belum ada aduan diterima setakat ini.</p>
        <% } else { %>
            <ul class="complaint-list">
                <% for (Map<String, Object> complaint : staffComplaints) {
                    String statusRaw = String.valueOf(complaint.get("status") == null ? "NEW" : complaint.get("status"));
                    String status = statusRaw.trim().toUpperCase(java.util.Locale.ROOT);
                    String statusClass = status.toLowerCase(java.util.Locale.ROOT);
                    String urgency = String.valueOf(complaint.get("urgency") == null ? "-" : complaint.get("urgency"));
                    String urgencyKey = urgency.trim().toUpperCase(java.util.Locale.ROOT);
                    String urgencyClass = "urgency-sederhana";
                    if ("RENDAH".equals(urgencyKey)) {
                        urgencyClass = "urgency-rendah";
                    } else if ("TINGGI".equals(urgencyKey)) {
                        urgencyClass = "urgency-tinggi";
                    } else if ("KRITIKAL".equals(urgencyKey)) {
                        urgencyClass = "urgency-kritikal";
                    }
                    Timestamp createdAt = (Timestamp) complaint.get("created_at");
                    String details = String.valueOf(complaint.get("complaint_details") == null ? "" : complaint.get("complaint_details"));
                    String complaintDisplayId = formatComplaintDisplayId(complaint.get("id"));
                    String formattedDetails = formatComplaintDetails(details);
                %>
                <li class="complaint-item">
                    <div class="complaint-head">
                        <div>
                            <p class="complaint-title"><%= escapeHtml(complaintDisplayId) %> - <%= escapeHtml(String.valueOf(complaint.get("complaint_title"))) %></p>
                            <div class="complaint-meta">
                                Staff: <%= escapeHtml(String.valueOf(complaint.get("staff_username"))) %> (<%= escapeHtml(String.valueOf(complaint.get("staff_email"))) %>)<br>
                                Jabatan: <%= escapeHtml(String.valueOf(complaint.get("department"))) %> | Kategori: <%= escapeHtml(String.valueOf(complaint.get("complaint_category"))) %><br>
                                Dihantar: <%= createdAt == null ? "-" : escapeHtml(String.valueOf(createdAt)) %>
                            </div>
                        </div>
                        <div style="text-align:right; min-width:130px;">
                            <span class="urgency-pill <%= urgencyClass %>"><%= escapeHtml(urgencyKey) %></span><br>
                            <span class="status-pill status-<%= statusClass %>"><%= escapeHtml(status) %></span>
                        </div>
                    </div>

                    <div class="actions">
                        <button
                            type="button"
                            class="semakan-btn js-open-complaint"
                            data-id="<%= escapeHtml(complaintDisplayId) %>"
                            data-title="<%= escapeHtml(String.valueOf(complaint.get("complaint_title"))) %>"
                            data-staff="<%= escapeHtml(String.valueOf(complaint.get("staff_username"))) %>"
                            data-email="<%= escapeHtml(String.valueOf(complaint.get("staff_email"))) %>"
                            data-department="<%= escapeHtml(String.valueOf(complaint.get("department"))) %>"
                            data-category="<%= escapeHtml(String.valueOf(complaint.get("complaint_category"))) %>"
                            data-urgency="<%= escapeHtml(urgencyKey) %>"
                            data-status="<%= escapeHtml(status) %>"
                            data-submitted="<%= createdAt == null ? "-" : escapeHtml(String.valueOf(createdAt)) %>"
                            data-details="<%= escapeHtml(formattedDetails) %>">Semak Aduan</button>

                        <% if ("NEW".equals(status)) { %>
                        <form method="post" action="${pageContext.request.contextPath}/dashboard?aduan_view=1">
                            <input type="hidden" name="_csrf" value="${csrf_token}">
                            <input type="hidden" name="staff_complaint_action" value="set_status">
                            <input type="hidden" name="staff_complaint_id" value="<%= complaint.get("id") %>">
                            <input type="hidden" name="next_status" value="UNDER_REVIEW">
                            <button type="submit">Tandakan Semakan</button>
                        </form>
                        <% } %>
                        <% if (!"IN_PROGRESS".equals(status) && !"RESOLVED".equals(status)) { %>
                        <form method="post" action="${pageContext.request.contextPath}/dashboard?aduan_view=1">
                            <input type="hidden" name="_csrf" value="${csrf_token}">
                            <input type="hidden" name="staff_complaint_action" value="set_status">
                            <input type="hidden" name="staff_complaint_id" value="<%= complaint.get("id") %>">
                            <input type="hidden" name="next_status" value="IN_PROGRESS">
                            <button type="submit">Tandakan Proses</button>
                        </form>
                        <% } %>
                        <% if (!"RESOLVED".equals(status)) { %>
                        <form method="post" action="${pageContext.request.contextPath}/dashboard?aduan_view=1">
                            <input type="hidden" name="_csrf" value="${csrf_token}">
                            <input type="hidden" name="staff_complaint_action" value="set_status">
                            <input type="hidden" name="staff_complaint_id" value="<%= complaint.get("id") %>">
                            <input type="hidden" name="next_status" value="RESOLVED">
                            <button class="primary" type="submit">Tandakan Selesai</button>
                        </form>
                        <% } %>
                    </div>
                </li>
                <% } %>
            </ul>
        <% } %>
    </div>

    <div class="complaint-modal" id="complaintModal" aria-hidden="true">
        <div class="complaint-modal-card" role="dialog" aria-modal="true" aria-labelledby="complaintModalTitle">
            <div class="complaint-modal-head">
                <h3 id="complaintModalTitle">Borang Aduan Penuh</h3>
                <button type="button" class="complaint-modal-close" id="complaintModalClose">Tutup</button>
            </div>
            <div class="complaint-modal-grid">
                <div class="modal-field"><strong>ID Aduan</strong><span id="modalComplaintId">-</span></div>
                <div class="modal-field"><strong>Tajuk</strong><span id="modalComplaintTitle">-</span></div>
                <div class="modal-field"><strong>Staff</strong><span id="modalComplaintStaff">-</span></div>
                <div class="modal-field"><strong>E-mel</strong><span id="modalComplaintEmail">-</span></div>
                <div class="modal-field"><strong>Jabatan</strong><span id="modalComplaintDepartment">-</span></div>
                <div class="modal-field"><strong>Kategori</strong><span id="modalComplaintCategory">-</span></div>
                <div class="modal-field"><strong>Keutamaan</strong><span id="modalComplaintUrgency">-</span></div>
                <div class="modal-field"><strong>Status Semasa</strong><span id="modalComplaintStatus">-</span></div>
                <div class="modal-field full"><strong>Tarikh Dihantar</strong><span id="modalComplaintSubmitted">-</span></div>
                <div class="modal-field full"><strong>Butiran Aduan Penuh</strong><span id="modalComplaintDetails">-</span></div>
            </div>
        </div>
    </div>

    <script>
        (function () {
            var modal = document.getElementById('complaintModal');
            var closeBtn = document.getElementById('complaintModalClose');
            var openButtons = Array.prototype.slice.call(document.querySelectorAll('.js-open-complaint'));

            var modalFields = {
                id: document.getElementById('modalComplaintId'),
                title: document.getElementById('modalComplaintTitle'),
                staff: document.getElementById('modalComplaintStaff'),
                email: document.getElementById('modalComplaintEmail'),
                department: document.getElementById('modalComplaintDepartment'),
                category: document.getElementById('modalComplaintCategory'),
                urgency: document.getElementById('modalComplaintUrgency'),
                status: document.getElementById('modalComplaintStatus'),
                submitted: document.getElementById('modalComplaintSubmitted'),
                details: document.getElementById('modalComplaintDetails')
            };

            function closeModal() {
                if (!modal) {
                    return;
                }
                modal.classList.remove('show');
                modal.setAttribute('aria-hidden', 'true');
            }

            function openModal(button) {
                if (!modal || !button) {
                    return;
                }
                modalFields.id.textContent = button.getAttribute('data-id') || '-';
                modalFields.title.textContent = button.getAttribute('data-title') || '-';
                modalFields.staff.textContent = button.getAttribute('data-staff') || '-';
                modalFields.email.textContent = button.getAttribute('data-email') || '-';
                modalFields.department.textContent = button.getAttribute('data-department') || '-';
                modalFields.category.textContent = button.getAttribute('data-category') || '-';
                modalFields.urgency.textContent = button.getAttribute('data-urgency') || '-';
                modalFields.status.textContent = button.getAttribute('data-status') || '-';
                modalFields.submitted.textContent = button.getAttribute('data-submitted') || '-';
                modalFields.details.textContent = button.getAttribute('data-details') || '-';
                modal.classList.add('show');
                modal.setAttribute('aria-hidden', 'false');
            }

            openButtons.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    openModal(btn);
                });
            });

            if (closeBtn) {
                closeBtn.addEventListener('click', closeModal);
            }

            if (modal) {
                modal.addEventListener('click', function (event) {
                    if (event.target === modal) {
                        closeModal();
                    }
                });
            }

            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape') {
                    closeModal();
                }
            });
        })();
    </script>
</body>
</html>
