<%-- NOTA ALIRAN KOD: Fail admin-application.jsp. Halaman ini biasa dipanggil terus melalui UI atau navigation ke /admin-application.jsp. Tujuan nota ni supaya orang seterusnya terus nampak konteks fail ni. --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.Timestamp" %>
<%@ page import="com.sistemppa.service.StatusConfigService" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String formatDateValue(Object value) {
        java.time.LocalDate date = null;
        if (value instanceof java.sql.Timestamp) {
            date = ((java.sql.Timestamp) value).toLocalDateTime().toLocalDate();
        } else if (value instanceof java.sql.Date) {
            date = ((java.sql.Date) value).toLocalDate();
        } else if (value != null) {
            String raw = String.valueOf(value).trim();
            if (!raw.isEmpty() && !"-".equals(raw)) {
                String normalized = raw.replace('T', ' ');
                try {
                    if (normalized.length() >= 10) {
                        date = java.time.LocalDate.parse(normalized.substring(0, 10));
                    }
                } catch (Exception ignored) {
                    date = null;
                }
            }
        }
        if (date == null) {
            return "-";
        }
        return date.format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
    }

    private String formatDateTimeValue(Object value) {
        java.time.LocalDateTime dateTime = null;
        if (value instanceof java.sql.Timestamp) {
            dateTime = ((java.sql.Timestamp) value).toLocalDateTime();
        } else if (value instanceof java.sql.Date) {
            dateTime = ((java.sql.Date) value).toLocalDate().atStartOfDay();
        } else if (value != null) {
            String raw = String.valueOf(value).trim();
            if (!raw.isEmpty() && !"-".equals(raw)) {
                String normalized = raw.replace('T', ' ');
                try {
                    if (normalized.length() >= 19) {
                        dateTime = java.time.LocalDateTime.parse(
                                normalized.substring(0, 19),
                                java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                    } else if (normalized.length() >= 10) {
                        dateTime = java.time.LocalDate.parse(normalized.substring(0, 10)).atStartOfDay();
                    }
                } catch (Exception ignored) {
                    dateTime = null;
                }
            }
        }
        if (dateTime == null) {
            return "-";
        }
        return dateTime.format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm:ss"));
    }

    private String displayStatusLabel(String status) {
        return displayStatusLabel(status, null);
    }

    private String displayStatusLabel(String status, Map<String, String> labelMap) {
        if (status == null) {
            return "";
        }
        String normalized = status.trim().toUpperCase(java.util.Locale.ROOT);
        if (labelMap != null) {
            String fromDb = labelMap.get(normalized);
            if (fromDb != null && !fromDb.isBlank()) {
                return fromDb.replace('_', ' ').trim();
            }
        }
        if ("APPROVED".equals(normalized) || "DILULUSKAN".equals(normalized)) {
            return "DILULUSKAN";
        }
        if ("REJECTED".equals(normalized) || "DITOLAK".equals(normalized)) {
            return "DITOLAK";
        }
        if ("KUERI".equals(normalized)) {
            return "KUERI";
        }
        if ("SUSPENDED".equals(normalized) || "DIGANTUNG".equals(normalized)) {
            return "DIGANTUNG";
        }
        if ("DRAFT".equals(normalized) || "DRAF".equals(normalized)) {
            return "DRAF";
        }
        if ("ARCHIVED".equals(normalized) || "DIARKIB".equals(normalized)) {
            return "DIARKIB";
        }
        if ("UNDER_REVIEW".equals(normalized) || "DALAM_SEMAKAN".equals(normalized) || "DALAM SEMAKAN".equals(normalized)) {
            return "DALAM SEMAKAN";
        }
        if ("MENUNGGU_TINDAKAN_PENGARAH".equals(normalized)) {
            return "MENUNGGU TINDAKAN PENGARAH";
        }
        if (normalized.startsWith("MENUNGGU_SETERUSNYA_")) {
            return "MENUNGGU SETERUSNYA";
        }
        if ("IN_PROGRESS".equals(normalized) || "DALAM_PROSES".equals(normalized) || "DALAM PROSES".equals(normalized)) {
            return "DALAM PROSES";
        }
        return normalized.replace('_', ' ');
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Semakan Permohonan - SPPPBA</title>
    <style>
* { box-sizing: border-box; }
        body { font-family: inherit; background: linear-gradient(180deg, #eff8ff 0%, #f7fbfd 100%); margin: 0; color: #1e293b; }
        .navbar { background: linear-gradient(130deg, #0F6BAE 0%, #2A9D8F 30%, #6DBE45 58%, #CDE11D 80%, #F2F72E 100%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 48px; height: 48px; border-radius: 14px; object-fit: contain; padding: 3px; }
        .brand strong { display: block; }
        .brand span { font-size: 12px; opacity: 0.88; }
        .navbar a { color: white; text-decoration: none; margin-left: 16px; }
        .container { max-width: 1200px; margin: 28px auto; padding: 0 20px; }
        .panel { border-radius: 12px; box-shadow: 0 10px 30px rgba(15, 23, 42, 0.08); padding: 24px; margin-bottom: 20px; background: #fff7bf; border: 1px solid #ecd86b; }
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
        .final-action { background: #d97706; }
        .next-step { background: #ea580c; }
        .under-review { background: #0369a1; }
        .in-progress { background: #7c3aed; }
        .secondary { background: #475569; text-decoration: none; display: inline-block; }
        .status { font-weight: 700; }
        .alert-error { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; border-radius: 10px; padding: 12px; margin-bottom: 14px; }
        .contact-card { width: 100%; max-width: 420px; border-radius: 12px; border: 1px solid #e2e8f0; background: #f8fbff; padding: 14px; color: #475569; }
        .contact-card strong { display: block; margin-bottom: 8px; color: #0f172a; }
        .contact-card p { margin: 4px 0; }
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; }
        .jans-contact-section .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; min-width: 0; }
        .jans-contact-section .contact-icon { width: 12px; height: 12px; display: inline-flex; align-items: center; justify-content: center; font-size: 11px; line-height: 1; color: #0f6bae; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-line-hanging { margin-left: 21px; }
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
        .icon-inline { width: 20px; height: 20px; display: inline-flex; align-items: center; justify-content: center; font-size: 18px; line-height: 1; vertical-align: middle; }
        .icon-link { width: 54px; height: 54px; display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; background: #0f4f8f; border: 2px solid #0b3f72; transition: transform 0.18s ease, background 0.18s ease; text-decoration: none; margin-left: 4px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22); }
        .icon-link .icon-glyph { width: 30px; height: 30px; display: inline-flex; align-items: center; justify-content: center; font-family: "Segoe UI Symbol", "Noto Sans Symbols 2", sans-serif; font-size: 30px; font-weight: 700; line-height: 1; color: #ffffff; text-shadow: none; }
        .icon-link:hover { transform: translateY(-1px) scale(1.03); background: #1263b5; }
        .doc-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .doc-actions .btn {
            padding: 8px 12px;
            font-size: 12px;
            text-decoration: none;
            border-radius: 8px;
            min-width: 44px;
            display: inline-flex;
            align-items: center;
            gap: 0;
            justify-content: center;
            transition: transform 0.18s ease, box-shadow 0.18s ease, filter 0.18s ease;
        }
        .doc-actions .btn .icon-inline,
        #documentDownloadBtn .icon-inline {
            width: 20px;
            height: 20px;
        }
        .btn-preview { background: #0f6bae; }
        .btn-download { background: #00a2ff; }
        .btn-preview:hover,
        .btn-download:hover,
        #documentDownloadBtn:hover,
        .btn-preview:focus,
        .btn-download:focus,
        #documentDownloadBtn:focus {
            transform: translateY(-3px);
            box-shadow: 0 8px 18px rgba(15, 107, 174, 0.38) !important;
            filter: brightness(1.06);
        }
        .doc-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(2, 6, 23, 0.65);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1200;
            padding: 16px;
        }
        .doc-modal-overlay.open { display: flex; }
        .doc-modal-card {
            width: min(1040px, 100%);
            max-height: calc(100vh - 32px);
            background: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 24px 64px rgba(15, 23, 42, 0.34);
            display: flex;
            flex-direction: column;
        }
        .doc-modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            background: #0f6bae;
            color: #ffffff;
        }
        .doc-modal-header h4 {
            margin: 0;
            font-size: 15px;
        }
        .doc-modal-body {
            padding: 0;
            background: #f8fafc;
            min-height: 360px;
            flex: 1;
            overflow: auto;
        }
        .doc-viewer {
            min-height: 360px;
            height: 70vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #e2e8f0;
        }
        .doc-viewer iframe,
        .doc-viewer img {
            width: 100%;
            height: 100%;
            border: none;
            display: block;
            background: #ffffff;
        }
        .doc-viewer img {
            object-fit: contain;
        }
        .doc-viewer-empty {
            padding: 20px;
            color: #334155;
            text-align: center;
        }
        .doc-modal-footer {
            padding: 12px 14px;
            border-top: 1px solid #dbe3ee;
            display: flex;
            gap: 8px;
            justify-content: flex-end;
            background: #ffffff;
        }
        .inprogress-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(2, 6, 23, 0.62);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1250;
            padding: 16px;
        }
        .inprogress-modal-overlay.open { display: flex; }
        .inprogress-modal-card {
            width: min(760px, 100%);
            max-height: calc(100vh - 32px);
            overflow: auto;
            border-radius: 12px;
            background: #ffffff;
            border: 1px solid #d8e5ef;
            box-shadow: 0 24px 56px rgba(15, 23, 42, 0.34);
            padding: 18px;
        }
        .inprogress-modal-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            margin-bottom: 10px;
        }
        .inprogress-modal-head h4 {
            margin: 0;
            color: #0f6bae;
            font-size: 18px;
        }
        .inprogress-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 10px;
            margin-bottom: 12px;
        }
        .inprogress-field label {
            display: block;
            font-size: 12px;
            color: #64748b;
            margin-bottom: 4px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .inprogress-field input:not([type="checkbox"]):not([type="radio"]),
        .inprogress-field textarea {
            width: 100%;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            padding: 10px;
            font: inherit;
        }
        .inprogress-field textarea {
            min-height: 140px;
            resize: vertical;
        }
        .inprogress-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 12px;
        }
        @media (max-width: 760px) {
            .inprogress-grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 760px) {
            .doc-viewer { height: 55vh; }
            .doc-actions .btn { min-width: 84px; }
        }
        .audit-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 9px; }
        .audit-item { border: 1px solid #d8e5ef; border-radius: 10px; background: #f8fbff; padding: 10px 12px; }
        .audit-item strong { display: block; color: #0f3f61; font-size: 13px; margin-bottom: 3px; }
        .audit-item p { margin: 0; color: #486376; font-size: 12px; line-height: 1.4; }
        .audit-meta { margin-top: 6px; display: flex; justify-content: space-between; gap: 8px; color: #708798; font-size: 11px; }
        .audit-panel-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 8px; }
        .audit-toggle-btn { width: 34px; height: 34px; border: 1px solid #c9dcea; border-radius: 8px; background: #f7fbff; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; padding: 0; }
        .audit-toggle-btn img { width: 18px; height: 18px; object-fit: contain; }
        .audit-content.is-hidden { display: none; }

        .decision-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(2, 6, 23, 0.62);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1300;
            padding: 16px;
        }
        .decision-modal-overlay.open { display: flex; }
        .decision-modal-card {
            width: min(420px, 100%);
            border-radius: 14px;
            background: #ffffff;
            border: 1px solid #d8e5ef;
            box-shadow: 0 24px 56px rgba(15, 23, 42, 0.34);
            padding: 18px;
            text-align: center;
        }
        .decision-modal-card h4 {
            margin: 0 0 8px;
            color: #0f3f61;
            font-size: 22px;
            font-weight: 800;
        }
        .decision-modal-card p {
            margin: 0;
            color: #4e6a7c;
            font-size: 14px;
            line-height: 1.45;
        }
        .decision-gif {
            width: 92px;
            height: 92px;
            display: none;
            align-items: center;
            justify-content: center;
            font-size: 70px;
            line-height: 1;
            color: #15803d;
            margin: 8px auto 12px;
        }
        .decision-gif.show { display: inline-flex; }
        .decision-actions {
            margin-top: 14px;
            display: flex;
            justify-content: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .decision-confirm-gif {
            width: 92px;
            height: 92px;
            margin: 6px auto 10px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 70px;
            line-height: 1;
            color: #0f6bae;
        }
        .action-toolbar-sticky {
            position: sticky;
            top: 10px;
            z-index: 1100;
            background: #fff7bf;
            border: 1px solid #ecd86b;
            border-radius: 10px;
            padding: 10px;
            margin-bottom: 12px;
            box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12);
        }
        .action-toolbar-sticky .actions {
            margin-top: 0;
        }
        .top-action-wrapper {
            margin-bottom: 16px;
        }
    </style>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <strong>SPPPBA - Semakan Permohonan</strong>
                <span>Jabatan Air Negeri Sabah</span>
            </div>
        </div>
        <div>
            <a class="icon-link" href="${pageContext.request.contextPath}/dashboard" title="
             Dashboard" aria-label="Kembali ke Dashboard"><span class="icon-glyph" aria-hidden="true">&#9638;</span></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><svg class="icon-glyph" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M3 10.5L12 3l9 7.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M5.5 9.5V21h13V9.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><svg class="icon-glyph" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M10 5H5v14h5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M13 12h8" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 8l4 4-4 4" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg></a>
        </div>
    </div>

    <div class="container">
        <%
            Map<String, Object> applicationData = (Map<String, Object>) request.getAttribute("application");
            Map<String, Object> detail = (Map<String, Object>) request.getAttribute("applicationDetail");
            List<Map<String, Object>> documents = (List<Map<String, Object>>) request.getAttribute("documents");
            List<Map<String, Object>> adminAuditLogs = (List<Map<String, Object>>) request.getAttribute("admin_audit_logs");
            List<Map<String, Object>> kppUsers = (List<Map<String, Object>>) request.getAttribute("kpp_users");
            Map<String, Object> latestPresentationInvite = (Map<String, Object>) request.getAttribute("latest_presentation_invite");
            @SuppressWarnings("unchecked")
            Map<String, String> statusLabelMap = (Map<String, String>) request.getAttribute("status_label_map");
            String adminError = request.getAttribute("error") == null ? null : String.valueOf(request.getAttribute("error"));
            String currentStatusValue = applicationData.get("status") == null ? "" : String.valueOf(applicationData.get("status"));
            String normalizedCurrentStatusValue = currentStatusValue.trim().toUpperCase(java.util.Locale.ROOT).replace(' ', '_').replace('-', '_');
            boolean showNextStepButton = normalizedCurrentStatusValue.startsWith("MENUNGGU_SETERUSNYA_");
            boolean isWaitingForDirector = "MENUNGGU_TINDAKAN_PENGARAH".equals(normalizedCurrentStatusValue);
            boolean isDirectorApprovedStage = "DILULUSKAN_PENGARAH".equals(normalizedCurrentStatusValue);
            boolean isInitialAdminReview = "NEW".equals(normalizedCurrentStatusValue);
            boolean isUnderReviewStage = "UNDER_REVIEW".equals(normalizedCurrentStatusValue);
            boolean isInProgressStage = "IN_PROGRESS".equals(normalizedCurrentStatusValue);
            boolean canRejectAtCurrentStage = isInitialAdminReview || isUnderReviewStage || isInProgressStage;
        %>

        <div class="top-action-wrapper">
            <form method="post" action="${pageContext.request.contextPath}/admin/application" id="adminActionForm" data-current-status="<%= applicationData.get("status") == null ? "" : String.valueOf(applicationData.get("status")) %>">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="id" value="<%= applicationData.get("id") %>">
                <input type="hidden" name="presentation_date" id="presentationDateHidden">
                <input type="hidden" name="presentation_time" id="presentationTimeHidden">
                <input type="hidden" name="presentation_venue" id="presentationVenueHidden">
                <input type="hidden" name="presentation_message" id="presentationMessageHidden">
                <input type="hidden" name="kpp_invite_emails" id="kppInviteEmailsHidden">
                <input type="hidden" name="kpp_invite_memo" id="kppInviteMemoHidden">
                <input type="hidden" name="invite_mode" id="inviteModeHidden" value="new">
                <input type="hidden" name="replace_invite_id" id="replaceInviteIdHidden" value="">
                <div class="action-toolbar-sticky">
                    <div class="actions">
                        <% if (isWaitingForDirector) { %>
                        <button class="btn final-action" type="button"
                            onclick="if(confirm('Hantar semula email notifikasi kepada Pengarah?')){var a=document.createElement('input');a.type='hidden';a.name='action';a.value='resend_director';document.getElementById('adminActionForm').appendChild(a);document.getElementById('adminActionForm').submit();}">&#128231; Hantar Semula Email Pengarah</button>
                        <% } else { %>
                        <% if (isInitialAdminReview) { %>
                        <button class="btn approve" type="button" id="acceptApplicationBtn">Terima</button>
                        <% } %>
                        <% if (canRejectAtCurrentStage) { %>
                        <button class="btn reject" type="button" id="rejectApplicationBtn">Tolak</button>
                        <% } %>
                        <% if (isDirectorApprovedStage || isUnderReviewStage || isInProgressStage) { %>
                        <button class="btn in-progress" type="button" id="openInProgressModal"><%= isInProgressStage ? "Urus Jemputan Pembentangan" : "Panggil Pemohon dan KPP ke Pembentangan" %></button>
                        <% } %>
                        <% if (showNextStepButton) { %>
                        <button class="btn next-step" type="button" id="nextStepBtn">Seterusnya</button>
                        <% } else if (isInProgressStage) { %>
                        <button class="btn final-action" type="button" id="finalActionBtn">Tindakan Akhir</button>
                        <% } %>
                        <% } %>
                        <a class="btn secondary" href="${pageContext.request.contextPath}/dashboard">Kembali</a>
                    </div>
                </div>
            </form>
        </div>

        <div class="panel">
            <h2>Permohonan <%= String.format("PPP%03d", ((Number)applicationData.get("id")).intValue()) %></h2>
            <p>Status semasa: <span class="status"><%= displayStatusLabel(String.valueOf(applicationData.get("status")), statusLabelMap) %></span></p>
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
                    <div class="value"><%= formatDateTimeValue(applicationData.get("submitted_at")) %></div>
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
                <div><div class="label">Sah Sehingga</div><div class="value"><%= formatDateValue(detail.get("certification_valid_until")) %></div></div>
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
                        <td>
                            <div class="doc-actions">
                                <button
                                    type="button"
                                    class="btn btn-preview open-doc-modal"
                                    data-doc-id="<%= doc.get("id") %>"
                                    data-doc-name="<%= doc.get("original_filename") == null ? "Dokumen" : String.valueOf(doc.get("original_filename")) %>"
                                    data-content-type="<%= doc.get("content_type") == null ? "" : String.valueOf(doc.get("content_type")) %>">
                                    Lihat
                                </button>
                                <a class="btn btn-download" href="${pageContext.request.contextPath}/documents/download?id=<%= doc.get("id") %>" title="Muat Turun" aria-label="Muat Turun">
                                    <span class="icon-inline" aria-hidden="true">&#8681;</span>
                                </a>
                            </div>
                        </td>
                    </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>

        <div class="panel">
            <h3>Tindakan Pentadbir</h3>
            <% if (adminError != null && !adminError.isBlank()) { %>
            <div class="alert-error"><%= adminError %></div>
            <% } %>
            <div class="label">Nota Pentadbir</div>
            <textarea form="adminActionForm" name="admin_notes" id="adminNotes"><%= applicationData.get("admin_notes") != null ? applicationData.get("admin_notes") : "" %></textarea>
        </div>

        <div class="panel">
            <div class="audit-panel-header">
                <h3 style="margin:0;">Tindakan Admin (Permohonan Ini)</h3>
                <button type="button" class="audit-toggle-btn" id="toggleAuditBtnApplication" aria-expanded="true" aria-controls="adminAuditContentApplication" title="Sembunyi rekod tindakan admin">
                    <span id="toggleAuditIconApplication" class="icon-inline" aria-hidden="true">&#8722;</span>
                </button>
            </div>
            <div id="adminAuditContentApplication" class="audit-content">
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
                    <strong><%= esc(actorName) %> (<%= esc(actorDisplayId) %>) Â· <%= esc(actionDisplay) %></strong>
                    <p><%= esc(details) %></p>
                    <div class="audit-meta">
                        <span><%= actionAt == null ? "Masa tidak direkod" : esc(formatDateTimeValue(actionAt)) %></span>
                    </div>
                </li>
                <%      }
                   } else { %>
                <li class="audit-item">
                    <strong>Belum ada rekod tindakan untuk permohonan ini</strong>
                    <p>Sebaik tindakan admin dibuat, rekod akan dipaparkan di sini.</p>
                </li>
                <% } %>
            </ul>
            </div>
        </div>

        <div id="inProgressModal" class="inprogress-modal-overlay" aria-hidden="true">
            <div class="inprogress-modal-card" role="dialog" aria-modal="true" aria-label="Urus jemputan pembentangan produk air">
                <div class="inprogress-modal-head">
                    <h4>Urus Jemputan Pembentangan</h4>
                    <button type="button" class="btn secondary" id="closeInProgressModal">Tutup</button>
                </div>
                <div class="panel" style="margin-bottom:10px;padding:12px;border-radius:10px;background:#f8fbff;border:1px solid #dce8f3;">
                    <h4 style="margin:0 0 8px;color:#0f6bae;font-size:15px;">1. Jemputan Pembentangan - Pemohon</h4>
                <div class="inprogress-grid">
                    <div class="inprogress-field">
                        <label for="presentationDate">Tarikh</label>
                        <input type="date" id="presentationDate">
                    </div>
                    <div class="inprogress-field">
                        <label for="presentationTime">Masa</label>
                        <input type="time" id="presentationTime">
                    </div>
                    <div class="inprogress-field">
                        <label for="presentationVenue">Tempat</label>
                        <input type="text" id="presentationVenue" placeholder="Contoh: Bilik Mesyuarat JANS, Tingkat 6">
                    </div>
                </div>
                <div class="inprogress-field">
                        <label for="presentationMessage">Memo kepada pemohon (boleh edit)</label>
                    <textarea id="presentationMessage"></textarea>
                </div>
                    <div class="inprogress-field" style="margin-top:10px;">
                        <label>Maklum balas pemohon terkini</label>
                        <% if (latestPresentationInvite == null) { %>
                        <div class="value">Belum ada rekod jemputan pembentangan untuk permohonan ini.</div>
                        <% } else { %>
                        <div class="value" style="line-height:1.6;">
                            <strong>Status:</strong> <%= latestPresentationInvite.get("invite_status") == null ? "MENUNGGU MAKLUM BALAS" : displayStatusLabel(String.valueOf(latestPresentationInvite.get("invite_status")), statusLabelMap) %><br>
                            <strong>Wakil Hadir:</strong> <%= latestPresentationInvite.get("applicant_rep_name") == null ? "-" : latestPresentationInvite.get("applicant_rep_name") %><br>
                            <strong>Bilangan Peserta:</strong> <%= latestPresentationInvite.get("applicant_attendee_count") == null ? "-" : latestPresentationInvite.get("applicant_attendee_count") %><br>
                            <strong>Sebab Tidak Hadir:</strong> <%= latestPresentationInvite.get("applicant_absence_reason") == null ? "-" : latestPresentationInvite.get("applicant_absence_reason") %>
                        </div>
                        <% } %>
                    </div>
                    <label style="display:flex;align-items:center;gap:8px;margin-top:10px;">
                        <input type="checkbox" id="rescheduleMode">
                        Penjadualan semula (gunakan apabila pemohon tidak hadir)
                    </label>
                </div>

                <div class="panel" style="margin-bottom:10px;padding:12px;border-radius:10px;background:#f8fbff;border:1px solid #dce8f3;">
                    <h4 style="margin:0 0 8px;color:#0f6bae;font-size:15px;">2. Jemputan Pembentangan - Ketua Penolong Pengarah (KPP)</h4>
                    <div class="inprogress-field">
                        <label for="kppRecipientChecklist">Pilih KPP berkaitan (checklist)</label>
                        <div id="kppRecipientChecklist" style="display:flex;flex-direction:column;gap:4px;max-height:200px;overflow-y:auto;padding:6px;border:1px solid #d3e2ee;border-radius:8px;background:#f8fafb;">
                            <% if (kppUsers == null || kppUsers.isEmpty()) { %>
                            <div style="color:#64748b;font-size:12px;padding:8px;text-align:center;background:#fff;border-radius:4px;">Tiada rekod KPP dijumpai dalam fail Senarai KPP.csv.</div>
                            <% } else {
                                for (Map<String, Object> kppUser : kppUsers) { %>
                            <label style="display:flex;align-items:center;gap:6px;padding:6px;border-radius:4px;background:#fff;border:1px solid #e2e8f0;cursor:pointer;transition:all 0.2s;">
                                <input type="checkbox" class="kpp-recipient-check" data-email="<%= esc(String.valueOf(kppUser.get("email") == null ? "" : kppUser.get("email"))) %>" style="cursor:pointer;flex-shrink:0;margin:0;">
                                <div style="flex:1;min-width:0;">
                                    <div style="font-weight:500;color:#1f3347;font-size:12px;margin:0;line-height:1.3;"><%= esc(String.valueOf(kppUser.get("full_name") == null ? "-" : kppUser.get("full_name"))) %></div>
                                    <div style="font-size:10px;color:#64748b;margin:1px 0 0 0;line-height:1.2;"><%= esc(String.valueOf(kppUser.get("role") == null ? "-" : kppUser.get("role"))) %> Â· <%= esc(String.valueOf(kppUser.get("email") == null ? "-" : kppUser.get("email"))) %></div>
                                </div>
                            </label>
                            <%  }
                               } %>
                        </div>
                    </div>
                    <div class="inprogress-field" style="margin-top:10px;">
                        <label for="kppInviteMemo">Memo jemputan KPP (boleh edit)</label>
                        <textarea id="kppInviteMemo" placeholder="Memo ini akan digunakan untuk sistem/e-mel KPP"></textarea>
                    </div>
                </div>

                <div class="inprogress-actions">
                    <button type="button" class="btn secondary" id="cancelInProgressSubmit">Batal</button>
                    <button type="button" class="btn in-progress" id="confirmInProgressSubmit">Simpan & Hantar Jemputan</button>
                </div>
            </div>
        </div>

        <div class="container" style="padding-top:0;">
            <div class="jans-contact-section">
                <h3>Hubungi Jabatan Air Sabah</h3>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#128205;</span><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#9742;</span><span>Tel: +60-88-232364 (HQ)</span></p>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#128224;</span><span>Faks: +60-88-232396</span></p>
                <p class="contact-line"><span class="contact-icon" aria-hidden="true">&#9993;</span><span>Emel: produk.air@sabah.gov.my</span></p></div>
        </div>
    </div>

    <div id="documentModal" class="doc-modal-overlay" aria-hidden="true">
        <div class="doc-modal-card" role="dialog" aria-modal="true" aria-label="Semakan Dokumen Lampiran">
            <div class="doc-modal-header">
                <h4 id="documentModalTitle">Semakan Dokumen Lampiran</h4>
                <button type="button" class="btn secondary" id="closeDocumentModal">Tutup</button>
            </div>
            <div class="doc-modal-body">
                <div id="documentViewer" class="doc-viewer">
                    <div class="doc-viewer-empty">Tiada dokumen dipilih.</div>
                </div>
            </div>
            <div class="doc-modal-footer">
                <a id="documentDownloadBtn" class="btn btn-download" href="#" title="Muat Turun Dokumen" aria-label="Muat Turun Dokumen">
                    <span class="icon-inline" aria-hidden="true">&#8681;</span>
                </a>
            </div>
        </div>
    </div>

    <div id="approveConfirmModal" class="decision-modal-overlay" aria-hidden="true">
        <div class="decision-modal-card" role="dialog" aria-modal="true" aria-label="Pengesahan tindakan permohonan">
            <span class="decision-confirm-gif" aria-hidden="true">&#10067;</span>
            <h4 id="actionConfirmTitle">Pengesahan Tindakan</h4>
            <p id="actionConfirmMessage">Adakah anda ingin teruskan tindakan ini?</p>
            <div class="decision-actions">
                <button type="button" class="btn approve" id="approveConfirmYes">Ya</button>
                <button type="button" class="btn secondary" id="approveConfirmBack">Tidak, Kembali</button>
            </div>
        </div>
    </div>

    <div id="decisionResultModal" class="decision-modal-overlay" aria-hidden="true">
        <div class="decision-modal-card" role="dialog" aria-modal="true" aria-label="Notifikasi tindakan permohonan">
            <span id="decisionResultGif" class="decision-gif" aria-hidden="true">&#9989;</span>
            <h4 id="decisionResultTitle">Permohonan Diluluskan!</h4>
            <div class="decision-actions">
                <button type="button" class="btn secondary" id="decisionResultClose">Tutup</button>
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

        (function () {
            var form = document.getElementById('adminActionForm');
            var acceptBtn = document.getElementById('acceptApplicationBtn');
            var rejectBtn = document.getElementById('rejectApplicationBtn');
            var openBtn = document.getElementById('openInProgressModal');
            var modal = document.getElementById('inProgressModal');
            var closeBtn = document.getElementById('closeInProgressModal');
            var cancelBtn = document.getElementById('cancelInProgressSubmit');
            var confirmBtn = document.getElementById('confirmInProgressSubmit');
            var dateInput = document.getElementById('presentationDate');
            var timeInput = document.getElementById('presentationTime');
            var venueInput = document.getElementById('presentationVenue');
            var messageInput = document.getElementById('presentationMessage');
            var dateHidden = document.getElementById('presentationDateHidden');
            var timeHidden = document.getElementById('presentationTimeHidden');
            var venueHidden = document.getElementById('presentationVenueHidden');
            var messageHidden = document.getElementById('presentationMessageHidden');
            var kppInviteEmailsHidden = document.getElementById('kppInviteEmailsHidden');
            var kppInviteMemoHidden = document.getElementById('kppInviteMemoHidden');
            var inviteModeHidden = document.getElementById('inviteModeHidden');
            var replaceInviteIdHidden = document.getElementById('replaceInviteIdHidden');
            var rescheduleMode = document.getElementById('rescheduleMode');
            var kppInviteMemo = document.getElementById('kppInviteMemo');
            var kppRecipientChecks = Array.prototype.slice.call(document.querySelectorAll('.kpp-recipient-check'));
            var notesField = document.getElementById('adminNotes');
            var latestInviteId = '<%= latestPresentationInvite != null && latestPresentationInvite.get("id") != null ? String.valueOf(latestPresentationInvite.get("id")) : "" %>';

            function formatDateHuman(value) {
                if (!value) return '';
                var parts = value.split('-');
                if (parts.length !== 3) return value;
                return parts[2] + '-' + parts[1] + '-' + parts[0];
            }

            function generateMessage() {
                var dateVal = formatDateHuman(dateInput.value);
                var timeVal = timeInput.value || '[Masa belum ditetapkan]';
                var venueVal = (venueInput.value || '').trim() || '[Tempat belum ditetapkan]';
                var base = 'Pemohon dimaklumkan bahawa jemputan pembentangan telah dijadualkan.'
                    + '\nTarikh: ' + (dateVal || '[Tarikh belum ditetapkan]')
                    + '\nMasa: ' + timeVal
                    + '\nTempat: ' + venueVal;
                messageInput.value = base;
            }

            function collectKppEmails() {
                return kppRecipientChecks
                    .filter(function (input) {
                        return !!input && !!input.checked;
                    })
                    .map(function (input) {
                        return (input.getAttribute('data-email') || '').trim();
                    })
                    .filter(function (email) {
                        return !!email;
                    })
                    .join(',');
            }

            function openModal() {
                generateMessage();
                modal.classList.add('open');
                modal.setAttribute('aria-hidden', 'false');
            }

            function submitAdminAction(actionName, needsNotes) {
                if (!form) return;
                if (needsNotes && !(notesField && notesField.value && notesField.value.trim())) {
                    alert('Sila isi sebab penolakan sebelum menolak permohonan.');
                    if (notesField) notesField.focus();
                    return;
                }
                var actionInput = document.createElement('input');
                actionInput.type = 'hidden';
                actionInput.name = 'action';
                actionInput.value = actionName;
                form.appendChild(actionInput);
                form.submit();
            }

            function closeModal() {
                modal.classList.remove('open');
                modal.setAttribute('aria-hidden', 'true');
            }

            if (!form) return;

            if (acceptBtn) {
                acceptBtn.addEventListener('click', function () {
                    if (typeof window.requestAdminActionProceed === 'function') {
                        window.requestAdminActionProceed('approve', function () {
                            submitAdminAction('approve', false);
                        });
                        return;
                    }
                    submitAdminAction('approve', false);
                });
            }

            if (rejectBtn) {
                rejectBtn.addEventListener('click', function () {
                    if (!validateRejectReason()) {
                        return;
                    }
                    if (typeof window.requestAdminActionProceed === 'function') {
                        window.requestAdminActionProceed('reject', function () {
                            submitAdminAction('reject', true);
                        });
                        return;
                    }
                    submitAdminAction('reject', true);
                });
            }

            if (openBtn && modal) {
                openBtn.addEventListener('click', openModal);
            }
            if (closeBtn) closeBtn.addEventListener('click', closeModal);
            if (cancelBtn) cancelBtn.addEventListener('click', closeModal);

            [dateInput, timeInput, venueInput, notesField].forEach(function (el) {
                if (el) el.addEventListener('input', generateMessage);
            });

            if (confirmBtn) {
                confirmBtn.addEventListener('click', function () {
                    if (!dateInput.value || !timeInput.value || !(venueInput.value || '').trim()) {
                        alert('Sila isi tarikh, masa, dan tempat pembentangan.');
                        return;
                    }
                    var submitInProgress = function () {
                        dateHidden.value = dateInput.value;
                        timeHidden.value = timeInput.value;
                        venueHidden.value = venueInput.value.trim();
                        messageHidden.value = (messageInput.value || '').trim();
                        if (kppInviteEmailsHidden) {
                            kppInviteEmailsHidden.value = collectKppEmails();
                        }
                        if (kppInviteMemoHidden) {
                            kppInviteMemoHidden.value = kppInviteMemo ? (kppInviteMemo.value || '').trim() : '';
                        }
                        if (inviteModeHidden) {
                            inviteModeHidden.value = rescheduleMode && rescheduleMode.checked ? 'reschedule' : 'new';
                        }
                        if (replaceInviteIdHidden) {
                            replaceInviteIdHidden.value = (rescheduleMode && rescheduleMode.checked) ? latestInviteId : '';
                        }

                        var actionInput = document.createElement('input');
                        actionInput.type = 'hidden';
                        actionInput.name = 'action';
                        actionInput.value = 'dalam_proses';
                        form.appendChild(actionInput);
                        form.submit();
                    };

                    if (typeof window.requestAdminActionProceed === 'function') {
                        window.requestAdminActionProceed('dalam_proses', submitInProgress);
                        return;
                    }

                    submitInProgress();
                });
            }

            if (modal) {
                modal.addEventListener('click', function (event) {
                    if (event.target === modal) closeModal();
                });
            }
        })();

        (function () {
            var contextPath = '${pageContext.request.contextPath}';
            var modal = document.getElementById('documentModal');
            var modalTitle = document.getElementById('documentModalTitle');
            var closeModalBtn = document.getElementById('closeDocumentModal');
            var viewer = document.getElementById('documentViewer');
            var downloadBtn = document.getElementById('documentDownloadBtn');
            var openButtons = document.querySelectorAll('.open-doc-modal');

            function escapeHtml(value) {
                return String(value)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;')
                    .replace(/'/g, '&#39;');
            }

            function buildDownloadUrl(docId, inline) {
                return contextPath + '/documents/download?id=' + encodeURIComponent(docId) + (inline ? '&inline=1' : '');
            }

            function supportsInline(contentType, fileName) {
                var safeType = (contentType || '').toLowerCase();
                var safeName = (fileName || '').toLowerCase();
                return safeType.indexOf('application/pdf') === 0
                    || safeType.indexOf('image/') === 0
                    || /\.(pdf|png|jpg|jpeg|gif|webp|bmp)$/i.test(safeName);
            }

            function closeModal() {
                modal.classList.remove('open');
                modal.setAttribute('aria-hidden', 'true');
                viewer.innerHTML = '<div class="doc-viewer-empty">Tiada dokumen dipilih.</div>';
                modalTitle.textContent = 'Semakan Dokumen Lampiran';
                downloadBtn.setAttribute('href', '#');
            }

            function renderPreview(docId, contentType, fileName) {
                var downloadUrl = buildDownloadUrl(docId, false);
                var previewUrl = buildDownloadUrl(docId, true);
                var safeName = fileName || 'Dokumen Lampiran';

                modalTitle.textContent = 'Semakan Dokumen: ' + safeName;
                downloadBtn.setAttribute('href', downloadUrl);

                if (!supportsInline(contentType, safeName)) {
                    viewer.innerHTML = ''
                        + '<div class="doc-viewer-empty">'
                        + 'Format dokumen ini tidak menyokong pratonton automatik. '
                        + 'Sila klik butang Muat Turun Dokumen untuk semakan.'
                        + '</div>';
                    return;
                }

                if ((contentType || '').toLowerCase().indexOf('image/') === 0 || /\.(png|jpg|jpeg|gif|webp|bmp)$/i.test(safeName)) {
                    viewer.innerHTML = '<img alt="Pratonton dokumen" src="' + escapeHtml(previewUrl) + '">';
                    return;
                }

                viewer.innerHTML = '<iframe title="Pratonton dokumen" src="' + escapeHtml(previewUrl) + '"></iframe>';
            }

            openButtons.forEach(function (button) {
                button.addEventListener('click', function () {
                    var docId = button.getAttribute('data-doc-id') || '';
                    var docName = button.getAttribute('data-doc-name') || 'Dokumen Lampiran';
                    var contentType = button.getAttribute('data-content-type') || '';

                    if (!docId) {
                        alert('ID dokumen tidak sah.');
                        return;
                    }

                    modal.classList.add('open');
                    modal.setAttribute('aria-hidden', 'false');
                    renderPreview(docId, contentType, docName);
                });
            });

            if (closeModalBtn) {
                closeModalBtn.addEventListener('click', closeModal);
            }

            if (modal) {
                modal.addEventListener('click', function (event) {
                    if (event.target === modal) {
                        closeModal();
                    }
                });
            }

            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape' && modal.classList.contains('open')) {
                    closeModal();
                }
            });
        })();

        (function initAdminAuditToggleApplication() {
            var button = document.getElementById('toggleAuditBtnApplication');
            var content = document.getElementById('adminAuditContentApplication');
            var icon = document.getElementById('toggleAuditIconApplication');
            if (!button || !content || !icon) {
                return;
            }

            function setState(hidden) {
                content.classList.toggle('is-hidden', hidden);
                button.setAttribute('aria-expanded', hidden ? 'false' : 'true');
                button.setAttribute('title', hidden ? 'Paparkan rekod tindakan admin' : 'Sembunyi rekod tindakan admin');
                icon.textContent = hidden ? '+' : '\u2212';
            }

            button.addEventListener('click', function () {
                setState(!content.classList.contains('is-hidden'));
            });

            setState(false);
        })();

        (function initDecisionPopups() {
            var form = document.getElementById('adminActionForm');
            if (!form) return;

            var approveButton = form.querySelector('button[name="action"][value="approve"]');
            var rejectButton = form.querySelector('button[name="action"][value="reject"]');
            var finalActionBtn = document.getElementById('finalActionBtn');
            var nextStepBtn = document.getElementById('nextStepBtn');
            var currentStatus = (form.getAttribute('data-current-status') || '').trim().toLowerCase();

            var approveConfirmModal = document.getElementById('approveConfirmModal');
            var approveConfirmYes = document.getElementById('approveConfirmYes');
            var approveConfirmBack = document.getElementById('approveConfirmBack');
            var actionConfirmTitle = document.getElementById('actionConfirmTitle');
            var actionConfirmMessage = document.getElementById('actionConfirmMessage');

            var resultModal = document.getElementById('decisionResultModal');
            var resultTitle = document.getElementById('decisionResultTitle');
            var resultGif = document.getElementById('decisionResultGif');
            var resultClose = document.getElementById('decisionResultClose');

            var pendingAction = '';
            var pendingContinue = null;
            var bypassGuard = false;

            var actionLabels = {
                approve: 'Terima',
                reject: 'Tolak',
                dalam_tindakan: 'Dalam Tindakan',
                tindakan_akhir: 'Tindakan Akhir',
                seterusnya: 'Seterusnya'
            };

            var statusAliases = {
                approve: ['under_review', 'dalam_semakan', 'dalam semakan'],
                reject: ['rejected', 'ditolak'],
                dalam_tindakan: ['in_progress', 'dalam_proses', 'dalam proses', 'dalam_tindakan', 'dalam tindakan'],
                tindakan_akhir: ['under_review', 'new'],
                seterusnya: ['menunggu_seterusnya_diluluskan', 'menunggu_seterusnya_gagal', 'menunggu_seterusnya_gantung', 'menunggu_seterusnya_batal']
            };

            function setModalOpen(modal, isOpen) {
                if (!modal) return;
                modal.classList.toggle('open', isOpen);
                modal.setAttribute('aria-hidden', isOpen ? 'false' : 'true');
            }

            function statusMatches(actionValue) {
                var aliases = statusAliases[actionValue] || [];
                for (var i = 0; i < aliases.length; i++) {
                    if (currentStatus === aliases[i]) {
                        return true;
                    }
                }
                return false;
            }

            function showActionConfirm(actionValue, onContinue) {
                var label = actionLabels[actionValue] || actionValue;
                if (actionConfirmTitle) {
                    actionConfirmTitle.textContent = 'Pengesahan Tindakan';
                }
                if (actionConfirmMessage) {
                    if (statusMatches(actionValue)) {
                        actionConfirmMessage.textContent = 'Permohonan telah berada dalam status ' + label + ', adakah anda ingin teruskan tindakan ini?';
                    } else {
                        actionConfirmMessage.textContent = 'Permohonan akan ditukar kepada status ' + label + ', adakah anda ingin teruskan tindakan ini?';
                    }
                }
                pendingContinue = onContinue;
                setModalOpen(approveConfirmModal, true);
            }

            window.requestAdminActionProceed = function (actionValue, onContinue) {
                showActionConfirm(actionValue, onContinue);
            };

            function submitWithAction(actionValue) {
                var existing = form.querySelector('input[data-popup-action="1"]');
                if (existing) {
                    existing.remove();
                }
                var hidden = document.createElement('input');
                hidden.type = 'hidden';
                hidden.name = 'action';
                hidden.value = actionValue;
                hidden.setAttribute('data-popup-action', '1');
                form.appendChild(hidden);
                bypassGuard = true;
                form.submit();
            }

            function showResultModal(title, withGif, actionValue) {
                if (resultTitle) {
                    resultTitle.textContent = title;
                }
                if (resultGif) {
                    resultGif.classList.toggle('show', !!withGif);
                }
                setModalOpen(resultModal, true);

                if (resultClose) {
                    resultClose.onclick = function () {
                        setModalOpen(resultModal, false);
                        submitWithAction(actionValue);
                    };
                }
            }

            if (approveButton) {
                approveButton.addEventListener('click', function () {
                    pendingAction = 'approve';
                });
            }

            if (rejectButton) {
                rejectButton.addEventListener('click', function () {
                    pendingAction = 'reject';
                });
            }

            if (finalActionBtn) {
                finalActionBtn.addEventListener('click', function () {
                    if (typeof window.requestAdminActionProceed === 'function') {
                        window.requestAdminActionProceed('tindakan_akhir', function () {
                            submitWithAction('final_action');
                        });
                        return;
                    }
                    submitWithAction('final_action');
                });
            }

            if (nextStepBtn) {
                nextStepBtn.addEventListener('click', function () {
                    if (typeof window.requestAdminActionProceed === 'function') {
                        window.requestAdminActionProceed('seterusnya', function () {
                            submitWithAction('next_step');
                        });
                        return;
                    }
                    submitWithAction('next_step');
                });
            }

            form.addEventListener('submit', function (event) {
                if (bypassGuard) {
                    return;
                }

                var submitterAction = pendingAction;
                if (!submitterAction && event.submitter && event.submitter.name === 'action') {
                    submitterAction = event.submitter.value;
                }

                if (submitterAction === 'approve') {
                    event.preventDefault();
                    showActionConfirm('approve', function () {
                        showResultModal('Permohonan Diluluskan!', true, 'approve');
                    });
                    return;
                }

                if (submitterAction === 'reject') {
                    event.preventDefault();
                    if (!validateRejectReason()) {
                        return;
                    }
                    showActionConfirm('reject', function () {
                        showResultModal('Permohonan Ditolak', false, 'reject');
                    });
                    return;
                }

                if (submitterAction === 'dalam_semakan' || submitterAction === 'suspend_application' || submitterAction === 'suspend_user') {
                    event.preventDefault();
                    showActionConfirm(submitterAction, function () {
                        submitWithAction(submitterAction);
                    });
                    return;
                }
            });

            if (approveConfirmBack) {
                approveConfirmBack.addEventListener('click', function () {
                    setModalOpen(approveConfirmModal, false);
                    pendingContinue = null;
                });
            }

            if (approveConfirmYes) {
                approveConfirmYes.addEventListener('click', function () {
                    setModalOpen(approveConfirmModal, false);
                    if (typeof pendingContinue === 'function') {
                        var continueFn = pendingContinue;
                        pendingContinue = null;
                        continueFn();
                    }
                });
            }

            if (approveConfirmModal) {
                approveConfirmModal.addEventListener('click', function (event) {
                    if (event.target === approveConfirmModal) {
                        setModalOpen(approveConfirmModal, false);
                    }
                });
            }

            if (resultModal) {
                resultModal.addEventListener('click', function (event) {
                    if (event.target === resultModal && resultClose) {
                        resultClose.click();
                    }
                });
            }
        })();
    </script>
    <script>
        (function () {
            var params = new URLSearchParams(window.location.search || '');
            if (params.get('updated') !== '1') {
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
            popup.innerHTML = '<strong style="display:block;margin-bottom:4px;">Berjaya!</strong><span>Tindakan pentadbir telah berjaya direkodkan.</span>';

            document.body.appendChild(popup);
            setTimeout(function () {
                if (popup.parentNode) {
                    popup.parentNode.removeChild(popup);
                }
            }, 3200);
        })();
    </script>
</body>
</html>






