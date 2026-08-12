<%-- NOTA ALIRAN KOD: Fail director-dashboard.jsp. Halaman ini dipaparkan oleh aliran /dashboard untuk pengguna role DIRECTOR. Tujuan nota ni supaya orang seterusnya terus nampak konteks fail ni. --%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.sistemppa.service.StatusConfigService" %>
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

    private String displayStatusLabel(String status) {
        return displayStatusLabel(status, null);
    }

    private String displayStatusLabel(String status, Map<String, String> labelMap) {
        if (status == null) {
            return "-";
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
        if ("UNDER_REVIEW".equals(normalized) || "DALAM_SEMAKAN".equals(normalized) || "DALAM SEMAKAN".equals(normalized)) {
            return "PERMOHONAN DITERIMA";
        }
        if ("DILULUSKAN_PENGARAH".equals(normalized)) {
            return "DILULUSKAN PENGARAH";
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
        if ("ARCHIVED".equals(normalized) || "DIARKIB".equals(normalized)) {
            return "DIARKIB";
        }
        return normalized.replace('_', ' ');
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

    private String formatDateValue(Object value) {
        java.time.LocalDate dateValue = null;
        if (value instanceof java.sql.Date) {
            dateValue = ((java.sql.Date) value).toLocalDate();
        } else if (value instanceof java.sql.Timestamp) {
            dateValue = ((java.sql.Timestamp) value).toLocalDateTime().toLocalDate();
        } else if (value != null) {
            String raw = String.valueOf(value).trim();
            if (!raw.isEmpty() && !"-".equals(raw)) {
                try {
                    dateValue = java.time.LocalDate.parse(raw.substring(0, Math.min(raw.length(), 10)));
                } catch (Exception ignored) {
                    dateValue = null;
                }
            }
        }
        if (dateValue == null) {
            return "-";
        }
        return dateValue.format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
    }

    private String nl2br(String value) {
        if (value == null) {
            return "-";
        }
        String escaped = escapeHtml(value.trim());
        if (escaped.isEmpty()) {
            return "-";
        }
        return escaped.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "<br>");
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Dashboard Pengarah - SPPPBA</title>
    <style>
        body { margin: 0; font-family: inherit; background: #f4f8fb; color: #173040; }
        .navbar { background: #eefbca; color: white; padding: 18px 24px; display: flex; justify-content: space-between; align-items: center; gap: 12px; }
        .navbar h1 { margin: 0; font-size: 20px; }
        .navbar a { color: white; text-decoration: none; font-weight: 600; }
        .navbar-brand { display: inline-flex; align-items: center; gap: 12px; min-width: 0; }
        .navbar-logo {
            width: 64px;
            height: 64px;
            object-fit: contain;
            background: rgba(255, 255, 255, 0.12);
            border-radius: 10px;
            padding: 4px;
            flex-shrink: 0;
        }
        .navbar-title {
            margin: 0;
            font-size: 19px;
            line-height: 1.3;
            color: #0a0228;
            font-weight: 700;
        }
        .navbar-actions { display: inline-flex; align-items: center; gap: 10px; }
        .nav-icon-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 54px;
            height: 54px;
            border-radius: 999px;
            border: 2px solid #0b3f72;
            background: #0f4f8f;
            color: #ffffff;
            text-decoration: none;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.22);
        }
        .nav-icon-link:hover {
            background: #1263b5;
        }
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
        .container { max-width: 1280px; margin: 24px auto; padding: 0 18px 36px; }
        .hero { display: grid; grid-template-columns: 1fr; gap: 18px; margin-bottom: 20px; }
        .panel { background: white; border: 1px solid #dfe8f1; border-radius: 18px; padding: 22px; box-shadow: 0 12px 28px rgba(6, 52, 79, 0.06); }
        .hero h2 { margin: 0 0 10px; font-size: 28px; }
        .hero p { margin: 0; color: #566d82; line-height: 1.6; }
        .stats { display: grid; grid-template-columns: repeat(5, minmax(170px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .stats-section {
            background: #ffffff;
            border: 1px solid #dfe8f1;
            border-radius: 18px;
            padding: 20px 22px;
            margin-bottom: 16px;
            box-shadow: 0 8px 20px rgba(6, 52, 79, 0.05);
        }
        .stats-section-label {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 16px;
        }
        .stage-tag {
            display: inline-flex;
            padding: 5px 14px;
            border-radius: 999px;
            font-size: 13px;
            font-weight: 800;
            letter-spacing: 0.04em;
            text-transform: uppercase;
        }
        .stage-initial { background: #d9ecff; color: #0f4f8f; }
        .stage-final { background: #d9f7df; color: #125c2b; }
        .stage-sub {
            font-size: 13px;
            color: #6b8299;
            font-weight: 600;
        }
        .stats-full-width {
            width: 100%;
            padding: 20px 24px 4px;
            box-sizing: border-box;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(165px, 1fr));
            gap: 16px;
            width: 100%;
            margin-bottom: 24px;
        }
        .stats-row {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 12px;
        }
        @media (max-width: 1100px) {
            .stats-row { grid-template-columns: repeat(4, 1fr); }
        }
        @media (max-width: 700px) {
            .stats-row { grid-template-columns: repeat(2, 1fr); }
        }
        .stat-card {
            background: #ffffff;
            padding: 18px 12px;
            border-radius: 18px;
            border: 1px solid #e3edf5;
            box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 130px;
            width: 100%;
            box-sizing: border-box;
        }
        .stat-card h3 {
            margin: 0 0 8px;
            font-size: 10.5px;
            font-weight: 700;
            color: #5d758c;
            text-transform: uppercase;
            letter-spacing: 0.01em;
            text-align: center;
            line-height: 1.4;
            overflow-wrap: break-word;
            width: 100%;
        }
        .stat-card .number { font-size: 30px; font-weight: 800; color: #0f4f8f; text-align: center; line-height: 1; }
        .stats .stat-card:nth-child(1) { background: #d9ecff; border-color: #afd3f8; }
        .stats .stat-card:nth-child(1) h3, .stats .stat-card:nth-child(1) .number { color: #0f4f8f; }
        .stats .stat-card:nth-child(2) { background: #d9f7df; border-color: #aee5bb; }
        .stats .stat-card:nth-child(2) h3, .stats .stat-card:nth-child(2) .number { color: #125c2b; }
        .stats .stat-card:nth-child(3) { background: #fffef5; border-color: #ece7c9; }
        .stats .stat-card:nth-child(3) h3, .stats .stat-card:nth-child(3) .number { color: #57513a; }
        .stats .stat-card:nth-child(4) { background: #ffd9e8; border-color: #f6b6d1; }
        .stats .stat-card:nth-child(4) h3, .stats .stat-card:nth-child(4) .number { color: #7b1f49; }
        .stats .stat-card:nth-child(5) { background: #fff3a3; border-color: #f7df6b; }
        .stats .stat-card:nth-child(5) h3, .stats .stat-card:nth-child(5) .number { color: #6a5700; }
        .stat-card.small { display: flex; justify-content: space-between; align-items: center; }
        .summary-row {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
            padding: 12px 14px;
            border: 1px solid #dce8f2;
            border-radius: 14px;
            background: #f7fbff;
        }
        .summary-row.pastel-yellow {
            background: #fff9d9;
            border-color: #f0e0a4;
        }
        .summary-metric { display: inline-flex; align-items: baseline; gap: 8px; color: #365063; }
        .summary-metric span {
            font-weight: 800;
            
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .summary-metric strong { color: #0f4f8f; font-size: 16px; }
        .toolbar { display: grid; grid-template-columns: minmax(220px, 1.6fr) repeat(2, minmax(160px, 1fr)) auto; gap: 12px; align-items: end; margin-bottom: 16px; }
        .field { min-width: 0; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: #5d758c; }
        .field input { width: 100%; padding: 11px 12px; border: 1px solid #cbd6e0; border-radius: 12px; font-size: 14px; box-sizing: border-box; }
        .toolbar .btn-primary { min-height: 44px; }
        .table-wrapper { max-width: 100%; border: 1px solid #dce8f2; border-radius: 14px; overflow: visible; }
        .table-scroll { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; min-width: 700px; background: white; }
        th, td { padding: 12px 10px; text-align: left; border-bottom: 1px solid #ebf1f6; }
        th { font-size: 12px; text-transform: uppercase; color: #4f6776; letter-spacing: 0.03em; background: #f6fbff; }
        .empty { text-align: center; color: #6e8492; padding: 18px; }
        tr:hover { background: #f6fbff; }
        .status-pill { display: inline-flex; padding: 6px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; color: white; }
        .status-approved { background: #1f7d35; }
        .status-rejected { background: #a11d2e; }
        .status-pending { background: #d97706; }
        .status-review { background: #0f63b5; }
        .status-suspended { background: #6b21a8; }
        .btn-primary { display: inline-flex; justify-content: center; align-items: center; padding: 10px 16px; border-radius: 12px; background: #0f6bae; color: white; text-decoration: none; font-weight: 700; }
        .btn-primary { border: none; cursor: pointer; }
        .action-cell {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
        }
        .btn-view,
        .btn-action {
            border: none;
            border-radius: 10px;
            padding: 8px 12px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .btn-view {
            background: #e8f2ff;
            color: #0f4f8f;
        }
        .btn-action {
            background: #0f6bae;
            color: #ffffff;
            min-width: 118px;
            justify-content: space-between;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .action-dropdown {
            position: relative;
            display: inline-block;
        }
        .action-menu {
            position: fixed;
            min-width: 164px;
            max-height: calc(100vh - 24px);
            overflow-y: auto;
            background: #ffffff;
            border: 1px solid #d6e3ef;
            border-radius: 12px;
            box-shadow: 0 14px 34px rgba(11, 55, 82, 0.16);
            padding: 6px;
            display: none;
            z-index: 20;
        }
        .action-menu.open {
            display: block;
        }
        .action-item {
            width: 100%;
            border: none;
            background: transparent;
            text-align: left;
            padding: 8px 10px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 700;
            color: #274256;
            cursor: pointer;
        }
        .action-item:hover {
            background: #f3f8fd;
                .action-item-terima  { color: #155724; }
                .action-item-terima:hover  { background: #d4edda; }
                .action-item-tolak   { color: #721c24; }
                .action-item-tolak:hover   { background: #f8d7da; }
                .action-item-gantung { color: #6b21a8; }
                .action-item-gantung:hover { background: #ede9fe; }
                .action-item-batal   { color: #5f6e7a; }
                .action-item-batal:hover   { background: #f0f4f8; }
                .action-item-kuiri   { color: #0f4f8f; }
                .action-item-kuiri:hover   { background: #dbeafe; }
            .action-item-terima  { color: #155724; }
            .action-item-terima:hover  { background: #d4edda; }
            .action-item-tolak   { color: #721c24; }
            .action-item-tolak:hover   { background: #f8d7da; }
            .action-item-gantung { color: #6b21a8; }
            .action-item-gantung:hover { background: #ede9fe; }
            .action-item-batal   { color: #5f6e7a; }
            .action-item-batal:hover   { background: #f0f4f8; }
            .action-item-kuiri   { color: #0f4f8f; }
            .action-item-kuiri:hover   { background: #dbeafe; }
        }
        .modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(9, 31, 47, 0.55);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2000;
            padding: 20px;
        }
        .modal-overlay.open {
            display: flex;
        }
        .modal-card {
            width: min(980px, 96vw);
            max-height: 88vh;
            overflow: auto;
            border-radius: 16px;
            background: #ffffff;
            border: 1px solid #d9e6f2;
            box-shadow: 0 18px 40px rgba(8, 40, 62, 0.28);
            padding: 18px;
        }
        .modal-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            margin-bottom: 14px;
            padding-bottom: 10px;
            border-bottom: 1px solid #dce8f2;
        }
        .modal-title {
            margin: 0;
            color: #1a3447;
            font-size: 20px;
        }
        .modal-close {
            border: none;
            background: #eaf2fb;
            color: #0f4f8f;
            border-radius: 10px;
            padding: 8px 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .modal-subtitle {
            margin: 0 0 12px;
            color: #4f6776;
            font-size: 13px;
        }
        .form-section {
            border: 1px solid #dce8f2;
            border-radius: 12px;
            margin-bottom: 12px;
            overflow: hidden;
            background: #fbfdff;
        }
        .form-section h4 {
            margin: 0;
            padding: 10px 12px;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
            color: #123a5a;
            background: #eaf3fb;
            border-bottom: 1px solid #d5e4f1;
        }
        .section-body {
            padding: 12px;
        }
        .detail-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 10px 16px;
        }
        .detail-item small {
            display: block;
            color: #5d758c;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
            margin-bottom: 2px;
        }
        .detail-item div {
            color: #1a3447;
            font-size: 13px;
            line-height: 1.5;
            word-break: break-word;
        }
        .modal-actions {
            margin-top: 14px;
            padding-top: 12px;
            border-top: 1px solid #dce8f2;
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }
        .modal-action-btn {
            border: none;
            border-radius: 10px;
            padding: 9px 12px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .action-accept { background: #0f6bae; color: #fff; }
        .action-reject { background: #a11d2e; color: #fff; }
        .action-suspend { background: #6b21a8; color: #fff; }
        .action-cancel { background: #5f6e7a; color: #fff; }
        .decision-overlay {
            position: fixed;
            inset: 0;
            background: rgba(6, 24, 38, 0.48);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2200;
            padding: 16px;
        }
        .decision-overlay.open {
            display: flex;
        }
        .decision-card {
            width: min(420px, 92vw);
            background: #ffffff;
            border: 1px solid #d7e4ef;
            border-radius: 16px;
            box-shadow: 0 20px 42px rgba(7, 36, 57, 0.26);
            padding: 20px;
            text-align: center;
        }
        .decision-icon {
            width: 78px;
            height: 78px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 64px;
            line-height: 1;
            color: #0f6bae;
            margin: 0 auto 10px;
        }
        .decision-title {
            margin: 0;
            font-size: 18px;
            color: #113650;
            font-weight: 800;
        }
        .decision-message {
            margin: 10px 0 0;
            color: #425b6e;
            font-size: 14px;
            line-height: 1.6;
        }
        .decision-actions {
            margin-top: 16px;
            display: flex;
            justify-content: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .decision-btn {
            border: none;
            border-radius: 10px;
            padding: 9px 14px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
        }
        .decision-btn-cancel {
            background: #e7eef5;
            color: #355167;
        }
        .decision-btn-confirm {
            background: #0f6bae;
            color: #ffffff;
        }
        .notice-success {
            margin-bottom: 12px;
            border: 1px solid #b8e7c6;
            background: #e7f9ec;
            color: #166534;
            border-radius: 12px;
            padding: 10px 12px;
            font-size: 13px;
            font-weight: 700;
        }
        .notice-error {
            margin-bottom: 12px;
            border: 1px solid #f5b5b5;
            background: #fff1f1;
            color: #9b1c1c;
            border-radius: 12px;
            padding: 10px 12px;
            font-size: 13px;
            font-weight: 700;
        }
        .summary-title { font-size: 14px; color: #546c86; }
        .processed-archive {
            margin-top: 18px;
            border: 1px solid #dce8f2;
            border-radius: 16px;
            background: #f9fcff;
            overflow: hidden;
        }
        .archive-headerbar {
            padding: 16px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            background: linear-gradient(180deg, #eaf4ff 0%, #d7ebff 100%);
            color: #123a5a;
            font-weight: 800;
        }
        .archive-headerbar > span:first-child {
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .archive-headerbar.green {
            background: linear-gradient(180deg, #eaf9ee 0%, #d8f2df 100%);
            color: #154d2b;
        }
        .processed-archive .archive-body {
            padding: 16px 18px 18px;
            background: #ffffff;
            border-top: 1px solid #dce8f2;
        }
        .archive-header {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }
        .archive-header p {
            margin: 0;
            color: #577084;
            font-size: 13px;
            line-height: 1.5;
        }
        .archive-count {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px;
            border-radius: 999px;
            background: #eaf3fb;
            color: #05294d;
            font-size: 12px;
            font-weight: 800;
        }
        @media (max-width: 1200px) {
            .stats { grid-template-columns: repeat(3, minmax(0, 1fr)); }
        }
        @media (max-width: 960px) {
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .toolbar { grid-template-columns: 1fr; }
            .detail-grid { grid-template-columns: 1fr; }
            .navbar-title { font-size: 16px; }
        }
        @media (max-width: 600px) {
            .stats { grid-template-columns: 1fr; }
            .navbar { padding: 14px 16px; }
            .navbar-logo { width: 38px; height: 38px; }
            .nav-icon-link {
                width: 42px;
                height: 42px;
            }
        }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="navbar-brand">
            <img class="navbar-logo" src="${pageContext.request.contextPath}/icon/logo-jans-2025-main.png" alt="Logo JANS">
            <div style="display:flex; flex-direction:column; gap:2px;">
                <h3 class="navbar-title">Sistem Pendaftaran Pembekal dan Bekalan Produk Air</h3>
                <h4 style="color: #000000; margin:0;">Jabatan Air Sabah</h4>
            </div>
        </div>
        <div class="navbar-actions">
            <a class="nav-icon-link" href="${pageContext.request.contextPath}/logout" aria-label="Log Keluar" title="Log Keluar">
                <svg class="nav-icon-svg" viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M10 5H5v14h5"></path>
                    <path d="M13 12h8"></path>
                    <path d="M18 8l4 4-4 4"></path>
                </svg>
            </a>
        </div>
    </div>
    <div class="stats-full-width">
            <div class="stats-row">
                <div class="stat-card" style="background:#d9ecff;border-color:#afd3f8;">
                    <h3 style="color:#0f4f8f;">Jumlah Permohonan</h4>
                    <div class="number" style="color:#0f4f8f;"><%= request.getAttribute("director_initial_total_count") != null ? request.getAttribute("director_initial_total_count") : "0" %></div>
                </div>
                <div class="stat-card" style="background:#d9f7df;border-color:#aee5bb;">
                    <h3 style="color:#125c2b;">Status Terima</h4>
                    <div class="number" style="color:#125c2b;"><%= request.getAttribute("director_initial_terima_count") != null ? request.getAttribute("director_initial_terima_count") : "0" %></div>
                </div>
                <div class="stat-card" style="background:#ffd9e8;border-color:#f6b6d1;">
                    <h3 style="color:#7b1f49;">Status Tolak</h4>
                    <div class="number" style="color:#7b1f49;"><%= request.getAttribute("director_initial_tolak_count") != null ? request.getAttribute("director_initial_tolak_count") : "0" %></div>
                </div>
                <div class="stat-card" style="background:#fff3a3;border-color:#f7df6b;">
                    <h3 style="color:#6a5700;">Status Tangguh</h4>
                    <div class="number" style="color:#6a5700;"><%= request.getAttribute("director_initial_gantung_count") != null ? request.getAttribute("director_initial_gantung_count") : "0" %></div>
                </div>
                <div class="stat-card" style="background:#fffef5;border-color:#ece7c9;">
                    <h3 style="color:#57513a;">Status Menunggu</h4>
                    <div class="number" style="color:#57513a;"><%= request.getAttribute("director_initial_pending_count") != null ? request.getAttribute("director_initial_pending_count") : "0" %></div>
                </div>
                <div class="stat-card" style="background:#d9f7df;border-color:#aee5bb;">
                    <h3 style="color:#125c2b;">Status Lulus</h4>
                    <div class="number" style="color:#125c2b;"><%= request.getAttribute("director_final_lulus_count") != null ? request.getAttribute("director_final_lulus_count") : "0" %></div>
                </div>
                <div class="stat-card" style="background:#ffd9e8;border-color:#f6b6d1;">
                    <h3 style="color:#7b1f49;">Status Tidak Lulus</h4>
                    <div class="number" style="color:#7b1f49;"><%= request.getAttribute("director_final_tidak_lulus_count") != null ? request.getAttribute("director_final_tidak_lulus_count") : "0" %></div>
                </div>
            </div>
    </div>

    <div class="container">
            <% if (request.getAttribute("director_success") != null) { %>
                <div class="notice-success"><%= request.getAttribute("director_success") %></div>
            <% } %>
            <% if (request.getAttribute("director_error") != null) { %>
                <div class="notice-error"><%= request.getAttribute("director_error") %></div>
            <% } %>

                        <%-- ===== PANEL 1: PERMOHONAN UNTUK DIAMBIL TINDAKAN (INITIAL) ===== --%>
                        <section class="processed-archive" style="margin-bottom: 18px;">
                            <div class="archive-headerbar" style="background: linear-gradient(180deg,#eaf9ee 0%,#d8f2df 100%); color:#154d2b;">
                                <span>PERMOHONAN UNTUK DIAMBIL TINDAKAN</span>
                                <span class="archive-count"><%= request.getAttribute("director_initial_action_count") != null ? request.getAttribute("director_initial_action_count") : 0 %> Rekod</span>
                            </div>
                            <div class="archive-body">
                                <div class="table-wrapper">
                                    <div class="table-scroll">
                                        <table>
                                            <thead>
                                                <tr>
                                                    <th>No. Permohonan</th>
                                                    <th>Pemohon</th>
                                                    <th>Syarikat</th>
                                                    <th>Produk</th>
                                                    <th>Tarikh Hantar</th>
                                                    <th>Tindakan</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <%
                                                    @SuppressWarnings("unchecked")
                                                    List<Map<String, Object>> initialApps = (List<Map<String, Object>>) request.getAttribute("director_initial_action_applications");
                                                    if (initialApps == null || initialApps.isEmpty()) {
                                                %>
                                                <tr><td colspan="6" class="empty">Tiada permohonan baharu menunggu tindakan.</td></tr>
                                                <% } else { for (Map<String, Object> appRow : initialApps) { %>
                                                <tr>
                                                    <td><strong><%= escapeHtml(appRow.get("display_id") != null ? String.valueOf(appRow.get("display_id")) : "-") %></strong></td>
                                                    <td><%= escapeHtml(String.valueOf(appRow.get("full_name"))) %></td>
                                                    <td><%= escapeHtml(String.valueOf(appRow.get("company_name"))) %></td>
                                                    <td><%= escapeHtml(String.valueOf(appRow.get("product_name"))) %></td>
                                                    <td><%= escapeHtml(formatDateTimeValue(appRow.get("submitted_at"))) %></td>
                                                    <td>
                                                        <div class="action-cell">
                                                            <button type="button" class="btn-view"
                                                                data-panel="initial"
                                                                data-app_id="<%= appRow.get("id") %>"
                                                                data-full_name="<%= escapeHtml(String.valueOf(appRow.get("full_name"))) %>"
                                                                data-user_email="<%= escapeHtml(String.valueOf(appRow.get("user_email"))) %>"
                                                                data-application_type="<%= escapeHtml(String.valueOf(appRow.get("application_type"))) %>"
                                                                data-company_name="<%= escapeHtml(String.valueOf(appRow.get("company_name"))) %>"
                                                                data-company_address="<%= escapeHtml(String.valueOf(appRow.get("company_address"))) %>"
                                                                data-contact_number="<%= escapeHtml(String.valueOf(appRow.get("contact_number"))) %>"
                                                                data-supplier_email="<%= escapeHtml(String.valueOf(appRow.get("supplier_email"))) %>"
                                                                data-supplier_name="<%= escapeHtml(String.valueOf(appRow.get("supplier_name"))) %>"
                                                                data-supplier_address="<%= escapeHtml(String.valueOf(appRow.get("supplier_address"))) %>"
                                                                data-supplier_phone="<%= escapeHtml(String.valueOf(appRow.get("supplier_phone"))) %>"
                                                                data-manufacturer_name="<%= escapeHtml(String.valueOf(appRow.get("manufacturer_name"))) %>"
                                                                data-manufacturer_address="<%= escapeHtml(String.valueOf(appRow.get("manufacturer_address"))) %>"
                                                                data-manufacturer_phone="<%= escapeHtml(String.valueOf(appRow.get("manufacturer_phone"))) %>"
                                                                data-principal_name="<%= escapeHtml(String.valueOf(appRow.get("principal_name"))) %>"
                                                                data-principal_address="<%= escapeHtml(String.valueOf(appRow.get("principal_address"))) %>"
                                                                data-principal_phone="<%= escapeHtml(String.valueOf(appRow.get("principal_phone"))) %>"
                                                                data-product_category="<%= escapeHtml(String.valueOf(appRow.get("product_category"))) %>"
                                                                data-product_name="<%= escapeHtml(String.valueOf(appRow.get("product_name"))) %>"
                                                                data-product_description="<%= escapeHtml(String.valueOf(appRow.get("product_description"))) %>"
                                                                data-standard_name="<%= escapeHtml(String.valueOf(appRow.get("standard_name"))) %>"
                                                                data-certification_license="<%= escapeHtml(String.valueOf(appRow.get("certification_license"))) %>"
                                                                data-certification_valid_until="<%= escapeHtml(formatDateValue(appRow.get("certification_valid_until"))) %>"
                                                                data-test_report_reference="<%= escapeHtml(String.valueOf(appRow.get("test_report_reference"))) %>"
                                                                data-test_report_date="<%= escapeHtml(formatDateValue(appRow.get("test_report_date"))) %>"
                                                                data-warranty_years="<%= escapeHtml(String.valueOf(appRow.get("warranty_years"))) %>"
                                                                data-sabah_rep_name="<%= escapeHtml(String.valueOf(appRow.get("sabah_rep_name"))) %>"
                                                                data-sabah_rep_address="<%= escapeHtml(String.valueOf(appRow.get("sabah_rep_address"))) %>"
                                                                data-sabah_rep_phone="<%= escapeHtml(String.valueOf(appRow.get("sabah_rep_phone"))) %>"
                                                                data-declaration_name="<%= escapeHtml(String.valueOf(appRow.get("declaration_name"))) %>"
                                                                data-declaration_position="<%= escapeHtml(String.valueOf(appRow.get("declaration_position"))) %>"
                                                                data-current_status="<%= escapeHtml(String.valueOf(appRow.get("status"))) %>"
                                                                data-submitted_at="<%= escapeHtml(formatDateTimeValue(appRow.get("submitted_at"))) %>">
                                                                Lihat Butiran
                                                            </button>
                                                            <div class="action-dropdown">
                                                                <button type="button" class="btn-action" data-dropdown-toggle="init-menu-<%= appRow.get("id") %>">Tindakan</button>
                                                                <div class="action-menu" id="init-menu-<%= appRow.get("id") %>">
                                                                    <button type="button" class="action-item action-item-terima" data-action="accept_application" data-appid="<%= appRow.get("id") %>">Terima</button>
                                                                    <button type="button" class="action-item action-item-tolak"  data-action="reject_application"  data-appid="<%= appRow.get("id") %>">Tolak</button>
                                                                    <button type="button" class="action-item action-item-gantung" data-action="suspend_application" data-appid="<%= appRow.get("id") %>"> Gantung</button>
                                                                    <button type="button" class="action-item action-item-batal"  data-action="cancel_application"  data-appid="<%= appRow.get("id") %>"> Batal</button>
                                                                </div>
                                                            </div>
                                                            <form class="director-action-form" method="post" action="${pageContext.request.contextPath}/dashboard">
                                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                                <input type="hidden" name="director_action" value="">
                                                                <input type="hidden" name="application_id" value="<%= appRow.get("id") %>">
                                                                <input type="hidden" name="director_notes" value="">
                                                            </form>
                                                        </div>
                                                    </td>
                                                </tr>
                                                <% } } %>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </section>

                        <%-- ===== PANEL 2: PERMOHONAN UNTUK DILULUSKAN (FINAL) ===== --%>
                        <section class="processed-archive">
                            <div class="archive-headerbar" style="background: linear-gradient(180deg,#eaf4ff 0%,#d7ebff 100%); color:#123a5a;">
                                <span>PERMOHONAN UNTUK DILULUSKAN</span>
                                <span class="archive-count"><%= request.getAttribute("director_final_action_count") != null ? request.getAttribute("director_final_action_count") : 0 %> Rekod</span>
                            </div>
                            <div class="archive-body">
                                <div class="table-wrapper">
                                    <div class="table-scroll">
                                        <table>
                                            <thead>
                                                <tr>
                                                    <th>No. Permohonan</th>
                                                    <th>Pemohon</th>
                                                    <th>Syarikat</th>
                                                    <th>Produk</th>
                                                    <th>Dihantar oleh Admin</th>
                                                    <th>Tindakan</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <%
                                                    @SuppressWarnings("unchecked")
                                                    List<Map<String, Object>> finalApps = (List<Map<String, Object>>) request.getAttribute("director_final_action_applications");
                                                    if (finalApps == null || finalApps.isEmpty()) {
                                                %>
                                                <tr><td colspan="6" class="empty">Tiada permohonan menunggu keputusan akhir.</td></tr>
                                                <% } else { for (Map<String, Object> appRow : finalApps) { %>
                                                <tr>
                                                    <td><strong><%= escapeHtml(appRow.get("display_id") != null ? String.valueOf(appRow.get("display_id")) : "-") %></strong></td>
                                                    <td><%= escapeHtml(String.valueOf(appRow.get("full_name"))) %></td>
                                                    <td><%= escapeHtml(String.valueOf(appRow.get("company_name"))) %></td>
                                                    <td><%= escapeHtml(String.valueOf(appRow.get("product_name"))) %></td>
                                                    <td><%= escapeHtml(formatDateTimeValue(appRow.get("reviewed_at") != null ? appRow.get("reviewed_at") : appRow.get("admin_sent_at"))) %></td>
                                                    <td>
                                                        <div class="action-cell">
                                                            <button type="button" class="btn-view"
                                                                data-panel="final"
                                                                data-app_id="<%= appRow.get("id") %>"
                                                                data-full_name="<%= escapeHtml(String.valueOf(appRow.get("full_name"))) %>"
                                                                data-user_email="<%= escapeHtml(String.valueOf(appRow.get("user_email"))) %>"
                                                                data-application_type="<%= escapeHtml(String.valueOf(appRow.get("application_type"))) %>"
                                                                data-company_name="<%= escapeHtml(String.valueOf(appRow.get("company_name"))) %>"
                                                                data-company_address="<%= escapeHtml(String.valueOf(appRow.get("company_address"))) %>"
                                                                data-contact_number="<%= escapeHtml(String.valueOf(appRow.get("contact_number"))) %>"
                                                                data-supplier_email="<%= escapeHtml(String.valueOf(appRow.get("supplier_email"))) %>"
                                                                data-supplier_name="<%= escapeHtml(String.valueOf(appRow.get("supplier_name"))) %>"
                                                                data-supplier_address="<%= escapeHtml(String.valueOf(appRow.get("supplier_address"))) %>"
                                                                data-supplier_phone="<%= escapeHtml(String.valueOf(appRow.get("supplier_phone"))) %>"
                                                                data-manufacturer_name="<%= escapeHtml(String.valueOf(appRow.get("manufacturer_name"))) %>"
                                                                data-manufacturer_address="<%= escapeHtml(String.valueOf(appRow.get("manufacturer_address"))) %>"
                                                                data-manufacturer_phone="<%= escapeHtml(String.valueOf(appRow.get("manufacturer_phone"))) %>"
                                                                data-principal_name="<%= escapeHtml(String.valueOf(appRow.get("principal_name"))) %>"
                                                                data-principal_address="<%= escapeHtml(String.valueOf(appRow.get("principal_address"))) %>"
                                                                data-principal_phone="<%= escapeHtml(String.valueOf(appRow.get("principal_phone"))) %>"
                                                                data-product_category="<%= escapeHtml(String.valueOf(appRow.get("product_category"))) %>"
                                                                data-product_name="<%= escapeHtml(String.valueOf(appRow.get("product_name"))) %>"
                                                                data-product_description="<%= escapeHtml(String.valueOf(appRow.get("product_description"))) %>"
                                                                data-standard_name="<%= escapeHtml(String.valueOf(appRow.get("standard_name"))) %>"
                                                                data-certification_license="<%= escapeHtml(String.valueOf(appRow.get("certification_license"))) %>"
                                                                data-certification_valid_until="<%= escapeHtml(formatDateValue(appRow.get("certification_valid_until"))) %>"
                                                                data-test_report_reference="<%= escapeHtml(String.valueOf(appRow.get("test_report_reference"))) %>"
                                                                data-test_report_date="<%= escapeHtml(formatDateValue(appRow.get("test_report_date"))) %>"
                                                                data-warranty_years="<%= escapeHtml(String.valueOf(appRow.get("warranty_years"))) %>"
                                                                data-sabah_rep_name="<%= escapeHtml(String.valueOf(appRow.get("sabah_rep_name"))) %>"
                                                                data-sabah_rep_address="<%= escapeHtml(String.valueOf(appRow.get("sabah_rep_address"))) %>"
                                                                data-sabah_rep_phone="<%= escapeHtml(String.valueOf(appRow.get("sabah_rep_phone"))) %>"
                                                                data-declaration_name="<%= escapeHtml(String.valueOf(appRow.get("declaration_name"))) %>"
                                                                data-declaration_position="<%= escapeHtml(String.valueOf(appRow.get("declaration_position"))) %>"
                                                                data-current_status="<%= escapeHtml(String.valueOf(appRow.get("status"))) %>"
                                                                data-submitted_at="<%= escapeHtml(formatDateTimeValue(appRow.get("submitted_at"))) %>">
                                                                Lihat Butiran
                                                            </button>
                                                            <div class="action-dropdown">
                                                                <button type="button" class="btn-action" data-dropdown-toggle="final-menu-<%= appRow.get("id") %>">Keputusan â–¼</button>
                                                                <div class="action-menu" id="final-menu-<%= appRow.get("id") %>">
                                                                    <button type="button" class="action-item action-item-terima" data-action="accept_application" data-appid="<%= appRow.get("id") %>">Lulus</button>
                                                                    <button type="button" class="action-item action-item-tolak"  data-action="reject_application"  data-appid="<%= appRow.get("id") %>">Gagal</button>
                                                                    <button type="button" class="action-item action-item-gantung" data-action="suspend_application" data-appid="<%= appRow.get("id") %>">Gantung</button>
                                                                    <button type="button" class="action-item action-item-batal"  data-action="cancel_application"  data-appid="<%= appRow.get("id") %>">Batal</button>
                                                                    <button type="button" class="action-item action-item-kuiri"  data-action="query_application"  data-appid="<%= appRow.get("id") %>">Kuiri</button>
                                                                </div>
                                                            </div>
                                                            <form class="director-action-form" method="post" action="${pageContext.request.contextPath}/dashboard">
                                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                                <input type="hidden" name="director_action" value="">
                                                                <input type="hidden" name="application_id" value="<%= appRow.get("id") %>">
                                                                <input type="hidden" name="director_notes" value="">
                                                            </form>
                                                        </div>
                                                    </td>
                                                </tr>
                                                <% } } %>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </section>

                <%-- ===== SHARED ACTION FORM (hidden, reused by all dropdown items) ===== --%>
                <form id="directorInlineActionForm" method="post" action="${pageContext.request.contextPath}/dashboard" style="display:none;">
                    <input type="hidden" name="_csrf" value="${csrf_token}">
                    <input type="hidden" id="inlineActionType" name="director_action" value="">
                    <input type="hidden" id="inlineApplicationId" name="application_id" value="">
                    <input type="hidden" id="inlineDirectorNotes" name="director_notes" value="">
                </form>

                <%-- ===== DETAILS MODAL (shared, read-only view) ===== --%>
                <div id="director-details-modal" class="modal-overlay" aria-hidden="true">
                    <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="directorModalTitle">
                        <div class="modal-head">
                            <h3 id="directorModalTitle" class="modal-title">Butiran Penuh Permohonan</h3>
                            <button type="button" id="directorModalClose" class="modal-close">Tutup</button>
                        </div>
                        <div class="form-section">
                            <h4>Maklumat Pemohon</h4>
                            <div class="section-body detail-grid">
                                <div class="detail-item"><small>Pemohon</small><div id="m_full_name">-</div></div>
                                <div class="detail-item"><small>Email Pemohon</small><div id="m_user_email">-</div></div>
                                <div class="detail-item"><small>Jenis Permohonan</small><div id="m_application_type">-</div></div>
                                <div class="detail-item"><small>Tarikh Hantar</small><div id="m_submitted_at">-</div></div>
                            </div>
                        </div>
                        <div class="form-section">
                            <h4>Maklumat Syarikat Dan Pembekal</h4>
                            <div class="section-body detail-grid">
                                <div class="detail-item"><small>Nama Syarikat</small><div id="m_company_name">-</div></div>
                                <div class="detail-item"><small>Telefon Syarikat</small><div id="m_contact_number">-</div></div>
                                <div class="detail-item" style="grid-column:1/-1;"><small>Alamat Syarikat</small><div id="m_company_address">-</div></div>
                                <div class="detail-item"><small>Nama Pembekal</small><div id="m_supplier_name">-</div></div>
                                <div class="detail-item"><small>Telefon Pembekal</small><div id="m_supplier_phone">-</div></div>
                                <div class="detail-item" style="grid-column:1/-1;"><small>Alamat Pembekal</small><div id="m_supplier_address">-</div></div>
                            </div>
                        </div>
                        <div class="form-section">
                            <h4>Maklumat Produk</h4>
                            <div class="section-body detail-grid">
                                <div class="detail-item"><small>Kategori Produk</small><div id="m_product_category">-</div></div>
                                <div class="detail-item"><small>Nama Produk</small><div id="m_product_name">-</div></div>
                                <div class="detail-item" style="grid-column:1/-1;"><small>Butiran Produk</small><div id="m_product_description">-</div></div>
                                <div class="detail-item"><small>Standard</small><div id="m_standard_name">-</div></div>
                                <div class="detail-item"><small>No. Sijil</small><div id="m_certification_license">-</div></div>
                            </div>
                        </div>
                        <div class="modal-actions" style="justify-content:flex-end;">
                            <button type="button" id="directorModalClose2" class="modal-close">Tutup</button>
                        </div>
                    </div>
                </div>

                <%-- ===== NOTES MODAL (prompt for reason before Tolak/Gantung/Batal) ===== --%>
                <div id="director-notes-modal" class="modal-overlay" aria-hidden="true">
                    <div class="decision-card" style="width:min(480px,94vw); text-align:left;" role="dialog" aria-modal="true">
                        <p id="notesModalTitle" style="font-size:16px; font-weight:800; color:#113650; margin:0 0 12px;"></p>
                        <label style="font-size:13px; font-weight:700; color:#4f6776; display:block; margin-bottom:6px;">Ulasan / Sebab Keputusan <span style="color:#dc2626;">*</span></label>
                        <textarea id="notesModalTextarea" style="width:100%; min-height:80px; border:1px solid #cbd6e0; border-radius:10px; padding:10px; font:inherit; font-size:13px; box-sizing:border-box; resize:vertical;" placeholder="Wajib diisi untuk Tolak, Gantung atau Batal"></textarea>
                        <p id="notesModalError" style="color:#dc2626; font-size:12px; margin:4px 0 0; display:none;">Sila isi sebab keputusan.</p>
                        <div class="decision-actions" style="margin-top:14px;">
                            <button type="button" id="notesModalCancel" class="decision-btn decision-btn-cancel">Batal</button>
                            <button type="button" id="notesModalConfirm" class="decision-btn decision-btn-confirm">Sahkan</button>
                        </div>
                    </div>
                </div>

                <%-- ===== CONFIRM MODAL (for accept/lulus, no notes needed) ===== --%>
                <div id="director-decision-modal" class="decision-overlay" aria-hidden="true">
                    <div class="decision-card" role="dialog" aria-modal="true" aria-labelledby="decisionModalTitle">
                        <span class="decision-icon" aria-hidden="true">&#128196;</span>
                        <p id="decisionModalMessage" class="decision-message">Adakah anda ingin meneruskan tindakan ini?</p>
                        <div class="decision-actions">
                            <button type="button" id="decisionCancelBtn" class="decision-btn decision-btn-cancel">Tidak, Kembali</button>
                            <button type="button" id="decisionConfirmBtn" class="decision-btn decision-btn-confirm">Ya</button>
            </div>
        </div>
    </div>
    <script>
        (function () {
            function closeAllMenus() {
                document.querySelectorAll('.action-menu.open').forEach(function (menu) {
                    menu.classList.remove('open');
                });
            }

            document.querySelectorAll('[data-dropdown-toggle]').forEach(function (btn) {
                btn.addEventListener('click', function (event) {
                    event.stopPropagation();
                    var menuId = btn.getAttribute('data-dropdown-toggle');
                    var menu = document.getElementById(menuId);
                    var willOpen = menu && !menu.classList.contains('open');
                    closeAllMenus();
                    if (menu && willOpen) {
                        var rect = btn.getBoundingClientRect();
                        menu.style.visibility = 'hidden';
                        menu.style.display = 'block';
                        var menuHeight = menu.offsetHeight || 220;
                        var menuWidth = menu.offsetWidth || 164;
                        menu.style.display = '';
                        menu.style.visibility = '';

                        var viewportH = window.innerHeight || document.documentElement.clientHeight || 800;
                        var viewportW = window.innerWidth || document.documentElement.clientWidth || 1200;

                        var top = rect.bottom + 6;
                        if (top + menuHeight > viewportH - 8) {
                            top = Math.max(8, rect.top - menuHeight - 6);
                        }

                        var left = rect.right - menuWidth;
                        if (left < 8) {
                            left = 8;
                        } else if (left + menuWidth > viewportW - 8) {
                            left = Math.max(8, viewportW - menuWidth - 8);
                        }

                        menu.style.top = top + 'px';
                        menu.style.left = left + 'px';
                        menu.classList.add('open');
                    }
                });
            });

            function toMultiline(value) {
                if (!value || value === '-') {
                    return '-';
                }
                return value.replace(/\n/g, '<br>');
            }

            function setModalValue(id, value, multiline) {
                var target = document.getElementById(id);
                if (!target) {
                    return;
                }
                var normalized = (!value || value === 'null' || value === 'undefined') ? '-' : value;
                if (multiline) {
                    target.innerHTML = toMultiline(normalized);
                } else {
                    target.textContent = normalized;
                }
            }

            var detailModal = document.getElementById('director-details-modal');
            var detailModalClose = document.getElementById('directorModalClose');
            var detailModalClose2 = document.getElementById('directorModalClose2');
            var modalActionForm = document.getElementById('directorModalActionForm');
            var modalActionInput = document.getElementById('m_action');
            var modalApplicationIdInput = document.getElementById('m_application_id');
            var directorNotesInput = document.getElementById('m_director_notes');
            var decisionModal = document.getElementById('director-decision-modal');
            var decisionMessage = document.getElementById('decisionModalMessage');
            var decisionCancelBtn = document.getElementById('decisionCancelBtn');
            var decisionConfirmBtn = document.getElementById('decisionConfirmBtn');
            var pendingDecision = null;

            function closeDetailModal() {
                if (detailModal) {
                    detailModal.classList.remove('open');
                    detailModal.setAttribute('aria-hidden', 'true');
                }
            }

            function closeDecisionModal() {
                if (decisionModal) {
                    decisionModal.classList.remove('open');
                    decisionModal.setAttribute('aria-hidden', 'true');
                }
                pendingDecision = null;
            }

            function openDecisionModal(actionText, onConfirm) {
                if (!decisionModal || !decisionMessage) {
                    if (typeof onConfirm === 'function') {
                        onConfirm();
                    }
                    return;
                }
                decisionMessage.textContent = 'Adakah anda ingin meneruskan tindakan "' + actionText + '"?';
                pendingDecision = onConfirm;
                decisionModal.classList.add('open');
                decisionModal.setAttribute('aria-hidden', 'false');
            }

            document.querySelectorAll('.btn-view').forEach(function (btn) {
                btn.addEventListener('click', function () {
                    if (!detailModal) {
                        return;
                    }

                    setModalValue('m_current_status', btn.dataset.current_status, false);
                    setModalValue('m_reviewed_at', btn.dataset.reviewed_at, false);
                    setModalValue('m_full_name', btn.dataset.full_name, false);
                    setModalValue('m_user_email', btn.dataset.user_email, false);
                    setModalValue('m_application_type', btn.dataset.application_type, false);
                    setModalValue('m_submitted_at', btn.dataset.submitted_at, false);
                    setModalValue('m_company_name', btn.dataset.company_name, false);
                    setModalValue('m_company_address', btn.dataset.company_address, true);
                    setModalValue('m_contact_number', btn.dataset.contact_number, false);
                    setModalValue('m_supplier_email', btn.dataset.supplier_email, false);
                    setModalValue('m_supplier_name', btn.dataset.supplier_name, false);
                    setModalValue('m_supplier_phone', btn.dataset.supplier_phone, false);
                    setModalValue('m_supplier_address', btn.dataset.supplier_address, true);
                    setModalValue('m_manufacturer_name', btn.dataset.manufacturer_name, false);
                    setModalValue('m_manufacturer_phone', btn.dataset.manufacturer_phone, false);
                    setModalValue('m_manufacturer_address', btn.dataset.manufacturer_address, true);
                    setModalValue('m_principal_name', btn.dataset.principal_name, false);
                    setModalValue('m_principal_phone', btn.dataset.principal_phone, false);
                    setModalValue('m_principal_address', btn.dataset.principal_address, true);
                    setModalValue('m_product_category', btn.dataset.product_category, false);
                    setModalValue('m_product_name', btn.dataset.product_name, false);
                    setModalValue('m_product_description', btn.dataset.product_description, true);
                    setModalValue('m_standard_name', btn.dataset.standard_name, false);
                    setModalValue('m_certification_license', btn.dataset.certification_license, false);
                    setModalValue('m_certification_valid_until', btn.dataset.certification_valid_until, false);
                    setModalValue('m_test_report_reference', btn.dataset.test_report_reference, false);
                    setModalValue('m_test_report_date', btn.dataset.test_report_date, false);
                    setModalValue('m_warranty_years', btn.dataset.warranty_years, false);
                    setModalValue('m_sabah_rep_name', btn.dataset.sabah_rep_name, false);
                    setModalValue('m_sabah_rep_phone', btn.dataset.sabah_rep_phone, false);
                    setModalValue('m_sabah_rep_address', btn.dataset.sabah_rep_address, true);
                    setModalValue('m_declaration_name', btn.dataset.declaration_name, false);
                    setModalValue('m_declaration_position', btn.dataset.declaration_position, false);
                    if (modalApplicationIdInput) {
                        modalApplicationIdInput.value = btn.closest('tr').querySelector('input[name="application_id"]').value;
                    }

                    detailModal.classList.add('open');
                    detailModal.setAttribute('aria-hidden', 'false');
                });
            });

            if (detailModalClose) {
                detailModalClose.addEventListener('click', closeDetailModal);
            }
            if (detailModalClose2) {
                detailModalClose2.addEventListener('click', closeDetailModal);
            }

            if (detailModal) {
                detailModal.addEventListener('click', function (event) {
                    if (event.target === detailModal) {
                        closeDetailModal();
                    }
                });
            }

            var actionLabels = {
                accept_application: 'Lulus',
                approve_application: 'Lulus',
                reject_application: 'Gagal',
                suspend_application: 'Gantung',
                cancel_application: 'Batal',
                query_application: 'Kuiri'
            };

            var requiresNotes = {
                reject_application: true,
                suspend_application: true,
                cancel_application: true,
                query_application: true
            };

            function getDirectorNotes() {
                return directorNotesInput ? directorNotesInput.value.trim() : '';
            }

            document.querySelectorAll('[data-modal-action]').forEach(function (btn) {
                btn.addEventListener('click', function () {
                    if (!modalActionForm || !modalActionInput || !modalApplicationIdInput || !modalApplicationIdInput.value) {
                        return;
                    }
                    var action = btn.getAttribute('data-modal-action');
                    var actionText = (btn.textContent || '').trim() || actionLabels[action] || 'Kemaskini';
                    if (requiresNotes[action] && !getDirectorNotes()) {
                        alert('Sila isi ulasan atau sebab keputusan sebelum meneruskan tindakan ini.');
                        if (directorNotesInput) {
                            directorNotesInput.focus();
                        }
                        return;
                    }
                    openDecisionModal(actionText, function () {
                        modalActionInput.value = action;
                        modalActionForm.submit();
                    });
                });
            });

            document.querySelectorAll('.action-dropdown').forEach(function (dropdown) {
                var form = dropdown.parentElement.querySelector('.director-action-form');
                if (!form) {
                    return;
                }

                dropdown.querySelectorAll('.action-item').forEach(function (item) {
                    item.addEventListener('click', function () {
                        var action = item.getAttribute('data-action');
                        var hiddenAction = form.querySelector('input[name="director_action"]');
                        var hiddenNotes = form.querySelector('input[name="director_notes"]');
                        if (!hiddenAction || !action) {
                            return;
                        }

                        if (requiresNotes[action]) {
                            closeAllMenus();
                            var btnText = (item.textContent || '').trim() || actionLabels[action] || 'tindakan ini';
                            var inputNotes = window.prompt('Sila masukkan ulasan untuk tindakan ' + btnText + ':', '');
                            if (inputNotes === null) {
                                return;
                            }
                            inputNotes = inputNotes.trim();
                            if (!inputNotes) {
                                alert('Ulasan wajib diisi untuk tindakan ini.');
                                return;
                            }
                            if (hiddenNotes) {
                                hiddenNotes.value = inputNotes;
                            }
                            var actionTextWithNotes = (item.textContent || '').trim() || actionLabels[action] || 'Kemaskini';
                            openDecisionModal(actionTextWithNotes, function () {
                                hiddenAction.value = action;
                                form.submit();
                            });
                            return;
                        }

                        var actionText = (item.textContent || '').trim() || actionLabels[action] || 'Kemaskini';
                        openDecisionModal(actionText, function () {
                            if (hiddenNotes) {
                                hiddenNotes.value = '';
                            }
                            hiddenAction.value = action;
                            form.submit();
                        });
                    });
                });
            });

            if (decisionCancelBtn) {
                decisionCancelBtn.addEventListener('click', closeDecisionModal);
            }

            if (decisionConfirmBtn) {
                decisionConfirmBtn.addEventListener('click', function () {
                    var handler = pendingDecision;
                    closeDecisionModal();
                    if (typeof handler === 'function') {
                        handler();
                    }
                });
            }

            if (decisionModal) {
                decisionModal.addEventListener('click', function (event) {
                    if (event.target === decisionModal) {
                        closeDecisionModal();
                    }
                });
            }

            document.addEventListener('click', function () {
                closeAllMenus();
            });

            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape') {
                    closeDecisionModal();
                    closeDetailModal();
                }
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
                var successNotice = document.querySelector('.notice-success');
                if (successNotice) {
                    var text = (successNotice.textContent || '').trim();
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
                message = 'Tindakan anda telah berjaya direkodkan.';
            }
            showSuccessPopup(message);
        })();
    </script>
</body>
</html>

