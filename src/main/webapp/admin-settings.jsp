<%-- NOTA ALIRAN KOD: Fail admin-settings.jsp. Halaman ini biasa dipanggil terus melalui UI atau navigation ke /admin-settings.jsp. Tujuan nota ni supaya orang seterusnya terus nampak konteks fail ni. --%>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.sistemppa.service.TemplateService.EmailTemplate" %>
<%@ page import="com.sistemppa.service.TemplateService.NotifTemplate" %>
<%@ page import="com.sistemppa.service.StatusConfigService.StatusConfig" %>
<%!
    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        String escaped = value;
        escaped = escaped.replace("&", "&amp;");
        escaped = escaped.replace("<", "&lt;");
        escaped = escaped.replace(">", "&gt;");
        escaped = escaped.replace("\"", "&quot;");
        escaped = escaped.replace("'", "&#39;");
        return escaped;
    }

    private String buildImageSrc(String contextPath, Object imageUrlValue) {
        if (imageUrlValue == null) {
            return "";
        }

        String raw = String.valueOf(imageUrlValue).trim().replace('\\', '/');
        if (raw.isEmpty()) {
            return "";
        }

        int managedAnnouncementIndex = raw.indexOf("/announcement-images/");
        if (managedAnnouncementIndex >= 0) {
            raw = raw.substring(managedAnnouncementIndex);
        }

        int legacyAnnouncementIndex = raw.indexOf("/assets/images/announcements/");
        if (legacyAnnouncementIndex >= 0) {
            String fileName = raw.substring(legacyAnnouncementIndex + "/assets/images/announcements/".length());
            int slashPos = fileName.indexOf('/');
            if (slashPos >= 0) {
                fileName = fileName.substring(0, slashPos);
            }
            if (!fileName.isBlank()) {
                raw = "/announcement-images/" + fileName;
            }
        }

        String safeContextPath = contextPath == null ? "" : contextPath.trim();
        if (safeContextPath.isEmpty() || "/".equals(safeContextPath)) {
            safeContextPath = "";
        }

        if (raw.startsWith("/")) {
            return safeContextPath + raw;
        }
        return safeContextPath + "/" + raw;
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

    private List<String> parseTemplateVariables(String variables) {
        List<String> keys = new java.util.ArrayList<>();
        if (variables == null || variables.isBlank()) {
            return keys;
        }
        String[] parts = variables.split(",");
        for (String part : parts) {
            if (part == null) {
                continue;
            }
            String token = part.trim();
            if (token.startsWith("{{") && token.endsWith("}}") && token.length() > 4) {
                token = token.substring(2, token.length() - 2).trim();
            }
            token = token.replace('{', ' ').replace('}', ' ').replace('[', ' ').replace(']', ' ').trim();
            if (!token.isEmpty() && !keys.contains(token)) {
                keys.add(token);
            }
        }
        return keys;
    }

    private String toFriendlyToken(String variableKey) {
        String label = toVariableLabel(variableKey);
        return "[" + label + "]";
    }

    private String toVariableLabel(String variableKey) {
        if (variableKey == null || variableKey.isBlank()) {
            return "";
        }
        String cleaned = variableKey.replaceAll("[^a-zA-Z0-9_\\- ]", " ")
                .replace('_', ' ')
                .replace('-', ' ')
                .trim();
        if (cleaned.isEmpty()) {
            return variableKey;
        }
        String[] words = cleaned.split("\\s+");
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < words.length; i++) {
            String w = words[i].toLowerCase(java.util.Locale.ROOT);
            if (w.isEmpty()) {
                continue;
            }
            out.append(Character.toUpperCase(w.charAt(0))).append(w.substring(1));
            if (i < words.length - 1) {
                out.append(' ');
            }
        }
        return out.toString().trim();
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Tetapan</title>
    <style>
        :root {
            --bg: #f2f7fb;
            --card: #ffffff;
            --line: #d7e6f1;
            --text: #12384f;
            --muted: #5d778a;
            --brand: #0f6bae;
            --brand-soft: #e9f4fc;
            --success-bg: #e7f9ec;
            --success-text: #166534;
            --success-line: #b8e7c6;
            --error-bg: #fff1f2;
            --error-text: #b91c1c;
            --error-line: #fecdd3;
        }

        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(180deg, #c4dcee 0%, var(--bg) 100%);
            color: var(--text);
        }

        .navbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            padding: 14px 18px;
            background: #15074c;
            border-bottom: 1px solid #15074c;
            position: sticky;
            top: 0;
            z-index: 20;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 10px;
            min-width: 0;
        }

        .brand-logo {
            width: 42px;
            height: 42px;
            object-fit: contain;
        }

        .brand h1 {
            margin: 0;
            font-size: 18px;
            color: #0b527f;
            line-height: 1.2;
        }

        .brand p {
            margin: 2px 0 0;
            color: var(--muted);
            font-size: 12px;
        }

        .nav-actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        .btn {
            border: 1px solid #c8deec;
            background: #eef7fd;
            color: #0f4f79;
            border-radius: 10px;
            padding: 8px 12px;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            cursor: pointer;
            transition: background 0.2s ease;
        }

        .btn:hover {
            background: #04375c;
        }

        .btn-primary {
            background: #0f6bae;
            border-color: #0f6bae;
            color: #04375c;
        }

        .btn-primary:hover {
            background: #0b5f99;
        }

        .container {
            max-width: 1160px;
            margin: 0 auto;
            padding: 18px 16px 24px;
        }

        .page-note {
            margin: 0 0 14px;
            font-size: 13px;
            color: #567085;
        }

        .settings-stack {
            display: grid;
            gap: 14px;
        }

        .settings-card {
            border: 1px solid var(--line);
            border-radius: 14px;
            background: var(--card);
            overflow: hidden;
        }

        .settings-fold-btn {
            width: 100%;
            border: 0;
            background: var(--brand-soft);
            color: #0d4c77;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            text-align: left;
            padding: 12px 14px;
            cursor: pointer;
        }

        .settings-fold-btn h3 {
            margin: 0;
            font-size: 16px;
            color: #0f5f93;
        }

        .settings-fold-btn small {
            display: block;
            margin-top: 3px;
            font-size: 12px;
            color: #4f6f83;
            font-weight: 600;
        }

        .settings-fold-icon {
            width: 18px;
            height: 18px;
            object-fit: contain;
            flex-shrink: 0;
            transition: transform 0.2s ease;
        }

        .settings-fold-btn[aria-expanded="true"] .settings-fold-icon {
            transform: rotate(180deg);
        }

        .settings-body {
            padding: 14px;
        }

        .settings-body.is-hidden {
            display: none;
        }

        .announce-alert {
            margin-bottom: 12px;
            border-radius: 10px;
            padding: 10px 12px;
            font-size: 13px;
        }

        .announce-success {
            background: var(--success-bg);
            color: var(--success-text);
            border: 1px solid var(--success-line);
        }

        .announce-error {
            background: var(--error-bg);
            color: var(--error-text);
            border: 1px solid var(--error-line);
        }

        .announcement-table-wrap {
            width: 100%;
            overflow-x: auto;
            border: 1px solid #d9e5ef;
            border-radius: 12px;
            background: #fff;
            margin-bottom: 12px;
        }

        .announcement-table {
            width: 100%;
            border-collapse: collapse;
            min-width: 700px;
        }

        .announcement-table th,
        .announcement-table td {
            border-bottom: 1px solid #e6eef5;
            padding: 9px 10px;
            text-align: left;
            font-size: 13px;
            color: #244255;
            vertical-align: top;
        }

        .announcement-table thead th {
            background: #f5faff;
            color: #0f5f93;
            font-weight: 700;
        }

        .announce-status {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            padding: 3px 8px;
            font-size: 11px;
            font-weight: 700;
            line-height: 1;
        }

        .announce-active {
            background: #dcfce7;
            color: #166534;
        }

        .announce-inactive {
            background: #fee2e2;
            color: #b91c1c;
        }

        .announcement-actions {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
        }

        .announcement-active-toggle {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            justify-content: flex-start;
            justify-self: start;
            width: fit-content;
        }

        .announcement-active-toggle input[type="checkbox"] {
            margin: 0;
            width: auto;
            min-width: 0;
            padding: 0;
            border: 0;
            border-radius: 0;
            background: transparent;
            box-shadow: none;
            accent-color: #0f6bae;
        }

        .btn.btn-primary.btn-announcement-add {
            background: #a9c9f5;
            color: #000000;
        }

        .btn.btn-primary.btn-announcement-add:hover {
            background: #99bef0;
            color: #000000;
        }

        .announce-image-preview {
            margin-top: 8px;
            border: 1px solid #d6e5f0;
            border-radius: 10px;
            background: #f8fcff;
            padding: 6px;
            max-width: 260px;
        }

        .announce-image-preview img {
            display: block;
            width: 100%;
            height: auto;
            border-radius: 8px;
            object-fit: cover;
        }

        .btn-danger {
            background: #ef4444;
            color: #ffffff;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        .icon-btn {
            width: 14px;
            height: 14px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            line-height: 1;
            margin-right: 6px;
        }

        .smtp-form {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 10px 12px;
        }

        .smtp-form .smtp-span-2 {
            grid-column: span 2;
        }

        .smtp-form label {
            display: block;
            margin-bottom: 6px;
            font-size: 13px;
            font-weight: 700;
            color: #4f6f83;
        }

        .smtp-form input,
        .smtp-form select,
        .smtp-form textarea,
        .announcement-form input,
        .announcement-form select,
        .announcement-form textarea {
            width: 100%;
            border: 1px solid #d4e4ef;
            border-radius: 10px;
            background: #f9fcff;
            padding: 9px 10px;
            font: inherit;
            color: #28475c;
        }

        .smtp-form-help,
        .smtp-form-note,
        .settings-help {
            margin-top: 5px;
            font-size: 12px;
            color: #5e798b;
        }

        .smtp-form-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            align-items: center;
        }

        .template-block {
            border: 1px solid #d6e6f2;
            border-radius: 12px;
            background: #fbfdff;
            padding: 10px;
            margin-bottom: 12px;
        }

        .template-block:last-child {
            margin-bottom: 0;
        }

        .template-block-head {
            width: 100%;
            border: 1px solid #d4e4ef;
            border-radius: 10px;
            padding: 10px 12px;
            background: #f6fbff;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            cursor: pointer;
            color: #0f5f93;
            font-weight: 700;
        }

        .template-block-head small {
            color: #4f6f83;
            font-size: 12px;
            font-weight: 700;
        }

        .template-block-head .settings-fold-icon {
            width: 16px;
            height: 16px;
        }

        .template-block-head[aria-expanded="true"] .settings-fold-icon {
            transform: rotate(180deg);
        }

        #emailTemplatesCard .template-block-head {
            background: #e3f2fd;
            border-color: #1976d2;
            color: #0d47a1;
        }

        #emailTemplatesCard .template-block-head small {
            color: #1565c0;
        }

        #notifTemplatesCard .template-block-head {
            background: #e8f5e9;
            border-color: #388e3c;
            color: #1b5e20;
        }

        #notifTemplatesCard .template-block-head small {
            color: #2e7d32;
        }

        .template-block-body {
            margin-top: 10px;
        }

        .template-detail {
            margin-bottom: 10px;
            border: 1px solid #d4e4ef;
            border-radius: 12px;
            overflow: hidden;
            background: #ffffff;
        }

        .template-detail:last-child {
            margin-bottom: 0;
        }

        .template-detail summary {
            padding: 12px 14px;
            cursor: pointer;
            background: #f6fbff;
            font-weight: 700;
            font-size: 13px;
            list-style: none;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
        }

        .template-detail code {
            font-size: 11px;
            font-weight: 700;
            color: #5c7788;
            background: #e8f0fb;
            padding: 2px 6px;
            border-radius: 6px;
        }

        .template-detail-inner {
            padding: 12px 14px;
            background: #ffffff;
        }

        .template-form-actions {
            display: flex;
            justify-content: flex-end;
            margin-top: 8px;
        }

        .template-helper {
            margin: 8px 0 10px;
            border: 1px dashed #b9d4e7;
            border-radius: 10px;
            background: #f4faff;
            padding: 8px 10px;
        }

        .template-helper-title {
            font-size: 12px;
            font-weight: 700;
            color: #1e5f89;
            margin-bottom: 6px;
        }

        .template-token-wrap {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .template-token-btn {
            border: 1px solid #b8d5ea;
            background: #ffffff;
            color: #0d4c77;
            border-radius: 999px;
            padding: 4px 9px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }

        .template-token-btn:hover {
            background: #e6f3ff;
        }

        .template-form-actions.top {
            margin-top: 0;
            margin-bottom: 10px;
        }

        .announcement-form {
            display: grid;
            gap: 10px;
        }

        .announcement-form textarea {
            resize: vertical;
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

        @media (max-width: 860px) {
            .smtp-form {
                grid-template-columns: 1fr;
            }

            .smtp-form .smtp-span-2 {
                grid-column: span 1;
            }

            .settings-fold-btn h3 {
                font-size: 15px;
            }

            .nav-actions {
                width: 100%;
                justify-content: flex-start;
            }

            .navbar {
                flex-direction: column;
                align-items: flex-start;
            }
        }
        
        body {
            font-family: inherit;
            background: linear-gradient(180deg, #eef3f8 0%, #f8fbfd 100%);
        }

        .navbar {
            background: #0b2a4a;
            border-bottom: 3px solid #081f36;
            color: #ffffff;
            padding: 14px 26px;
            box-shadow: 0 12px 28px rgba(8, 51, 77, 0.2);
            border-bottom-left-radius: 0;
            border-bottom-right-radius: 0;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .brand-logo {
            width: 52px;
            height: 52px;
            object-fit: contain;
        }

        .brand h1 {
            margin: 0;
            font-size: 21px;
            letter-spacing: 0.02em;
            color: #ffffff;
        }

        .brand p {
            margin: 2px 0 0;
            font-size: 12px;
            opacity: 0.9;
            color: #e8f2ff;
        }

        .nav-actions span {
            color: #f3f8ff;
        }

        .nav-actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        .icon-link {
            width: 54px;
            height: 54px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            background: #0f4f8f;
            border: 2px solid #0b3f72;
            transition: transform 0.18s ease, background 0.18s ease;
            text-decoration: none;
            margin-left: 4px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22);
        }

        .icon-link .icon-glyph {
            width: 30px;
            height: 30px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-family: "Segoe UI Symbol", "Noto Sans Symbols 2", sans-serif;
            font-size: 30px;
            font-weight: 700;
            line-height: 1;
            color: #ffffff;
            text-shadow: none;
        }

        .icon-link:hover {
            transform: translateY(-1px) scale(1.03);
            background: #1263b5;
        }

        .container {
            max-width: 1200px;
            margin: 28px auto;
            padding: 0 20px 40px;
        }

        .page-header {
            margin-bottom: 20px;
        }

        .page-header h2 {
            margin: 0 0 4px;
            font-size: 26px;
            color: var(--brand-navy);
        }

        .page-header p {
            margin: 0;
            color: var(--muted);
        }

        .settings-stack {
            display: grid;
            gap: 18px;
        }

        .settings-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: 14px;
            box-shadow: 0 8px 26px rgba(9, 53, 79, 0.07);
            overflow: hidden;
        }

        .settings-fold-btn {
            width: 100%;
            border: 0;
            background: #f5fbff;
            color: #0d4c77;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            text-align: left;
            padding: 14px 16px;
            cursor: pointer;
        }

        .settings-card {
            --panel-accent: #0f6bae;
            --panel-soft: #f5fbff;
        }

        #announcementPanel {
            --panel-accent: #ec4899;
            --panel-soft: #fdf0f7;
        }

        #smtpSettingsCard {
            --panel-accent: #22c55e;
            --panel-soft: #effbf3;
        }

        #templatePanel {
            --panel-accent: #3b82f6;
            --panel-soft: #eff6ff;
        }

        #statusConfigPanel {
            --panel-accent: #f59e0b;
            --panel-soft: #fff8e7;
        }

        .settings-card > .settings-fold-btn {
            background: var(--panel-soft);
            border-left: 6px solid var(--panel-accent);
        }

        .settings-fold-btn h3 {
            margin: 0;
            font-size: 18px;
            color: var(--panel-accent);
        }

        .settings-fold-btn small {
            display: block;
            margin-top: 3px;
            font-size: 12px;
            color: #4f6f83;
            font-weight: 600;
        }

        .settings-fold-icon {
            font-size: 16px;
            font-weight: 800;
            line-height: 1;
            color: #0f6bae;
            transition: transform 0.2s ease;
        }

        .settings-fold-btn[aria-expanded="true"] .settings-fold-icon {
            transform: rotate(180deg);
        }

        .settings-body {
            padding: 18px 22px 22px;
        }

        .template-block {
            border: 1px solid #d8e7f2;
            border-radius: 12px;
            background: #fbfdff;
            padding: 0;
            margin-bottom: 12px;
            overflow: hidden;
        }

        .template-block-head {
            width: 100%;
            border: 0;
            border-radius: 0;
            padding: 12px 14px;
            background: #f7fbff;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            cursor: pointer;
            color: #0f5f93;
            font-weight: 700;
        }

        .template-block-head small {
            color: #4f6f83;
            font-size: 12px;
            font-weight: 700;
        }

        .template-block-body {
            margin-top: 0;
            padding: 12px 14px 14px;
        }

        .template-detail {
            border-color: #d8e7f2;
        }

        .btn {
            padding: 10px 16px;
            border-radius: 10px;
            border: none;
            font-size: 14px;
            font-weight: 700;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-family: inherit;
            text-decoration: none;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
        }

        .btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 5px 14px rgba(9,53,79,0.15);
        }

        .btn-primary {
            background: #0f6bae;
            border-color: #0f6bae;
            color: #ffffff;
            box-shadow: 0 6px 18px rgba(15, 58, 111, 0.16);
        }

        .btn-primary:hover {
            background: #0b5f99;
            color: #ffffff;
        }

        .btn-secondary {
            background: #e2edf5;
            color: var(--brand-navy);
        }

        .btn-email-save {
            background: #0f6bae;
            border-color: #0f6bae;
            color: #ffffff;
        }

        .btn-email-save:hover {
            background: #0b5f99;
            color: #ffffff;
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

        .table-wrap {
            width: 100%;
            overflow-x: auto;
            border: 1px solid #d9e5ef;
            border-radius: 12px;
            background: #fff;
        }

        .table-wrap table {
            min-width: 850px;
            margin: 0;
            border-collapse: collapse;
        }

        @media (max-width: 860px) {
            .navbar {
                flex-direction: column;
                align-items: flex-start;
            }

            .brand-logo {
                width: 42px;
                height: 42px;
            }

            .brand h1 {
                font-size: 16px;
            }

            .container {
                padding: 0 10px 20px;
            }

            .settings-card {
                border-radius: 14px;
            }

            .settings-body {
                padding: 14px;
            }

            .table-wrap table {
                min-width: 760px;
            }
        }
    </style>
</head>
<body>
    <%
        @SuppressWarnings("unchecked")
        List<EmailTemplate> emailTemplates = (List<EmailTemplate>) request.getAttribute("email_templates");
        if (emailTemplates == null) emailTemplates = Collections.emptyList();
        @SuppressWarnings("unchecked")
        List<NotifTemplate> notifTemplates = (List<NotifTemplate>) request.getAttribute("notif_templates");
        if (notifTemplates == null) notifTemplates = Collections.emptyList();
        @SuppressWarnings("unchecked")
        List<StatusConfig> statusConfigs = (List<StatusConfig>) request.getAttribute("status_configs");
        if (statusConfigs == null) statusConfigs = Collections.emptyList();

        boolean templateSaved = "1".equals(request.getParameter("template_saved"));
        String templateError = request.getParameter("template_error");
        boolean statusConfigSaved = "1".equals(request.getParameter("status_config_saved"));
        String statusConfigError = request.getParameter("status_config_error");
    %>

    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Tetapan Admin</h1>
                <p>Pengurusan template e-mel, notifikasi, status dan SMTP.</p>
            </div>
        </div>
        <div class="nav-actions">
            <a class="icon-link" href="${pageContext.request.contextPath}/dashboard" title="Dashboard" aria-label="Dashboard"><span class="icon-glyph" aria-hidden="true">&#9638;</span></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><svg class="icon-glyph" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M3 10.5L12 3l9 7.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M5.5 9.5V21h13V9.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><svg class="icon-glyph" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M10 5H5v14h5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M13 12h8" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 8l4 4-4 4" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg></a>
        </div>
    </div>


        <div class="settings-stack">
            <div class="settings-card" id="announcementPanel">
                <button type="button" class="settings-fold-btn" data-target="announcementPanelBody" aria-expanded="true">
                    <span>
                        <h3>Pengurusan Pengumuman</h3>
                        <small>Urus kandungan, status aktif, dan imej pengumuman di halaman utama.</small>
                    </span>
                    <span class="settings-fold-icon" aria-hidden="true">&#9662;</span>
                </button>
                <div class="settings-body" id="announcementPanelBody">
                    <% if (request.getAttribute("announcement_success") != null) { %>
                        <div class="announce-alert announce-success"><%= request.getAttribute("announcement_success") %></div>
                    <% } %>
                    <% if (request.getAttribute("announcement_error") != null) { %>
                        <div class="announce-alert announce-error"><%= request.getAttribute("announcement_error") %></div>
                    <% } %>

                    <%
                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> announcementList = (List<Map<String, Object>>) request.getAttribute("announcements");
                        if (announcementList == null) announcementList = java.util.Collections.emptyList();
                    %>

                    <% if (!announcementList.isEmpty()) { %>
                    <div class="announcement-table-wrap">
                        <table class="announcement-table">
                            <thead>
                                <tr>
                                    <th style="width:36px;">#</th>
                                    <th>Tajuk</th>
                                    <th style="width:90px;">Status</th>
                                    <th style="width:140px;">Tarikh Cipta</th>
                                    <th style="width:110px;">Tindakan</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (int ai = 0; ai < announcementList.size(); ai++) {
                                Map<String, Object> ann = announcementList.get(ai);
                                boolean annActive = Boolean.TRUE.equals(ann.get("is_active"));
                                String annId = String.valueOf(ann.get("id"));
                                String annTitle = escapeHtml(String.valueOf(ann.get("title")));
                                Object annCreated = ann.get("created_at");
                                String annDate = annCreated == null ? "-" : formatDateValue(annCreated);
                                String annStatusClass = annActive ? "announce-status announce-active" : "announce-status announce-inactive";
                                String annStatusText = annActive ? "Aktif" : "Tidak Aktif";
                            %>
                                <tr>
                                    <td><%= ai + 1 %></td>
                                    <td style="max-width:220px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<%= annTitle %>"><%= annTitle %></td>
                                    <td><span class="<%= annStatusClass %>"><%= annStatusText %></span></td>
                                    <td style="font-size:12px; color:#666;"><%= annDate %></td>
                                    <td>
                                        <div style="display:flex; gap:6px; flex-wrap:wrap;">
                                            <a class="btn btn-secondary" style="padding:4px 10px; font-size:12px;"
                                               href="${pageContext.request.contextPath}/dashboard?view=settings&announcement_id=<%= annId %>#announcementPanel">
                                                <span class="icon-btn" aria-hidden="true">&#9998;</span>Edit
                                            </a>
                                            <form method="post" action="${pageContext.request.contextPath}/dashboard" style="margin:0;" onsubmit="return confirm('Padam pengumuman ini?');">
                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                <input type="hidden" name="announcement_action" value="delete_announcement">
                                                <input type="hidden" name="announcement_id" value="<%= annId %>">
                                                <button type="submit" class="btn btn-danger" style="padding:4px 10px; font-size:12px;">
                                                    <span class="icon-btn" aria-hidden="true">&#10006;</span>Padam
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                        <p style="color:#6e8492; font-size:13px; margin-bottom:14px;">Tiada pengumuman lagi. Tambah pengumuman pertama di bawah.</p>
                    <% } %>

                    <h4 style="margin: 0 0 10px; font-size:14px; color:#0b5e8f;">
                        <%= (request.getAttribute("announcement_editing") != null && !((Map<?,?>)request.getAttribute("announcement_editing")).isEmpty()) ? "&#9998; Kemaskini Pengumuman" : "&#43; Tambah Pengumuman Baharu" %>
                    </h4>

                    <%
                        @SuppressWarnings("unchecked")
                        Map<String, Object> announcementEditing = (Map<String, Object>) request.getAttribute("announcement_editing");
                        String announcementFormTitle = String.valueOf(request.getAttribute("announcement_form_title") == null ? "" : request.getAttribute("announcement_form_title"));
                        String announcementFormContent = String.valueOf(request.getAttribute("announcement_form_content") == null ? "" : request.getAttribute("announcement_form_content"));
                        Boolean announcementFormActive = (Boolean) request.getAttribute("announcement_form_active");
                        boolean formActive = announcementFormActive == null || announcementFormActive;

                        if (announcementEditing != null && !announcementEditing.isEmpty()) {
                            announcementFormTitle = String.valueOf(announcementEditing.get("title"));
                            announcementFormContent = String.valueOf(announcementEditing.get("content"));
                            formActive = Boolean.TRUE.equals(announcementEditing.get("is_active"));
                        }
                    %>

                    <form method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form" enctype="multipart/form-data">
                        <input type="hidden" name="_csrf" value="${csrf_token}">
                        <input type="hidden" name="announcement_action" value="<%= (announcementEditing != null && !announcementEditing.isEmpty()) ? "update_announcement" : "create_announcement" %>">
                        <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                            <input type="hidden" name="announcement_id" value="<%= announcementEditing.get("id") %>">
                        <% } %>
                        <%
                            String announcementImageUrl = String.valueOf(request.getAttribute("announcement_form_image_url") == null ? "" : request.getAttribute("announcement_form_image_url"));
                            if ((announcementImageUrl == null || announcementImageUrl.isBlank()) && announcementEditing != null && !announcementEditing.isEmpty()) {
                                announcementImageUrl = announcementEditing.get("image_url") == null ? "" : String.valueOf(announcementEditing.get("image_url"));
                            }
                            String announcementImageSrc = buildImageSrc(request.getContextPath(), announcementImageUrl);
                        %>
                        <input type="hidden" name="announcement_existing_image_url" value="<%= escapeHtml(announcementImageUrl) %>">

                        <div>
                            <label for="announcement_title"><strong>Tajuk</strong></label>
                            <input id="announcement_title" type="text" name="announcement_title" maxlength="180" required value="<%= escapeHtml(announcementFormTitle) %>">
                        </div>
                        <div>
                            <label for="announcement_content"><strong>Kandungan</strong></label>
                            <textarea id="announcement_content" name="announcement_content" required><%= escapeHtml(announcementFormContent) %></textarea>
                        </div>
                        <div>
                            <label for="announcement_image"><strong>Gambar (pilihan)</strong></label>
                            <input id="announcement_image" type="file" name="announcement_image" accept=".png,.jpg,.jpeg,.webp,image/png,image/jpeg,image/webp">
                            <% if (!announcementImageSrc.isBlank()) { %>
                                <div class="announce-image-preview">
                                    <img src="<%= escapeHtml(announcementImageSrc) %>" alt="Pratonton gambar pengumuman" onerror="this.style.display='none';">
                                </div>
                            <% } %>
                        </div>
                        <label class="announcement-active-toggle">
                            <input type="checkbox" name="announcement_active" <%= formActive ? "checked" : "" %>>
                            Aktifkan paparan di halaman utama
                        </label>
                        <div class="announcement-actions">
                            <button class="btn btn-primary <%= (announcementEditing != null && !announcementEditing.isEmpty()) ? "" : "btn-announcement-add" %>" type="submit">
                                <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                                    <span class="icon-btn" aria-hidden="true">&#9998;</span> Kemas Kini
                                <% } else { %>
                                    <span class="icon-btn" aria-hidden="true">+</span> Tambah
                                <% } %>
                            </button>
                            <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard?view=settings#announcementPanel">Batal</a>
                            <% } %>
                        </div>
                    </form>
                </div>
            </div>

            <div class="settings-card" id="smtpSettingsCard">
                <button type="button" class="settings-fold-btn" data-target="smtpSettingsBody" aria-expanded="true">
                    <span>
                        <h3>Tetapan Pengirim</h3>
                        <small>Konfigurasi SMTP untuk penghantaran e-mel sistem.</small>
                    </span>
                    <span class="settings-fold-icon" aria-hidden="true">&#9662;</span>
                </button>
                <div class="settings-body" id="smtpSettingsBody">
                    <% if (request.getAttribute("smtp_success") != null) { %>
                        <div class="announce-alert announce-success"><%= request.getAttribute("smtp_success") %></div>
                    <% } %>
                    <% if (request.getAttribute("smtp_error") != null) { %>
                        <div class="announce-alert announce-error"><%= request.getAttribute("smtp_error") %></div>
                    <% } %>

                    <form method="post" action="${pageContext.request.contextPath}/dashboard" class="smtp-form">
                        <input type="hidden" name="_csrf" value="${csrf_token}">
                        <input type="hidden" name="smtp_action" value="update_sender">

                        <div>
                            <label for="smtp_host">SMTP Host</label>
                            <input id="smtp_host" name="smtp_host" type="text" required value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_host") == null ? "" : request.getAttribute("smtp_setting_host"))) %>">
                        </div>

                        <div>
                            <label for="smtp_port">SMTP Port</label>
                            <input id="smtp_port" name="smtp_port" type="number" min="1" required value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_port") == null ? "587" : request.getAttribute("smtp_setting_port"))) %>">
                        </div>

                        <div>
                            <label for="smtp_username">SMTP Username</label>
                            <input id="smtp_username" name="smtp_username" type="text" value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_username") == null ? "" : request.getAttribute("smtp_setting_username"))) %>">
                        </div>

                        <div>
                            <label for="smtp_password">SMTP Password Baharu</label>
                            <input id="smtp_password" name="smtp_password" type="password" autocomplete="new-password" placeholder="Kosongkan jika tidak mahu ubah">
                            <div class="smtp-form-help">Biarkan kosong untuk kekalkan password semasa.</div>
                        </div>

                        <div>
                            <label for="smtp_from">From Address</label>
                            <input id="smtp_from" name="smtp_from" type="email" value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_from") == null ? "" : request.getAttribute("smtp_setting_from"))) %>">
                        </div>

                        <div>
                            <label for="smtp_auth">SMTP Auth</label>
                            <select id="smtp_auth" name="smtp_auth">
                                <option value="true" <%= "true".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_auth") == null ? "true" : request.getAttribute("smtp_setting_auth"))) ? "selected" : "" %>>Aktif</option>
                                <option value="false" <%= "false".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_auth") == null ? "true" : request.getAttribute("smtp_setting_auth"))) ? "selected" : "" %>>Tidak Aktif</option>
                            </select>
                        </div>

                        <div>
                            <label for="smtp_tls">STATUS</label>
                            <select id="smtp_tls" name="smtp_tls">
                                <option value="true" <%= "true".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_tls") == null ? "true" : request.getAttribute("smtp_setting_tls"))) ? "selected" : "" %>>Aktif</option>
                                <option value="false" <%= "false".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_tls") == null ? "true" : request.getAttribute("smtp_setting_tls"))) ? "selected" : "" %>>Tidak Aktif</option>
                            </select>
                        </div>

                        <div class="smtp-span-2 smtp-form-actions">
                            <button class="btn btn-email-save" type="submit">Simpan Tetapan Email</button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="settings-card" id="templatePanel">
                <button type="button" class="settings-fold-btn" data-target="templatePanelBody" aria-expanded="true">
                    <span>
                        <h3>Pengurusan Template E-mel &amp; Pemberitahuan</h3>
                        <small>Semua template e-mel dan notifikasi sistem.</small>
                    </span>
                    <span class="settings-fold-icon" aria-hidden="true">&#9662;</span>
                </button>
                <div class="settings-body" id="templatePanelBody">
                    <% if (templateSaved) { %>
                    <div class="announce-alert announce-success">Template berjaya disimpan.</div>
                    <% } %>
                    <% if (templateError != null && !templateError.isEmpty()) { %>
                    <div class="announce-alert announce-error">Ralat menyimpan template: <%= escapeHtml(templateError) %>.</div>
                    <% } %>

                    <div class="template-block" id="emailTemplatesCard">
                        <button type="button" class="template-block-head" data-target="emailTemplatesBody" aria-expanded="true">
                            <span>Template E-mel</span>
                            <span class="settings-fold-icon" aria-hidden="true">&#9662;</span>
                        </button>
                        <div class="template-block-body" id="emailTemplatesBody">
                            <% for (EmailTemplate et : emailTemplates) { 
                                String emailTemplateFormId = "email-template-form-" + et.key;
                            %>
                            <details class="template-detail">
                                <summary>
                                    <span><%= escapeHtml(et.name) %> <code><%= escapeHtml(et.key) %></code></span>
                                    <span style="display:flex;align-items:center;gap:8px;">
                                        <span style="font-size:12px;color:#0f6bae;">Edit &#9660;</span>
                                    </span>
                                </summary>
                                <div class="template-detail-inner">
                                    <% if (et.description != null && !et.description.isEmpty()) { %>
                                    <p style="font-size:12px;color:#5c7485;margin:0 0 8px;"><%= escapeHtml(et.description) %></p>
                                    <% } %>
                                    <% if (et.variables != null && !et.variables.isEmpty()) { %>
                                    <p style="font-size:12px;color:#0369a1;margin:0 0 10px;">Placeholder tersedia: <code><%= escapeHtml(et.variables) %></code></p>
                                    <div class="template-helper" data-template-helper>
                                        <div class="template-helper-title">Sisipi kata kunci automatik</div>
                                        <div class="template-token-wrap">
                                            <% for (String varKey : parseTemplateVariables(et.variables)) { %>
                                            <button type="button" class="template-token-btn" data-template-token="<%= escapeHtml(toFriendlyToken(varKey)) %>"><%= escapeHtml(toVariableLabel(varKey)) %></button>
                                            <% } %>
                                        </div>
                                        <div class="settings-help">Klik kata kunci, sistem akan auto tukar ke format dalaman semasa simpan template.</div>
                                    </div>
                                    <% } %>
                                    <form id="<%= emailTemplateFormId %>" method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form">
                                        <input type="hidden" name="_csrf" value="${csrf_token}">
                                        <input type="hidden" name="template_action" value="save_email">
                                        <input type="hidden" name="template_type" value="email">
                                        <input type="hidden" name="template_key" value="<%= escapeHtml(et.key) %>">
                                        <input type="hidden" name="template_name" value="<%= escapeHtml(et.name) %>">
                                        <input type="hidden" name="template_description" value="<%= escapeHtml(et.description != null ? et.description : "") %>">
                                        <div>
                                            <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Subjek E-mel</label>
                                            <input type="text" name="template_subject" class="template-editor" value="<%= escapeHtml(et.subject) %>" required>
                                        </div>
                                        <div>
                                            <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Badan E-mel</label>
                                            <textarea name="template_body" class="template-editor" rows="8" required style="font-size:12px;font-family:Consolas,monospace;"><%= escapeHtml(et.body) %></textarea>
                                            <div class="settings-help">Admin boleh tulis ayat biasa sahaja. Sistem akan auto-format ke HTML semasa simpan jika tiada tag HTML dikesan.</div>
                                        </div>
                                        <div class="template-form-actions">
                                            <button class="btn btn-primary" type="submit">Simpan Perubahan Template</button>
                                        </div>
                                    </form>
                                </div>
                            </details>
                            <% } %>
                            <% if (emailTemplates.isEmpty()) { %>
                            <p style="font-size:13px;color:#6e8492;margin:0;">Tiada template e-mel ditemui. Pastikan migrasi pangkalan data telah dijalankan.</p>
                            <% } %>
                        </div>
                    </div>

                    <div class="template-block" id="notifTemplatesCard">
                        <button type="button" class="template-block-head" data-target="notifTemplatesBody" aria-expanded="true">
                            <span>Template Pemberitahuan</span>
                            <span class="settings-fold-icon" aria-hidden="true">&#9662;</span>
                        </button>
                        <div class="template-block-body" id="notifTemplatesBody">
                            <% for (NotifTemplate nt : notifTemplates) { 
                                String notifTemplateFormId = "notif-template-form-" + nt.key;
                            %>
                            <details class="template-detail">
                                <summary>
                                    <span><%= escapeHtml(nt.name) %> <code><%= escapeHtml(nt.key) %></code></span>
                                    <span style="display:flex;align-items:center;gap:8px;">
                                        <span style="font-size:12px;color:#0f6bae;">Edit &#9660;</span>
                                    </span>
                                </summary>
                                <div class="template-detail-inner">
                                    <% if (nt.description != null && !nt.description.isEmpty()) { %>
                                    <p style="font-size:12px;color:#5c7485;margin:0 0 8px;"><%= escapeHtml(nt.description) %></p>
                                    <% } %>
                                    <% if (nt.variables != null && !nt.variables.isEmpty()) { %>
                                    <p style="font-size:12px;color:#0369a1;margin:0 0 10px;">Placeholder tersedia: <code><%= escapeHtml(nt.variables) %></code></p>
                                    <div class="template-helper" data-template-helper>
                                        <div class="template-helper-title">Sisipi kata kunci automatik</div>
                                        <div class="template-token-wrap">
                                            <% for (String varKey : parseTemplateVariables(nt.variables)) { %>
                                            <button type="button" class="template-token-btn" data-template-token="<%= escapeHtml(toFriendlyToken(varKey)) %>"><%= escapeHtml(toVariableLabel(varKey)) %></button>
                                            <% } %>
                                        </div>
                                        <div class="settings-help">Klik kata kunci, sistem akan auto tukar ke format dalaman semasa simpan template.</div>
                                    </div>
                                    <% } %>
                                    <form id="<%= notifTemplateFormId %>" method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form">
                                        <input type="hidden" name="_csrf" value="${csrf_token}">
                                        <input type="hidden" name="template_action" value="save_notif">
                                        <input type="hidden" name="template_type" value="notif">
                                        <input type="hidden" name="template_key" value="<%= escapeHtml(nt.key) %>">
                                        <input type="hidden" name="template_name" value="<%= escapeHtml(nt.name) %>">
                                        <input type="hidden" name="template_description" value="<%= escapeHtml(nt.description != null ? nt.description : "") %>">
                                        <div>
                                            <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Mesej Pemberitahuan</label>
                                            <textarea name="template_message" class="template-editor" rows="4" required><%= escapeHtml(nt.message) %></textarea>
                                        </div>
                                        <div class="template-form-actions">
                                            <button class="btn btn-primary" type="submit">Simpan Perubahan Template</button>
                                        </div>
                                    </form>
                                </div>
                            </details>
                            <% } %>
                            <% if (notifTemplates.isEmpty()) { %>
                            <p style="font-size:13px;color:#6e8492;margin:0;">Tiada template pemberitahuan ditemui.</p>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>

            <div class="settings-card" id="statusConfigPanel">
                <button type="button" class="settings-fold-btn" data-target="statusConfigPanelBody" aria-expanded="true">
                    <span>
                        <h3>Pengurusan Konfigurasi Status</h3>
                        <small>Urus label, warna lencana dan penerangan status.</small>
                    </span>
                    <span class="settings-fold-icon" aria-hidden="true">&#9662;</span>
                </button>
                <div class="settings-body" id="statusConfigPanelBody">
                    <% if (statusConfigSaved) { %>
                    <div class="announce-alert announce-success">Konfigurasi status berjaya dikemas kini.</div>
                    <% } %>
                    <% if (statusConfigError != null && !statusConfigError.isEmpty()) { %>
                    <div class="announce-alert announce-error">Ralat: <%= escapeHtml(statusConfigError) %>.</div>
                    <% } %>
                

                    <% if (statusConfigs.isEmpty()) { %>
                    <p style="font-size:13px;color:#6e8492;margin:0;">Tiada konfigurasi status ditemui. Pastikan migrasi pangkalan data telah dijalankan.</p>
                    <% } else { %>
                    <% for (StatusConfig sc : statusConfigs) { %>
                    <details class="template-detail">
                        <summary>
                            <span style="display:flex;align-items:center;gap:10px;">
                                <span class="status-pill" data-bg="<%= escapeHtml(sc.bgColor) %>" data-text="<%= escapeHtml(sc.textColor) %>"><%= escapeHtml(sc.displayLabel) %></span>
                                <code><%= escapeHtml(sc.key) %></code>
                            </span>
                            <span style="font-size:12px;color:#0f6bae;">Edit &#9660;</span>
                        </summary>
                        <div class="template-detail-inner">
                            <form method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form" style="grid-template-columns:1fr 1fr;">
                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                <input type="hidden" name="status_config_action" value="save_status">
                                <input type="hidden" name="sc_key" value="<%= escapeHtml(sc.key) %>">
                                <div style="grid-column:1/-1;">
                                    <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Label Paparan</label>
                                    <input type="text" name="sc_label" value="<%= escapeHtml(sc.displayLabel) %>" required>
                                </div>
                                <div>
                                    <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Warna Latar Lencana</label>
                                    <input type="color" name="sc_bg" value="<%= escapeHtml(sc.bgColor != null && sc.bgColor.matches("#[0-9a-fA-F]{6}") ? sc.bgColor : "#e2e8f0") %>">
                                </div>
                                <div>
                                    <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Warna Teks Lencana</label>
                                    <input type="color" name="sc_text" value="<%= escapeHtml(sc.textColor != null && sc.textColor.matches("#[0-9a-fA-F]{6}") ? sc.textColor : "#0f172a") %>">
                                </div>
                                <div style="grid-column:1/-1;">
                                    <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Penerangan (untuk rujukan admin)</label>
                                    <input type="text" name="sc_description" value="<%= escapeHtml(sc.description != null ? sc.description : "") %>">
                                </div>
                                <div>
                                    <label style="display:block;font-size:12px;font-weight:700;color:#35566a;margin-bottom:4px;">Urutan Paparan</label>
                                    <input type="number" name="sc_sort_order" value="<%= sc.sortOrder %>" min="0" max="999">
                                </div>
                                <div style="display:flex;align-items:flex-end;">
                                    <button class="btn btn-primary" type="submit">Simpan</button>
                                </div>
                            </form>
                        </div>
                    </details>
                    <% } %>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <script>
        (function () {
            function toggleBody(button, body, forceOpen) {
                if (!button || !body) {
                    return;
                }
                var isExpanded = button.getAttribute('aria-expanded') === 'true';
                var nextExpanded = typeof forceOpen === 'boolean' ? forceOpen : !isExpanded;
                button.setAttribute('aria-expanded', nextExpanded ? 'true' : 'false');
                body.classList.toggle('is-hidden', !nextExpanded);
            }

            var foldButtons = Array.prototype.slice.call(document.querySelectorAll('.settings-fold-btn, .template-block-head'));
            foldButtons.forEach(function (button) {
                var targetId = button.getAttribute('data-target');
                var body = targetId ? document.getElementById(targetId) : null;
                button.addEventListener('click', function () {
                    toggleBody(button, body);
                });
            });

            var statusPills = Array.prototype.slice.call(document.querySelectorAll('.status-pill[data-bg][data-text]'));
            statusPills.forEach(function (pill) {
                var bg = pill.getAttribute('data-bg') || '';
                var text = pill.getAttribute('data-text') || '';
                if (bg) {
                    pill.style.background = bg;
                }
                if (text) {
                    pill.style.color = text;
                }
            });

            var hash = window.location.hash || '';
            if (hash) {
                var targetCard = document.querySelector(hash + '.settings-card');
                if (!targetCard) {
                    targetCard = document.querySelector(hash);
                }
                if (targetCard) {
                    var parentCard = targetCard.classList.contains('settings-card')
                        ? targetCard
                        : targetCard.closest('.settings-card');
                    if (parentCard) {
                        var foldBtn = parentCard.querySelector('.settings-fold-btn');
                        var bodyId = foldBtn ? foldBtn.getAttribute('data-target') : null;
                        var body = bodyId ? document.getElementById(bodyId) : null;
                        toggleBody(foldBtn, body, true);
                        parentCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    }
                }
            }

            function insertAtCursor(input, text) {
                if (!input) {
                    return;
                }
                input.focus();
                var start = typeof input.selectionStart === 'number' ? input.selectionStart : input.value.length;
                var end = typeof input.selectionEnd === 'number' ? input.selectionEnd : input.value.length;
                var before = input.value.substring(0, start);
                var after = input.value.substring(end);
                input.value = before + text + after;
                var caret = start + text.length;
                if (typeof input.setSelectionRange === 'function') {
                    input.setSelectionRange(caret, caret);
                }
                input.dispatchEvent(new Event('input', { bubbles: true }));
            }

            var editors = Array.prototype.slice.call(document.querySelectorAll('.template-editor'));
            editors.forEach(function (editor) {
                editor.addEventListener('focus', function () {
                    var form = editor.closest('form');
                    if (!form) {
                        return;
                    }
                    if (editor.name) {
                        form.setAttribute('data-last-focused-editor', editor.name);
                    }
                });
            });

            var tokenButtons = Array.prototype.slice.call(document.querySelectorAll('.template-token-btn[data-template-token]'));
            tokenButtons.forEach(function (btn) {
                btn.addEventListener('click', function () {
                    var form = btn.closest('.template-detail-inner') ? btn.closest('.template-detail-inner').querySelector('form') : null;
                    if (!form) {
                        return;
                    }

                    var targetName = form.getAttribute('data-last-focused-editor');
                    var target = null;
                    if (targetName) {
                        target = form.querySelector('[name="' + targetName + '"]');
                    }
                    if (!target) {
                        target = form.querySelector('.template-editor');
                    }
                    insertAtCursor(target, btn.getAttribute('data-template-token') || '');
                });
            });
        })();
    </script>
    <script>
        (function () {
            function hasSuccessFlag() {
                var params = new URLSearchParams(window.location.search || '');
                for (var pair of params.entries()) {
                    var key = (pair[0] || '').toLowerCase();
                    var value = (pair[1] || '').toLowerCase();
                    if (key.indexOf('success') >= 0 || key.indexOf('saved') >= 0 || key.indexOf('updated') >= 0) {
                        if (value === '1' || value === 'true' || value === 'ok' || value === '') {
                            return true;
                        }
                    }
                }
                return false;
            }

            function resolveSuccessMessage() {
                var notice = document.querySelector('.announce-alert.announce-success');
                if (notice) {
                    var text = (notice.textContent || '').trim();
                    if (text) {
                        return text;
                    }
                }
                return '';
            }

            function showSuccessPopup(message) {
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
            }

            var message = resolveSuccessMessage();
            if (!message && !hasSuccessFlag()) {
                return;
            }
            if (!message) {
                message = 'Tetapan telah berjaya disimpan.';
            }
            showSuccessPopup(message);
        })();
    </script>
</body>
</html>

