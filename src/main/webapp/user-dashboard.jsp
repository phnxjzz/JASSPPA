<%-- NOTA ALIRAN KOD: Fail user-dashboard.jsp. Halaman ini dipaparkan oleh aliran /dashboard untuk pengguna role USER. Tujuan nota ni supaya orang seterusnya terus nampak konteks fail ni. --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%!
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

    private String statusCssClass(String status) {
        if (status == null) {
            return "";
        }
        return status.trim().toLowerCase(java.util.Locale.ROOT).replace(' ', '-').replace('_', '-');
    }

    private String displayStatusLabel(String status) {
        if (status == null) {
            return "";
        }
        String normalized = status.trim().toUpperCase(java.util.Locale.ROOT);
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
            return "PERMOHONAN DITERIMA";
        }
        if ("MENUNGGU_TINDAKAN_PENGARAH".equals(normalized)) {
            return "MENUNGGU TINDAKAN PENGARAH";
        }
        if (normalized.startsWith("MENUNGGU_SETERUSNYA_")) {
            return "MENUNGGU SETERUSNYA";
        }
        if ("DIRECTOR_REVIEW".equals(normalized) || "MENUNGGU_PENGARAH".equals(normalized) || "MENUNGGU PENGARAH".equals(normalized)) {
            return "MENUNGGU PENGARAH";
        }
        if ("IN_PROGRESS".equals(normalized) || "DALAM_PROSES".equals(normalized) || "DALAM PROSES".equals(normalized)) {
            return "DALAM PROSES";
        }
        return normalized.replace('_', ' ');
    }

    private String displayAccountStatus(Object statusObj) {
        if (statusObj == null) {
            return "Aktif";
        }
        String status = String.valueOf(statusObj).trim().toUpperCase(java.util.Locale.ROOT);
        if ("ACTIVE".equals(status) || "AKTIF".equals(status)) {
            return "Aktif";
        }
        if ("INACTIVE".equals(status) || "TIDAK AKTIF".equals(status) || "NONAKTIF".equals(status)) {
            return "Tidak Aktif";
        }
        if ("SUSPENDED".equals(status) || "DIGANTUNG".equals(status)) {
            return "Digantung";
        }
        return String.valueOf(statusObj);
    }

    private String formatCertificateNumber(Object value) {
        if (value == null) {
            return "-";
        }
        String raw = String.valueOf(value).trim();
        if (raw.isEmpty() || "null".equalsIgnoreCase(raw) || "-".equals(raw)) {
            return "-";
        }

        String compact = raw.replaceAll("\\s+", "").toUpperCase(java.util.Locale.ROOT);
        java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("^JANS([A-Z0-9]+)$", java.util.regex.Pattern.CASE_INSENSITIVE)
                .matcher(compact);
        if (matcher.find()) {
            String token = matcher.group(1).toUpperCase(java.util.Locale.ROOT);
            if (token.matches("\\d+") && token.length() < 6) {
                token = String.format("%06d", Integer.parseInt(token));
            }
            return "JANS" + token;
        }
        return compact;
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

    private String presentationInviteStatusLabel(Object statusObj) {
        if (statusObj == null) {
            return "MENUNGGU MAKLUM BALAS";
        }
        String status = String.valueOf(statusObj).trim().toUpperCase(java.util.Locale.ROOT);
        if ("HADIR".equals(status)) {
            return "HADIR";
        }
        if ("TIDAK_HADIR".equals(status) || "TIDAK HADIR".equals(status)) {
            return "TIDAK HADIR";
        }
        if ("MENUNGGU_PENJADUALAN_SEMULA".equals(status) || "MENUNGGU PENJADUALAN SEMULA".equals(status)) {
            return "MENUNGGU PENJADUALAN SEMULA";
        }
        if ("SELESAI".equals(status)) {
            return "SELESAI";
        }
        return "MENUNGGU MAKLUM BALAS";
    }
%>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Dashboard Pemohon - SPPPBA</title>
    <style>
:root {
            --brand-blue: #2A9D8F;
            --brand-navy: #0F6BAE;
            --brand-green: #6DBE45;
            --brand-lime: #CDE11D;
            --brand-yellow: #F2F72E;
            --brand-cyan: #6DBE45;
            --surface: #ffffff;
            --line: #d6e6f1;
            --text: #173040;
            --muted: #678090;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: inherit;
            color: var(--text);
            background:
                linear-gradient(rgba(247, 252, 255, 0.76), rgba(238, 246, 251, 0.82)),
                url('${pageContext.request.contextPath}/icon/dshbordpemohnbg.jpg') center center / cover no-repeat fixed;
        }
        .navbar {
            background: linear-gradient(120deg, var(--brand-navy) 0%, var(--brand-blue) 30%, var(--brand-green) 58%, var(--brand-lime) 80%, var(--brand-yellow) 100%);
            color: white;
            padding: 14px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            border-bottom: 3px solid rgba(255, 255, 255, 0.25);
        }
        .brand { display: flex; align-items: center; gap: 12px; }
        .brand-logo { width: 50px; height: 50px; object-fit: contain; }
        .brand h1 { margin: 0; font-size: 20px; letter-spacing: 0.02em; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.9; }
        .top-actions { display: flex; align-items: center; gap: 10px; }
        .welcome { font-size: 13px; opacity: 0.92; margin-right: 6px; }
        .nav-icon-link {
            width: 54px;
            height: 54px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            background: #0f4f8f;
            border: 2px solid #0b3f72;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22);
            color: #ffffff;
            text-decoration: none;
            transition: background 0.18s ease;
        }
        .nav-icon-link:hover { background: #1263b5; }
        .nav-icon {
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
        .nav-icon-svg {
            width: 28px;
            height: 28px;
            display: block;
            stroke: #ffffff;
            fill: none;
            stroke-width: 2.2;
            stroke-linecap: round;
            stroke-linejoin: round;
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
            transition: background 0.18s ease;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22);
            color: #ffffff;
            text-decoration: none;
        }
        .icon-link .icon-glyph { width: 30px; height: 30px; display: inline-flex; align-items: center; justify-content: center; font-family: "Segoe UI Symbol", "Noto Sans Symbols 2", sans-serif; font-size: 30px; font-weight: 700; line-height: 1; color: #ffffff; text-shadow: none; }
        .icon-link:hover { background: #1263b5; }
        .notif-icon { position: relative; }
        .notif-badge {
            position: absolute;
            top: -6px;
            right: -6px;
            min-width: 20px;
            height: 20px;
            padding: 0 5px;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: #ef4444;
            color: white;
            font-size: 11px;
            font-weight: 800;
            border: 2px solid rgba(255, 255, 255, 0.88);
            line-height: 1;
            box-shadow: 0 5px 14px rgba(190, 24, 24, 0.35);
        }

        .container { max-width: 1180px; margin: 28px auto; padding: 0 20px 34px; }
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 14px;
            margin-bottom: 22px;
        }
        .stat-card {
            border: none;
            border-radius: 16px;
            padding: 16px;
            box-shadow: 0 12px 26px rgba(6, 52, 79, 0.08);
            transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
            animation: floatShadow 4.2s ease-in-out infinite;
            text-align: center;
        }
        .stat-card:nth-child(1) {
            background: linear-gradient(165deg, #B0E0E6 0%, #A8D8E8 100%);
        }
        .stat-card:nth-child(2) {
            background: linear-gradient(165deg, #FFB6D9 0%, #FFC0E0 100%);
        }
        .stat-card:nth-child(3) {
            background: linear-gradient(165deg, #FFFFE0 0%, #FFFACD 100%);
        }
        .stat-card:nth-child(4) {
            background: linear-gradient(165deg, #A8E6A1 0%, #98FB98 100%);
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 18px 34px rgba(6, 52, 79, 0.16);
        }
        .stat-card h3 {
            margin: 0 0 7px;
            color: var(--brand-navy);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            text-align: center;
        }
        .stat-card .num { font-size: 28px; font-weight: 800; color: #000102; text-align: center; }

        .feature-shell {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: 20px;
            padding: 20px;
            box-shadow: 0 16px 38px rgba(6, 52, 79, 0.1);
            position: relative;
        }
        .feature-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 14px;
        }
        .feature-header h3 { margin: 0; font-size: 19px; color: #0d4b71; }
        .feature-header p { margin: 4px 0 0; color: var(--muted); font-size: 13px; }

        .arrow-btn {
            width: 42px;
            height: 42px;
            border-radius: 999px;
            border: 1px solid #cfe0ed;
            background: #eef6fc;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: transform 0.15s ease, background 0.15s ease;
            position: absolute;
            top: 50%;
            z-index: 3;
        }
        .arrow-btn .icon-glyph { width: 20px; height: 20px; display: inline-flex; align-items: center; justify-content: center; font-size: 20px; line-height: 1; }
        .arrow-btn:hover { transform: translateY(-1px); background: #dfeef8; }
        .arrow-left { left: -20px; }
        .arrow-right { right: -20px; }

        .carousel-window {
            width: 100%;
            height: 600px;
            position: relative;
            overflow: hidden;
        }
        .carousel-track {
            position: relative;
            width: 100%;
            height: 100%;
        }
        .feature-page {
            position: absolute;
            top: 50%;
            left: 50%;
            width: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
            transition: transform 0.55s cubic-bezier(0.2, 0.75, 0.2, 1), opacity 0.35s ease;
        }
        .feature-card {
            position: relative;
            border-radius: 18px;
            padding: 22px;
            width: clamp(260px, 30vw, 360px);
            aspect-ratio: 3 / 4;
            background:
                radial-gradient(420px 180px at 92% -14%, rgba(255,255,255,0.65) 0%, rgba(255,255,255,0) 62%),
                linear-gradient(152deg, #0c527d 0%, #0d6fa7 58%, #19adc8 115%);
            color: white;
            border: none;
            box-shadow: 0 18px 38px rgba(7, 62, 92, 0.28);
            transition: transform 0.22s ease, box-shadow 0.22s ease;
            overflow: hidden;
            animation: floatShadow 4.8s ease-in-out infinite;
            display: flex;
            flex-direction: column;
        }
        .feature-card::before {
            content: "";
            position: absolute;
            inset: 0;
            border-radius: 18px;
            background-image: var(--card-bg);
            background-size: cover;
            background-position: center;
            opacity: 0.22;
            z-index: 0;
        }
        .feature-card > * { position: relative; z-index: 1; }
        .feature-card::after {
            content: "";
            position: absolute;
            width: 220px;
            height: 220px;
            right: -65px;
            bottom: -95px;
            background: rgba(255, 255, 255, 0.17);
            border-radius: 50%;
            z-index: 0;
            pointer-events: none;
        }
        .feature-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 28px 50px rgba(7, 62, 92, 0.36);
        }
        .feature-card h4 { margin: 0 0 14px; font-size: 32px; line-height: 1.15; letter-spacing: 0.01em; text-align: center; }
        .feature-card p { margin: 0 auto; max-width: 620px; font-size: 16px; line-height: 1.6; color: rgba(255,255,255,0.95); text-align: center; }
        .feature-badges { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 16px; }
        .feature-badge {
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255,255,255,0.34);
            border-radius: 999px;
            padding: 7px 12px;
            font-size: 12px;
            font-weight: 700;
        }
        .feature-actions { display: flex; gap: 10px; margin-top: auto; padding-top: 18px; flex-wrap: wrap; }
        .cta {
            text-decoration: none;
            border-radius: 12px;
            padding: 10px 15px;
            font-weight: 700;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 7px;
            border: 1px solid rgba(255,255,255,0.6);
            transition: transform 0.14s ease, background 0.14s ease;
        }
        .cta:hover { transform: translateY(-1px); }
        .cta-primary { background: white; color: #0d4f77; }
        .cta-secondary { background: rgba(255,255,255,0.16); color: white; }

        .page-indicator {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 7px;
            margin-top: 14px;
        }
        .dot {
            width: 8px;
            height: 8px;
            border-radius: 999px;
            background: #c2d8e8;
            transition: width 0.2s ease, background 0.2s ease;
        }
        .dot.active { width: 24px; background: #0d6fa7; }

        @keyframes floatShadow {
            0% { box-shadow: 0 14px 30px rgba(6, 52, 79, 0.14); }
            50% { box-shadow: 0 24px 44px rgba(6, 52, 79, 0.22); }
            100% { box-shadow: 0 14px 30px rgba(6, 52, 79, 0.14); }
        }

        .notif-modal {
            position: fixed;
            inset: 0;
            background: rgba(6, 30, 44, 0.5);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 999;
            padding: 18px;
        }
        .notif-modal.active { display: flex; }
        .notif-panel {
            width: min(620px, 100%);
            max-height: 78vh;
            overflow: auto;
            background: #ffffff;
            border: 1px solid #cfe0ed;
            border-radius: 16px;
            box-shadow: 0 24px 48px rgba(6, 52, 79, 0.28);
            padding: 18px;
        }
        .notif-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .notif-head h4 { margin: 0; font-size: 18px; color: #0d4b71; }
        .notif-close {
            border: 1px solid #d3e3ef;
            background: #f1f7fc;
            border-radius: 999px;
            width: 34px;
            height: 34px;
            cursor: pointer;
            font-size: 16px;
        }
        .notif-item {
            border: 1px solid #deebf4;
            background: #f9fcff;
            border-radius: 12px;
            padding: 10px 12px;
            margin-bottom: 9px;
        }
        .notif-item strong { color: #0b577f; }
        .notif-time { color: var(--muted); font-size: 12px; margin-top: 4px; }

        .app-modal {
            position: fixed;
            inset: 0;
            background: rgba(6, 30, 44, 0.5);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 999;
            padding: 18px;
        }
        .app-modal.active { display: flex; }
        .app-panel {
            width: min(820px, 100%);
            max-height: 82vh;
            overflow: auto;
            background: #ffffff;
            border: 1px solid #cfe0ed;
            border-radius: 16px;
            box-shadow: 0 24px 48px rgba(6, 52, 79, 0.28);
            padding: 20px;
        }
        .app-panel-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
        }
        .app-panel-head h4 { margin: 0; font-size: 18px; color: #0d4b71; }
        .app-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .app-table th {
            background: #eef6fc;
            color: #0d4b71;
            padding: 9px 10px;
            text-align: left;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .app-table td { padding: 9px 10px; border-bottom: 1px solid #e5f0f8; vertical-align: top; }
        .app-table tr:last-child td { border-bottom: none; }
        .cert-action-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border: 1px solid #0d6fa7;
            background: #0d6fa7;
            color: #ffffff;
            border-radius: 8px;
            padding: 6px 10px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .cert-action-btn:hover { background: #0b5f90; border-color: #0b5f90; }
        .cert-action-btn:disabled {
            background: #cbd5e1;
            border-color: #cbd5e1;
            color: #475569;
            cursor: not-allowed;
        }
        .certificate-view-panel {
            width: min(1100px, 100%);
            height: min(88vh, 900px);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            padding: 0;
        }
        .certificate-view-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 14px 16px;
            border-bottom: 1px solid #dbe7f1;
            background: #f7fbff;
        }
        .certificate-view-head h4 { margin: 0; font-size: 17px; color: #0d4b71; }
        .certificate-frame {
            width: 100%;
            height: 100%;
            border: 0;
            background: #ffffff;
            flex: 1;
        }
        .status-badge {
            display: inline-block;
            padding: 3px 9px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }
        .status-badge.pending { background: #fff3cd; color: #856404; }
        .status-badge.approved { background: #d1e7dd; color: #0a5a3c; }
        .status-badge.rejected { background: #f8d7da; color: #842029; }
        .status-badge.under_review { background: #cfe2ff; color: #084298; }
        .status-badge.in_progress { background: #fde68a; color: #92400e; }
        .status-badge.new { background: #dbeafe; color: #1e40af; }
        .status-badge.draft { background: #e5e7eb; color: #374151; }
        .important-alert {
            margin-bottom: 16px;
            border: 1px solid #fbbf24;
            background: #fff7d6;
            color: #7c2d12;
            border-radius: 12px;
            padding: 12px 14px;
            box-shadow: 0 8px 18px rgba(124, 45, 18, 0.08);
        }
        .important-alert strong {
            display: block;
            margin-bottom: 4px;
            font-size: 14px;
        }
        .history-group { margin-bottom: 16px; border: 1px solid #d6e6f1; border-radius: 10px; overflow: hidden; }
        .history-group-head { background: #eef6fc; padding: 8px 12px; font-size: 13px; font-weight: 700; color: #0d4b71; }
        .history-row { display: flex; gap: 10px; padding: 8px 12px; border-top: 1px solid #e5f0f8; font-size: 13px; align-items: flex-start; }
        .history-arrow { color: #0d6fa7; font-weight: 700; margin: 0 4px; }

        @media (max-width: 940px) {
            .stat-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .brand h1 { font-size: 18px; }
            .carousel-window { height: 560px; }
            .feature-card { width: clamp(240px, 60vw, 320px); }
            .arrow-left { left: -12px; }
            .arrow-right { right: -12px; }
        }
        @media (max-width: 640px) {
            .navbar { flex-direction: column; align-items: flex-start; }
            .top-actions { width: 100%; justify-content: space-between; }
            .stat-grid { grid-template-columns: 1fr; }
            .carousel-window { height: 520px; }
            .feature-card { width: min(82vw, 320px); }
            .feature-card h4 { font-size: 24px; }
            .arrow-btn { top: auto; bottom: -54px; }
            .arrow-left { left: calc(50% - 56px); }
            .arrow-right { right: calc(50% - 56px); }
            .page-indicator { margin-top: 62px; }
            .app-floating-actions {
                right: 10px;
                bottom: 12px;
            }
            .app-floating-link {
                width: 50px;
                height: 50px;
            }
            .app-floating-link .icon-glyph {
                width: 22px;
                height: 22px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                font-size: 22px;
                line-height: 1;
            }
        }
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
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; display: inline-flex; align-items: center; gap: 8px; }
        .contact-line { display: flex; align-items: flex-start; gap: 8px; margin: 7px 0; font-size: 13px; color: #4e6a7c; line-height: 1.45; }
        .contact-icon { width: 13px; height: 13px; display: inline-flex; align-items: center; justify-content: center; font-size: 12px; line-height: 1; flex-shrink: 0; margin-top: 2px; }
        .contact-address-link { color: #0f6bae; text-decoration: underline; text-underline-offset: 3px; font-weight: 600; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-line-hanging { margin-left: 21px; }
        .contact-address-link:hover { color: #0d4f77; }

        .presentation-popup {
            position: fixed;
            inset: 0;
            z-index: 1400;
            background: rgba(2, 6, 23, 0.62);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .presentation-popup.show { display: flex; }
        .presentation-popup-card {
            width: min(760px, 100%);
            max-height: calc(100vh - 32px);
            overflow: auto;
            background: #ffffff;
            border-radius: 14px;
            border: 1px solid #cfe2f1;
            box-shadow: 0 24px 58px rgba(15, 23, 42, 0.34);
            padding: 18px;
        }
        .presentation-popup-card h3 {
            margin: 0 0 10px;
            color: #0f6bae;
            font-size: 20px;
        }
        .presentation-popup-message {
            color: #334155;
            line-height: 1.6;
            font-size: 14px;
            white-space: pre-wrap;
            margin-bottom: 14px;
        }
        .presentation-popup-schedule {
            margin: 8px 0 14px;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .presentation-popup-schedule div {
            color: #15803d;
            font-weight: 700;
            font-size: 14px;
            line-height: 1.4;
        }
        .presentation-popup-actions { display: flex; justify-content: flex-end; }

        .decision-popup {
            position: fixed;
            inset: 0;
            z-index: 1410;
            background: rgba(2, 6, 23, 0.62);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .decision-popup.show { display: flex; }
        .decision-popup-card {
            width: min(520px, 100%);
            background: #ffffff;
            border-radius: 14px;
            border: 1px solid #cfe2f1;
            box-shadow: 0 24px 58px rgba(15, 23, 42, 0.34);
            padding: 20px 18px;
            text-align: center;
            position: relative;
        }
        .decision-popup.approved .decision-popup-card {
            border-color: #b8e7c6;
            box-shadow: 0 18px 40px rgba(10, 64, 38, 0.2);
        }
        .decision-popup-icon {
            width: 88px;
            height: 88px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 72px;
            line-height: 1;
            margin: 0 auto 8px;
            color: #15803d;
        }
        .decision-popup-title {
            margin: 0 0 10px;
            font-size: 24px;
            line-height: 1.2;
            color: #0f5132;
            font-weight: 800;
        }
        .decision-popup-message {
            margin: 0;
            color: #334155;
            font-size: 16px;
            line-height: 1.5;
        }
        .decision-popup-status {
            color: #b91c1c;
            font-weight: 800;
        }
        .decision-popup-actions {
            margin-top: 14px;
            display: flex;
            justify-content: center;
        }
        .decision-popup-btn {
            border: 1px solid #0f5132;
            background: #166534;
            color: #fff;
            border-radius: 10px;
            padding: 10px 22px;
            font-size: 14px;
            font-weight: 700;
            cursor: pointer;
        }
        .decision-popup-close {
            position: absolute;
            top: 10px;
            right: 10px;
            width: 36px;
            height: 36px;
            border: 1px solid #fecaca;
            background: #fff1f2;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            padding: 0;
        }
        .decision-popup-close .icon-glyph {
            width: 18px;
            height: 18px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            line-height: 1;
        }
        .invite-response-panel {
            margin-bottom: 16px;
            border: 1px solid #cfe2f1;
            background: #ffffff;
            border-radius: 14px;
            padding: 14px;
            box-shadow: 0 10px 24px rgba(6, 52, 79, 0.12);
        }
        .invite-response-head {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            align-items: flex-start;
            margin-bottom: 10px;
        }
        .invite-response-head h3 {
            margin: 0;
            color: #0f6bae;
            font-size: 17px;
        }
        .invite-response-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 10px;
            margin-bottom: 10px;
        }
        .invite-response-field label {
            display: block;
            font-size: 12px;
            color: #64748b;
            margin-bottom: 4px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .invite-response-field .value {
            min-height: 38px;
        }
        .invite-response-actions {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }
        .invite-response-form {
            border: 1px solid #d8e7f2;
            border-radius: 10px;
            background: #f8fcff;
            padding: 10px;
            display: grid;
            gap: 8px;
        }
        .invite-response-form h4 {
            margin: 0;
            color: #0f4f79;
            font-size: 14px;
        }
        .invite-response-form input,
        .invite-response-form textarea {
            width: 100%;
            border: 1px solid #cddfeb;
            border-radius: 8px;
            background: #fff;
            padding: 9px 10px;
            font: inherit;
            font-size: 13px;
        }
        .invite-response-form textarea {
            min-height: 90px;
            resize: vertical;
        }
        .invite-response-btn {
            border: 1px solid #fff;
            border-radius: 9px;
            padding: 10px 12px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            color: #fff;
        }
        .invite-response-btn.hadir { background: #15803d; }
        .invite-response-btn.tidak-hadir { background: #b91c1c; }
        .dashboard-main.is-locked {
            pointer-events: none;
            user-select: none;
            filter: blur(2.5px);
        }
        .invite-gate-active {
            overflow: hidden;
        }
        .invite-gate-overlay {
            position: fixed;
            inset: 0;
            z-index: 2100;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 18px;
            background: rgba(7, 30, 45, 0.55);
            backdrop-filter: blur(2px);
        }
        .invite-gate-card {
            width: min(960px, 100%);
            max-height: calc(100vh - 36px);
            overflow: auto;
            border-radius: 14px;
            border: 1px solid #cfe2f1;
            background: #ffffff;
            box-shadow: 0 26px 52px rgba(6, 52, 79, 0.3);
            padding: 14px;
        }
        @media (max-width: 900px) {
            .invite-response-grid { grid-template-columns: 1fr; }
            .invite-response-actions { grid-template-columns: 1fr; }
            .invite-gate-overlay {
                align-items: flex-start;
                padding-top: 10px;
            }
        }

        .app-floating-actions {
            position: fixed;
            right: 16px;
            bottom: 18px;
            z-index: 920;
            display: block;
        }
        .app-floating-link {
            width: 56px;
            height: 56px;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border: 1px solid #d8e7f2;
            background: #ffffff;
            color: #0f5f96;
            text-decoration: none;
            box-shadow: 0 14px 28px rgba(6, 52, 79, 0.22);
            transition: transform 0.18s ease, box-shadow 0.18s ease;
        }
        .app-floating-link .icon-glyph {
            width: 24px;
            height: 24px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            line-height: 1;
            filter: drop-shadow(0 1px 2px rgba(15, 95, 150, 0.22));
        }
        .app-floating-link:hover {
            transform: translateY(-3px);
            box-shadow: 0 18px 32px rgba(6, 52, 79, 0.28);
        }
        .app-floating-link span {
            display: none;
        }

        
    </style>
</head>
<body>
<%
    Object unreadObj = request.getAttribute("unread_notification_count");
    int unreadCount = 0;
    if (unreadObj != null) {
        try {
            unreadCount = Integer.parseInt(String.valueOf(unreadObj));
        } catch (Exception ignored) {
            unreadCount = 0;
        }
    }

    java.util.Map<String, Object> decisionPopup =
            (java.util.Map<String, Object>) request.getAttribute("decision_popup");
    boolean decisionPopupEnabled = Boolean.TRUE.equals(request.getAttribute("user_decision_popup_enabled"));
    String decisionPopupMessage = decisionPopup == null || decisionPopup.get("message") == null
            ? ""
            : String.valueOf(decisionPopup.get("message")).trim();
    String decisionPopupType = decisionPopup == null || decisionPopup.get("type") == null
            ? ""
            : String.valueOf(decisionPopup.get("type")).trim().toUpperCase(java.util.Locale.ROOT);
    boolean showDecisionPopup = decisionPopupEnabled && !decisionPopupMessage.isBlank();
    String decisionStatusWord = "";
    String decisionUpperMessage = decisionPopupMessage.toUpperCase(java.util.Locale.ROOT);
    if (showDecisionPopup) {
        if (decisionUpperMessage.contains("DILULUSKAN") || "SUCCESS".equals(decisionPopupType)) {
            decisionStatusWord = "DILULUSKAN";
        } else if (decisionUpperMessage.contains("DITOLAK") || "ERROR".equals(decisionPopupType)) {
            decisionStatusWord = "DITOLAK";
        } else if (decisionUpperMessage.contains("DIGANTUNG") || "WARNING".equals(decisionPopupType)) {
            decisionStatusWord = "DIGANTUNG";
        } else if (decisionUpperMessage.contains("DIBATAL")) {
            decisionStatusWord = "DIBATALKAN";
        } else {
            showDecisionPopup = false;
        }
    }
    boolean decisionPopupApproved = "DILULUSKAN".equals(decisionStatusWord);
    String decisionApproveIconSetting = request.getAttribute("user_decision_popup_approve_icon") == null
            ? "/icon/stamp.gif"
            : String.valueOf(request.getAttribute("user_decision_popup_approve_icon")).trim();
    String decisionRejectIconSetting = request.getAttribute("user_decision_popup_reject_icon") == null
            ? "/icon/exit.png"
            : String.valueOf(request.getAttribute("user_decision_popup_reject_icon")).trim();
    String decisionApproveButtonText = request.getAttribute("user_decision_popup_approve_button_text") == null
            ? "Lihat Perakuan"
            : String.valueOf(request.getAttribute("user_decision_popup_approve_button_text")).trim();
    String decisionApproveIcon = decisionApproveIconSetting.startsWith("/")
            ? request.getContextPath() + decisionApproveIconSetting
            : request.getContextPath() + "/" + decisionApproveIconSetting;
    String decisionRejectIcon = decisionRejectIconSetting.startsWith("/")
            ? request.getContextPath() + decisionRejectIconSetting
            : request.getContextPath() + "/" + decisionRejectIconSetting;

        java.util.Map<String, Object> presentationPopup =
            (java.util.Map<String, Object>) request.getAttribute("presentation_popup");
        java.util.Map<String, Object> activePresentationInvite =
            (java.util.Map<String, Object>) request.getAttribute("active_presentation_invite");
        String activeInviteStatus = activePresentationInvite == null || activePresentationInvite.get("invite_status") == null
            ? ""
            : String.valueOf(activePresentationInvite.get("invite_status")).trim().toUpperCase(java.util.Locale.ROOT);
        boolean requireInviteResponse = activePresentationInvite != null
            && (activeInviteStatus.isEmpty()
                || "MENUNGGU_MAKLUM_BALAS".equals(activeInviteStatus)
                || "MENUNGGU MAKLUM BALAS".equals(activeInviteStatus)
                || "PENDING".equals(activeInviteStatus));
        request.setAttribute("require_invite_response", requireInviteResponse);
        String presentationResponseStatus = request.getParameter("presentation_response");
        String presentationPopupMessage = presentationPopup == null || presentationPopup.get("message") == null
            ? null
            : String.valueOf(presentationPopup.get("message"));
        String presentationMainText = presentationPopupMessage;
        java.util.List<String> presentationScheduleLines = new java.util.ArrayList<>();
        if (presentationPopupMessage != null) {
            String[] popupLines = presentationPopupMessage.split("\\r?\\n");
            StringBuilder mainBuilder = new StringBuilder();
            for (String rawLine : popupLines) {
                String line = rawLine == null ? "" : rawLine.trim();
                if (line.isEmpty()) {
                    continue;
                }
                String upper = line.toUpperCase(java.util.Locale.ROOT);
                if (upper.startsWith("TARIKH:") || upper.startsWith("MASA:") || upper.startsWith("TEMPAT:")) {
                    presentationScheduleLines.add(line);
                } else if (upper.startsWith("NOTA PENTADBIR:")) {
                    continue;
                } else {
                    if (mainBuilder.length() > 0) {
                        mainBuilder.append(' ');
                    }
                    mainBuilder.append(line);
                }
            }
            presentationMainText = mainBuilder.toString();
        }

    java.util.List<java.util.Map<String, Object>> userApplications =
            (java.util.List<java.util.Map<String, Object>>) request.getAttribute("applications");
    int inProgressCount = 0;
    if (userApplications != null) {
        for (java.util.Map<String, Object> app : userApplications) {
            String appStatus = app.get("status") == null ? "" : String.valueOf(app.get("status"));
            if ("IN_PROGRESS".equals(appStatus)) {
                inProgressCount++;
            }
        }
    }
%>
<div class="navbar">
    <div class="brand">
        <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo JANS">
        <div>
            <h1>Dashboard Pemohon</h1>
            <p>Sistem Pendaftaran Pembekal dan Produk Bekalan Air - Jabatan Air Sabah</p>
        </div>
    </div>
    <div class="top-actions">
        <span class="welcome">Selamat datang, <strong><%= session.getAttribute("username") %></strong></span>
        <a class="icon-link notif-icon" href="#" id="notifShortcut" title="Pemberitahuan" aria-label="Pemberitahuan">
            <span class="icon-glyph" aria-hidden="true">&#128276;</span>
            <% if (unreadCount > 0) { %>
                <span class="notif-badge"><%= unreadCount > 99 ? "99+" : unreadCount %></span>
            <% } %>
        </a>
        <a class="nav-icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama">
            <svg class="nav-icon-svg" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M3 10.5L12 3l9 7.5"></path>
                <path d="M5.5 9.5V21h13V9.5"></path>
            </svg>
        </a>
        <a class="nav-icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar">
            <svg class="nav-icon-svg" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M10 5H5v14h5"></path>
                <path d="M13 12h8"></path>
                <path d="M18 8l4 4-4 4"></path>
            </svg>
        </a>
    </div>
</div>

<div class="container dashboard-main <%= requireInviteResponse ? "is-locked" : "" %>">
    <% if ("ok".equalsIgnoreCase(presentationResponseStatus)) { %>
    <div class="important-alert" role="status" aria-live="polite">
        <strong>Maklum balas berjaya dihantar</strong>
        Terima kasih. Maklum balas anda telah direkodkan dan dihantar kepada pentadbir.
    </div>
    <% } else if (presentationResponseStatus != null && !presentationResponseStatus.isBlank()) { %>
    <div class="important-alert" role="alert" aria-live="assertive">
        <strong>Maklum balas tidak lengkap</strong>
        Sila semak semula borang Hadir/Tidak Hadir dan hantar sekali lagi.
    </div>
    <% } %>

    <% if (inProgressCount > 0) { %>
    <div class="important-alert" role="alert" aria-live="polite">
        <strong>&#9888; Perhatian: Tindakan Susulan Permohonan</strong>
        Sila bawa semua dokumen sokongan asal/lengkap dan hadir untuk sesi pembentangan produk yang ingin didaftarkan mengikut arahan Jabatan Air Sabah.
        <% if (inProgressCount > 1) { %>
        <div style="margin-top:4px;">Jumlah permohonan dalam status ini: <strong><%= inProgressCount %></strong></div>
        <% } %>
    </div>
    <% } %>

    <div class="stat-grid">
        <div class="stat-card">
            <h3>Jumlah Permohonan</h3>
            <div class="num"><%= request.getAttribute("application_count") == null ? "0" : request.getAttribute("application_count") %></div>
        </div>
        <div class="stat-card">
            <h3>Dalam Proses</h3>
            <div class="num"><%= inProgressCount > 0 ? inProgressCount : (request.getAttribute("user_in_progress_count") != null ? request.getAttribute("user_in_progress_count") : "0") %></div>
        </div>
        <div class="stat-card">
            <h3>Pembentangan</h3>
            <div class="num"><%= request.getAttribute("presentation_count") != null ? request.getAttribute("presentation_count") : request.getAttribute("user_presentation_count") != null ? request.getAttribute("user_presentation_count") : "0" %></div>
        </div>
        <div class="stat-card">
            <h3>Lulus</h3>
            <div class="num"><%= request.getAttribute("user_approved_count") != null ? request.getAttribute("user_approved_count") : request.getAttribute("user_approved") != null ? request.getAttribute("user_approved") : "0" %></div>
        </div>
    </div>

    <div class="feature-shell">
        <div class="feature-header"></div>

        <button type="button" class="arrow-btn arrow-left" id="arrowLeft" aria-label="Feature sebelum">
            <span class="icon-glyph" aria-hidden="true">&#10094;</span>
        </button>
        <button type="button" class="arrow-btn arrow-right" id="arrowRight" aria-label="Feature seterusnya">
            <span class="icon-glyph" aria-hidden="true">&#10095;</span>
        </button>

        <div class="carousel-window">
            <div class="carousel-track" id="featureTrack">
                <div class="feature-page">
                    <div class="feature-card" style="--card-bg: url('${pageContext.request.contextPath}/assets/images/application.webp')">
                        <h4>Permohonan Saya</h4>
                        <p>Semak status permohonan, tindakan pentadbir, dan kemajuan semasa untuk semua rekod yang pernah dihantar.</p>
                        <div class="feature-actions">
                            <a class="cta cta-primary" href="${pageContext.request.contextPath}/applications/new">Permohonan Baru</a>
                            <a class="cta cta-secondary" href="#" id="openAppListBtn">Lihat Permohonan</a>
                        </div>
                    </div>
                </div>


                <div class="feature-page" id="feature-notifications">
                    <div class="feature-card" style="animation-delay:0.8s; --card-bg: url('${pageContext.request.contextPath}/assets/images/notification-bg.jpg')">
                        <h4>Pemberitahuan & Sejarah</h4>
                        <p>Semak notifikasi terkini sistem dan sejarah perubahan status permohonan dari pihak pentadbir.</p>
                        <div class="feature-actions">
                            <a class="cta cta-primary" href="#" id="openNotifBtn">Pemberitahuan</a>
                            <a class="cta cta-secondary" href="#" id="openHistoryBtn">Rekod Status</a>
                            <a class="cta cta-secondary" href="#" id="openPresentationBtn">Pembentangan</a>
                        </div>
                    </div>
                </div>

                <div class="feature-page">
                    <div class="feature-card" style="animation-delay:1.2s; --card-bg: url('${pageContext.request.contextPath}/assets/images/user.webp')">
                        <h4>Profil &amp; Sijil</h4>
                        <p>Kemaskini butiran akaun, maklumat peribadi, dan semak semua sijil pendaftaran produk air yang telah diluluskan.</p>
                        <div class="feature-actions">
                            <a class="cta cta-primary" href="${pageContext.request.contextPath}/profile">Kemaskini Profil</a>
                            <a class="cta cta-secondary" href="#" id="openCertificateListBtn">Lihat Sijil</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="page-indicator" id="pageIndicator">
            <span class="dot active"></span>
            <span class="dot"></span>
            <span class="dot"></span>
        </div>
    </div>
</div>

<% if (requireInviteResponse) { %>
<div class="invite-gate-overlay" id="inviteGateOverlay" aria-hidden="false">
    <div class="invite-gate-card" role="dialog" aria-modal="true" aria-label="Jemputan pembentangan terkini">
        <div class="invite-response-head">
            <div>
                <h3>Jemputan Pembentangan Terkini</h3>
                <div style="color:#5b7485;font-size:13px;">Sila pilih Hadir atau Tidak Hadir untuk maklum balas rasmi.</div>
            </div>
            <span class="status-badge in_progress"><%= presentationInviteStatusLabel(activePresentationInvite.get("invite_status")) %></span>
        </div>

        <% if (presentationResponseStatus != null && !presentationResponseStatus.isBlank() && !"ok".equalsIgnoreCase(presentationResponseStatus)) { %>
        <div class="important-alert" role="alert" aria-live="assertive" style="margin-top:8px; margin-bottom:12px;">
            <strong>Maklum balas tidak lengkap</strong>
            Sila semak semula borang Hadir/Tidak Hadir dan hantar sekali lagi.
        </div>
        <% } %>

        <div class="invite-response-grid">
            <div class="invite-response-field">
                <label>Produk/Permohonan</label>
                <div class="value"><%= activePresentationInvite.get("product_name") == null ? "-" : activePresentationInvite.get("product_name") %></div>
            </div>
            <div class="invite-response-field">
                <label>Tarikh & Masa</label>
                <div class="value">
                    <%= activePresentationInvite.get("presentation_date") == null ? "-" : activePresentationInvite.get("presentation_date") %>
                    <br>
                    <%= activePresentationInvite.get("presentation_time") == null ? "-" : activePresentationInvite.get("presentation_time") %>
                </div>
            </div>
            <div class="invite-response-field">
                <label>Tempat</label>
                <div class="value"><%= activePresentationInvite.get("presentation_venue") == null ? "-" : activePresentationInvite.get("presentation_venue") %></div>
            </div>
        </div>
        <div class="invite-response-field" style="margin-bottom:10px;">
            <label>Memo Pentadbir</label>
            <div class="value"><pre style="margin:0;white-space:pre-wrap;font-family:inherit;"><%= activePresentationInvite.get("applicant_memo") == null ? "-" : activePresentationInvite.get("applicant_memo") %></pre></div>
        </div>

        <div class="invite-response-actions">
            <form class="invite-response-form" method="post" action="${pageContext.request.contextPath}/dashboard">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="presentation_invite_id" value="<%= activePresentationInvite.get("id") %>">
                <input type="hidden" name="presentation_response_action" value="HADIR">
                <h4>Hadir</h4>
                <input type="text" name="presentation_rep_name" placeholder="Nama wakil yang hadir" required>
                <input type="number" name="presentation_attendee_count" min="1" placeholder="Bilangan peserta yang hadir" required>
                <button type="submit" class="invite-response-btn hadir">Hantar Maklum Balas Hadir</button>
            </form>

            <form class="invite-response-form" method="post" action="${pageContext.request.contextPath}/dashboard">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="presentation_invite_id" value="<%= activePresentationInvite.get("id") %>">
                <input type="hidden" name="presentation_response_action" value="TIDAK_HADIR">
                <h4>Tidak Hadir</h4>
                <textarea name="presentation_absence_reason" placeholder="Sebab tidak hadir" required></textarea>
                <button type="submit" class="invite-response-btn tidak-hadir">Hantar Maklum Balas Tidak Hadir</button>
            </form>
        </div>
    </div>
</div>
<% } %>


<div class="app-modal" id="appListModal" aria-hidden="true">
    <div class="app-panel" role="dialog" aria-modal="true" aria-label="Senarai Permohonan">
        <div class="app-panel-head">
            <h4>Senarai Permohonan Saya</h4>
            <button class="notif-close" type="button" id="appListClose" aria-label="Tutup">x</button>
        </div>
        <%
            if (userApplications == null || userApplications.isEmpty()) {
        %>
            <div class="notif-item">Tiada permohonan ditemui.</div>
        <% } else { %>
            <table class="app-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Nama Produk</th>
                        <th>Syarikat</th>
                        <th>Status</th>
                        <th>Tarikh Hantar</th>
                        <th>Tindakan</th>
                    </tr>
                </thead>
                <tbody>
                <%  for (java.util.Map<String, Object> app : userApplications) {
                        String appStatus = app.get("status") == null ? "" : String.valueOf(app.get("status"));
                %>
                    <tr>
                        <td><%= String.format("PPP%03d", ((Number)app.get("id")).intValue()) %></td>
                        <td><%= app.get("product_name") == null ? "-" : app.get("product_name") %></td>
                        <td><%= app.get("company_name") == null ? "-" : app.get("company_name") %></td>
                        <td><span class="status-badge <%= statusCssClass(appStatus) %>"><%= displayStatusLabel(appStatus) %></span></td>
                        <td><%= app.get("submitted_at") == null ? "-" : formatDateTimeValue(app.get("submitted_at")) %></td>
                        <td>
                            <a href="${pageContext.request.contextPath}/applications/<%= app.get("id") %>" style="color:#0d6fa7;font-weight:700;text-decoration:none;">Lihat</a>
                            <% if ("APPROVED".equalsIgnoreCase(appStatus)) { %>
                                <span style="color:#8aa0b2; margin: 0 6px;">|</span>
                                <a href="${pageContext.request.contextPath}/applications/new?renewFrom=<%= app.get("id") %>" style="color:#15803d;font-weight:700;text-decoration:none;">Pembaharuan</a>
                            <% } %>
                        </td>
                    </tr>
                <%  } %>
                </tbody>
            </table>
        <% } %>
    </div>
</div>

<div class="app-modal" id="certificateListModal" aria-hidden="true">
    <div class="app-panel" role="dialog" aria-modal="true" aria-label="Senarai Sijil">
        <div class="app-panel-head">
            <h4>Senarai Sijil Produk Diluluskan</h4>
            <button class="notif-close" type="button" id="certificateListClose" aria-label="Tutup">x</button>
        </div>
        <%
            boolean hasApprovedCertificates = false;
            if (userApplications != null) {
                for (java.util.Map<String, Object> app : userApplications) {
                    String appStatus = app.get("status") == null ? "" : String.valueOf(app.get("status"));
                    if ("APPROVED".equalsIgnoreCase(appStatus)) {
                        hasApprovedCertificates = true;
                        break;
                    }
                }
            }
            if (!hasApprovedCertificates) {
        %>
            <div class="notif-item">Tiada sijil untuk dipaparkan kerana tiada permohonan diluluskan.</div>
        <% } else { %>
            <table class="app-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>No Sijil</th>
                        <th>Nama Produk</th>
                        <th>Syarikat</th>
                        <th>Status</th>
                        <th>Tindakan</th>
                    </tr>
                </thead>
                <tbody>
                <%  for (java.util.Map<String, Object> app : userApplications) {
                        String appStatus = app.get("status") == null ? "" : String.valueOf(app.get("status"));
                        String certNo = formatCertificateNumber(app.get("certificate_number"));
                        if (!"APPROVED".equalsIgnoreCase(appStatus)) {
                            continue;
                        }
                %>
                    <tr>
                        <td><%= String.format("PPP%03d", ((Number)app.get("id")).intValue()) %></td>
                        <td><%= certNo %></td>
                        <td><%= app.get("product_name") == null ? "-" : app.get("product_name") %></td>
                        <td><%= app.get("company_name") == null ? "-" : app.get("company_name") %></td>
                        <td><span class="status-badge <%= statusCssClass(appStatus) %>"><%= displayStatusLabel(appStatus) %></span></td>
                        <td>
                            <button
                                type="button"
                                class="cert-action-btn open-certificate-btn"
                                data-certificate-url="${pageContext.request.contextPath}/certificate?id=<%= app.get("id") %>">
                                Lihat
                            </button>
                        </td>
                    </tr>
                <%  } %>
                </tbody>
            </table>
        <% } %>
    </div>
</div>

<div class="app-modal" id="presentationModal" aria-hidden="true">
    <div class="app-panel" role="dialog" aria-modal="true" aria-label="Rekod Pembentangan">
        <div class="app-panel-head">
            <h4>Rekod Jemputan Pembentangan</h4>
            <button class="notif-close" type="button" id="presentationClose" aria-label="Tutup">x</button>
        </div>
        <%
            java.util.List<java.util.Map<String, Object>> presentationInviteHistory =
                (java.util.List<java.util.Map<String, Object>>) request.getAttribute("presentation_invite_history");
            if (presentationInviteHistory == null || presentationInviteHistory.isEmpty()) {
        %>
            <div class="notif-item">Tiada rekod jemputan pembentangan ditemui.</div>
        <% } else { %>
            <table class="app-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Produk</th>
                        <th>Tarikh & Masa</th>
                        <th>Status</th>
                        <th>Maklum Balas</th>
                        <th>Dikemas Kini</th>
                    </tr>
                </thead>
                <tbody>
                <% for (java.util.Map<String, Object> inviteRow : presentationInviteHistory) {
                    String inviteStatus = presentationInviteStatusLabel(inviteRow.get("invite_status"));
                    String applicantResponseLabel = inviteRow.get("applicant_response") == null ? "-" : presentationInviteStatusLabel(inviteRow.get("applicant_response"));
                %>
                    <tr>
                        <td><%= String.format("PPP%03d", ((Number)inviteRow.get("application_id")).intValue()) %></td>
                        <td>
                            <strong><%= inviteRow.get("product_name") == null ? "-" : inviteRow.get("product_name") %></strong>
                            <div style="font-size:12px;color:#5b7485;"><%= inviteRow.get("presentation_venue") == null ? "-" : inviteRow.get("presentation_venue") %></div>
                        </td>
                        <td>
                            <%= inviteRow.get("presentation_date") == null ? "-" : inviteRow.get("presentation_date") %><br>
                            <%= inviteRow.get("presentation_time") == null ? "-" : inviteRow.get("presentation_time") %>
                        </td>
                        <td><span class="status-badge in_progress"><%= inviteStatus %></span></td>
                        <td>
                            <div><strong><%= applicantResponseLabel %></strong></div>
                            <% if (inviteRow.get("applicant_rep_name") != null && !String.valueOf(inviteRow.get("applicant_rep_name")).isBlank()) { %>
                            <div style="font-size:12px;color:#5b7485;">Wakil: <%= inviteRow.get("applicant_rep_name") %></div>
                            <% } %>
                            <% if (inviteRow.get("applicant_attendee_count") != null) { %>
                            <div style="font-size:12px;color:#5b7485;">Peserta: <%= inviteRow.get("applicant_attendee_count") %></div>
                            <% } %>
                            <% if (inviteRow.get("applicant_absence_reason") != null && !String.valueOf(inviteRow.get("applicant_absence_reason")).isBlank()) { %>
                            <div style="font-size:12px;color:#5b7485;">Sebab: <%= inviteRow.get("applicant_absence_reason") %></div>
                            <% } %>
                        </td>
                        <td><%= inviteRow.get("updated_at") == null ? "-" : formatDateTimeValue(inviteRow.get("updated_at")) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        <% } %>
    </div>
</div>

<div class="app-modal" id="certificateViewModal" aria-hidden="true">
    <div class="app-panel certificate-view-panel" role="dialog" aria-modal="true" aria-label="Paparan Sijil">
        <div class="certificate-view-head">
            <h4>Sijil Pendaftaran Produk Air</h4>
            <button class="notif-close" type="button" id="certificateViewClose" aria-label="Tutup">x</button>
        </div>
        <iframe id="certificateFrame" class="certificate-frame" src="about:blank" title="Paparan Sijil"></iframe>
    </div>
</div>

<!-- Modal: Sejarah Permohonan -->
<div class="app-modal" id="historyModal" aria-hidden="true">
    <div class="app-panel" role="dialog" aria-modal="true" aria-label="Sejarah Permohonan">
        <div class="app-panel-head">
            <h4>Sejarah Status Permohonan</h4>
            <button class="notif-close" type="button" id="historyClose" aria-label="Tutup">x</button>
        </div>
        <%
            java.util.Map<Integer, java.util.List<java.util.Map<String, Object>>> statusHistory =
                (java.util.Map<Integer, java.util.List<java.util.Map<String, Object>>>) request.getAttribute("status_history");
            if (statusHistory == null || statusHistory.isEmpty()) {
        %>
            <div class="notif-item">Tiada sejarah perubahan status ditemui.</div>
        <% } else {
            for (java.util.Map.Entry<Integer, java.util.List<java.util.Map<String, Object>>> entry : statusHistory.entrySet()) {
        %>
            <div class="history-group">
                <div class="history-group-head">Permohonan <%= String.format("PPP%03d", entry.getKey()) %></div>
                <% for (java.util.Map<String, Object> h : entry.getValue()) { %>
                <div class="history-row">
                    <div style="flex:1">
                        <span class="status-badge <%= h.get("old_status") == null ? "" : statusCssClass(String.valueOf(h.get("old_status"))) %>"><%= h.get("old_status") == null ? "BARU" : displayStatusLabel(String.valueOf(h.get("old_status"))) %></span>
                        <span class="history-arrow">?</span>
                        <span class="status-badge <%= h.get("new_status") == null ? "" : statusCssClass(String.valueOf(h.get("new_status"))) %>"><%= displayStatusLabel(String.valueOf(h.get("new_status"))) %></span>
                    </div>
                    <div style="flex:1;color:var(--muted);font-size:12px;">
                        <%= h.get("changed_by_name") == null ? "Sistem" : h.get("changed_by_name") %> &bull;
                        <%= h.get("changed_at") == null ? "-" : h.get("changed_at") %>
                    </div>
                    <% if (h.get("admin_notes") != null && !String.valueOf(h.get("admin_notes")).isEmpty()) { %>
                    <div style="flex:2;color:#0d4b71;font-size:12px;"><em><%= h.get("admin_notes") %></em></div>
                    <% } %>
                </div>
                <% } %>
            </div>
        <% } } %>
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

<div class="app-floating-actions" aria-label="Sidebar Cara Guna Sistem">
    <a class="app-floating-link" href="${pageContext.request.contextPath}/user-portal-guide.html" title="Cara Guna Sistem" aria-label="Cara Guna Sistem" target="_blank" rel="noopener">
        <span class="icon-glyph" aria-hidden="true">&#10067;</span>
        <span>Cara Guna Sistem</span>
    </a>
</div>

<% if (showDecisionPopup) { %>
<div class="decision-popup show <%= decisionPopupApproved ? "approved" : "alert" %>" id="decisionStatusPopup" aria-hidden="false">
    <div class="decision-popup-card" role="dialog" aria-modal="true" aria-label="Notifikasi keputusan permohonan">
        <% if (decisionPopupApproved) { %>
        <span class="decision-popup-icon" aria-hidden="true">&#127942;</span>
        <h3 class="decision-popup-title">Tahniah!</h3>
        <p class="decision-popup-message">Permohonan anda <strong>DILULUSKAN</strong>.</p>
        <div class="decision-popup-actions">
            <button type="button" class="decision-popup-btn" id="decisionViewCertificateBtn"><%= escapeHtml(decisionApproveButtonText) %></button>
        </div>
        <% } else { %>
        <button type="button" class="decision-popup-close" id="decisionClosePopupBtn" aria-label="Tutup pemberitahuan">
            <span class="icon-glyph" aria-hidden="true">&#10005;</span>
        </button>
        <h3 class="decision-popup-title" style="color:#991b1b;">Pemberitahuan</h3>
        <p class="decision-popup-message">Permohonan anda <span class="decision-popup-status"><%= escapeHtml(decisionStatusWord) %></span>.</p>
        <% } %>
    </div>
</div>
<% } %>

<% if (presentationPopupMessage != null && !presentationPopupMessage.isBlank()) { %>
<div class="presentation-popup show" id="presentationPopup" aria-hidden="false">
    <div class="presentation-popup-card" role="dialog" aria-modal="true" aria-label="MAKLUMAN: TINDAKAN SUSULAN PERMOHONAN">
        <h3>MAKLUMAN: TINDAKAN SUSULAN PERMOHONAN</h3>
        <div class="presentation-popup-message"><%= presentationMainText == null ? "" : presentationMainText %></div>
        <% if (presentationScheduleLines != null && !presentationScheduleLines.isEmpty()) { %>
        <div class="presentation-popup-schedule">
            <% for (String scheduleLine : presentationScheduleLines) { %>
            <div><%= scheduleLine %></div>
            <% } %>
        </div>
        <% } %>
        <div class="presentation-popup-actions">
            <button type="button" class="success-ok" id="closePresentationPopup">OK</button>
        </div>
    </div>
</div>
<% } %>

<div class="notif-modal" id="notifModal" aria-hidden="true">
    <div class="notif-panel" role="dialog" aria-modal="true" aria-label="Senarai Pemberitahuan">
        <div class="notif-head">
            <h4>Senarai Pemberitahuan</h4>
            <button class="notif-close" type="button" id="notifClose" aria-label="Tutup">x</button>
        </div>
        <%
            java.util.List<java.util.Map<String, Object>> notifications =
                    (java.util.List<java.util.Map<String, Object>>) request.getAttribute("notifications");
            if (notifications == null || notifications.isEmpty()) {
        %>
            <div class="notif-item">Tiada pemberitahuan baharu.</div>
        <% } else {
            for (java.util.Map<String, Object> notif : notifications) {
        %>
            <div class="notif-item">
                <div><strong><%= notif.get("type") == null ? "INFO" : notif.get("type") %></strong> - <%= notif.get("message") == null ? "" : notif.get("message") %></div>
                <div class="notif-time"><%= notif.get("created_at") == null ? "" : formatDateTimeValue(notif.get("created_at")) %></div>
            </div>
        <%  }
            }
        %>
    </div>
</div>

<script>
    (function () {
        var track = document.getElementById('featureTrack');
        var pages = Array.prototype.slice.call(document.querySelectorAll('.feature-page'));
        var dots = Array.prototype.slice.call(document.querySelectorAll('#pageIndicator .dot'));
        var left = document.getElementById('arrowLeft');
        var right = document.getElementById('arrowRight');
        var notifShortcut = document.getElementById('notifShortcut');
        var notifModal = document.getElementById('notifModal');
        var notifClose = document.getElementById('notifClose');
        var openCertificateListBtn = document.getElementById('openCertificateListBtn');
        var certificateListModal = document.getElementById('certificateListModal');
        var certificateListClose = document.getElementById('certificateListClose');
        var certificateViewModal = document.getElementById('certificateViewModal');
        var certificateViewClose = document.getElementById('certificateViewClose');
        var certificateFrame = document.getElementById('certificateFrame');
        var presentationPopup = document.getElementById('presentationPopup');
        var closePresentationPopup = document.getElementById('closePresentationPopup');
        var decisionStatusPopup = document.getElementById('decisionStatusPopup');
        var decisionClosePopupBtn = document.getElementById('decisionClosePopupBtn');
        var decisionViewCertificateBtn = document.getElementById('decisionViewCertificateBtn');
        var total = pages.length;
        var index = 0;

        function render() {
            var sideOffset = window.innerWidth < 640 ? 170 : 240;
            var sideScale = window.innerWidth < 640 ? 0.9 : 0.88;

            pages.forEach(function (page, i) {
                var rel = (i - index + total) % total;
                if (rel > total / 2) {
                    rel -= total;
                }

                var absRel = Math.abs(rel);
                var isActive = rel === 0;
                var isSide = absRel === 1;
                var x = isActive ? 0 : (isSide ? rel * sideOffset : rel * (sideOffset * 1.25));
                var scale = isActive ? 1 : (isSide ? sideScale : 0.82);
                var opacity = isActive ? 1 : (isSide ? 0.72 : 0);
                var zIndex = isActive ? 6 : (isSide ? 4 : 1);

                page.style.opacity = String(opacity);
                page.style.zIndex = String(zIndex);
                page.style.pointerEvents = isActive ? 'auto' : 'none';
                page.style.transform =
                    'translate(-50%, -50%) translateX(' + x + 'px) scale(' + scale + ')';
            });

            dots.forEach(function (dot, i) {
                if (i === index) dot.classList.add('active');
                else dot.classList.remove('active');
            });
        }

        left.addEventListener('click', function () {
            index = (index - 1 + total) % total;
            render();
        });

        right.addEventListener('click', function () {
            index = (index + 1) % total;
            render();
        });

        function openNotifModal(e) {
            e.preventDefault();
            notifModal.classList.add('active');
            notifModal.setAttribute('aria-hidden', 'false');
        }

        notifShortcut.addEventListener('click', openNotifModal);

        var openNotifBtn = document.getElementById('openNotifBtn');
        if (openNotifBtn) { openNotifBtn.addEventListener('click', openNotifModal); }

        function makeModalHandlers(modalId, closeId, extraBtnId) {
            var modal = document.getElementById(modalId);
            var closeBtn = document.getElementById(closeId);
            if (!modal) {
                return function () {};
            }
            function open(e) { e.preventDefault(); modal.classList.add('active'); modal.setAttribute('aria-hidden', 'false'); }
            function close() { modal.classList.remove('active'); modal.setAttribute('aria-hidden', 'true'); }
            if (extraBtnId) { var btn = document.getElementById(extraBtnId); if (btn) btn.addEventListener('click', open); }
            if (closeBtn) closeBtn.addEventListener('click', close);
            modal.addEventListener('click', function(e) { if (e.target === modal) close(); });
            return close;
        }
        var closeAppList = makeModalHandlers('appListModal', 'appListClose', 'openAppListBtn');
        var closeCertificateList = makeModalHandlers('certificateListModal', 'certificateListClose', 'openCertificateListBtn');
        var closeHistory = makeModalHandlers('historyModal', 'historyClose', 'openHistoryBtn');
        var closePresentation = makeModalHandlers('presentationModal', 'presentationClose', 'openPresentationBtn');

        function closeCertificateView() {
            certificateViewModal.classList.remove('active');
            certificateViewModal.setAttribute('aria-hidden', 'true');
            certificateFrame.setAttribute('src', 'about:blank');
        }

        if (certificateViewClose) {
            certificateViewClose.addEventListener('click', closeCertificateView);
        }
        if (certificateViewModal) {
            certificateViewModal.addEventListener('click', function (e) {
                if (e.target === certificateViewModal) {
                    closeCertificateView();
                }
            });
        }

        if (certificateListModal) {
            certificateListModal.addEventListener('click', function (e) {
                var openBtn = e.target.closest('.open-certificate-btn');
                if (!openBtn) {
                    return;
                }
                e.preventDefault();
                var certificateUrl = openBtn.getAttribute('data-certificate-url');
                if (!certificateUrl || !certificateViewModal || !certificateFrame) {
                    return;
                }
                certificateFrame.setAttribute('src', certificateUrl);
                certificateViewModal.classList.add('active');
                certificateViewModal.setAttribute('aria-hidden', 'false');
            });
        }

        notifClose.addEventListener('click', function () {
            notifModal.classList.remove('active');
            notifModal.setAttribute('aria-hidden', 'true');
        });

        notifModal.addEventListener('click', function (e) {
            if (e.target === notifModal) {
                notifModal.classList.remove('active');
                notifModal.setAttribute('aria-hidden', 'true');
            }
        });

        function closePresentationNotice() {
            if (!presentationPopup) return;
            presentationPopup.classList.remove('show');
            presentationPopup.setAttribute('aria-hidden', 'true');
        }

        function closeDecisionPopup() {
            if (!decisionStatusPopup) return;
            decisionStatusPopup.classList.remove('show');
            decisionStatusPopup.setAttribute('aria-hidden', 'true');
        }

        if (decisionClosePopupBtn) {
            decisionClosePopupBtn.addEventListener('click', closeDecisionPopup);
        }

        if (decisionViewCertificateBtn) {
            decisionViewCertificateBtn.addEventListener('click', function () {
                closeDecisionPopup();
                if (!certificateListModal) {
                    return;
                }
                certificateListModal.classList.add('active');
                certificateListModal.setAttribute('aria-hidden', 'false');
            });
        }

        if (decisionStatusPopup) {
            decisionStatusPopup.addEventListener('click', function (e) {
                if (e.target === decisionStatusPopup && decisionClosePopupBtn) {
                    closeDecisionPopup();
                }
            });
        }

        if (closePresentationPopup) {
            closePresentationPopup.addEventListener('click', closePresentationNotice);
        }

        if (presentationPopup) {
            presentationPopup.addEventListener('click', function (e) {
                if (e.target === presentationPopup) {
                    closePresentationNotice();
                }
            });
        }

        document.addEventListener('keydown', function (e) {
            if (e.key === 'ArrowLeft') {
                index = (index - 1 + total) % total;
                render();
            }
            if (e.key === 'ArrowRight') {
                index = (index + 1) % total;
                render();
            }
            if (e.key === 'Escape') {
                notifModal.classList.remove('active');
                notifModal.setAttribute('aria-hidden', 'true');
                closePresentationNotice();
                closeDecisionPopup();
                closeAppList();
                closeCertificateList();
                closeCertificateView();
                closeHistory();
            }
        });

        window.addEventListener('resize', render);

        render();
    })();
</script>
</body>
</html>





