<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>
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

    private String buildImageSrc(String contextPath, Object imageUrlValue) {
        if (imageUrlValue == null) {
            return "";
        }

        String raw = String.valueOf(imageUrlValue).trim().replace('\\', '/');
        if (raw.isEmpty()) {
            return "";
        }

        int assetsIndex = raw.indexOf("/assets/");
        if (assetsIndex > 0) {
            raw = raw.substring(assetsIndex);
        } else {
            int assetsRelativeIndex = raw.indexOf("assets/");
            if (assetsRelativeIndex > 0) {
                raw = "/" + raw.substring(assetsRelativeIndex);
            }
        }

        while (raw.contains("//") && !raw.startsWith("//")) {
            raw = raw.replace("//", "/");
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

        String lower = raw.toLowerCase(java.util.Locale.ROOT);
        if (lower.startsWith("http://") || lower.startsWith("https://") || lower.startsWith("data:") || raw.startsWith("//")) {
            return raw;
        }

        String safeContextPath = contextPath == null ? "" : contextPath.trim();
        if (safeContextPath.isEmpty() || "/".equals(safeContextPath)) {
            safeContextPath = "";
        }

        if (raw.startsWith("/")) {
            if (!safeContextPath.isEmpty() && raw.startsWith(safeContextPath + "/")) {
                return raw;
            }
            return safeContextPath + raw;
        }

        return safeContextPath + "/" + raw;
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Pentadbir - SPPA</title>
    <style>
        /* ── Design tokens ───────────────────────────── */
        :root {
            --brand-blue: #0097d9;
            --brand-navy: #06344f;
            --brand-yellow: #fff212;
            --surface: #ffffff;
            --surface-soft: #f7fbff;
            --line: #d9e7f1;
            --text: #183244;
            --muted: #637d8d;
            --tr: 0.2s ease;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(180deg, #f4fbff 0%, #f9fcfd 100%); color: var(--text); }
        .navbar { background: linear-gradient(130deg, var(--brand-navy) 0%, var(--brand-blue) 76%, var(--brand-yellow) 190%); color: white; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; gap: 20px; }
        .brand { display: flex; align-items: center; gap: 14px; }
        .brand-logo { width: 52px; height: 52px; border-radius: 14px; object-fit: contain; padding: 4px; }
        .brand h1 { margin: 0; font-size: 19px; font-weight: 700; letter-spacing: -0.2px; }
        .brand p { margin: 2px 0 0; font-size: 12px; opacity: 0.85; }
        .navbar a { color: white; text-decoration: none; margin-left: 14px; font-weight: 600; font-size: 13px; display: inline-flex; align-items: center; gap: 6px; opacity: 0.92; transition: opacity var(--tr); }
        .navbar a:hover { opacity: 1; }
        .navbar > div:last-child { display: flex; align-items: center; flex-wrap: wrap; justify-content: flex-end; gap: 8px; }
        .navbar > div:last-child span { font-size: 13px; font-weight: 600; margin-right: 6px; }
        .icon-inline { width: 14px; height: 14px; object-fit: contain; vertical-align: middle; }
        .icon-link { width: 32px; height: 32px; margin-left: 6px; border-radius: 999px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.4); display: inline-flex; align-items: center; justify-content: center; padding: 0; }
        .icon-link img { width: 20px; height: 20px; object-fit: contain; vertical-align: middle; }
        .panel-expand-btn { background: none; border: none; cursor: pointer; padding: 4px; display: inline-flex; align-items: center; }
        .panel-expand-btn img { width: 18px; height: 18px; object-fit: contain; }
        .container { max-width: 1320px; margin: 28px auto; padding: 0 20px 32px; }
        .left-panel, .right-panel { min-width: 0; }
        .hero { display: grid; grid-template-columns: 1.8fr 1fr; gap: 20px; margin-bottom: 20px; }
        .panel { background: var(--surface); border: 1px solid var(--line); border-radius: 20px; box-shadow: 0 16px 40px rgba(6, 52, 79, 0.08); padding: 22px; }
        .hero h2 { margin-top: 0; font-size: 30px; }
        .hero p { color: var(--muted); line-height: 1.7; max-width: 760px; }
        .metric-strip { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .metric-chip { background: var(--surface-soft); border: 1px solid var(--line); padding: 10px 14px; border-radius: 999px; font-weight: 700; }
        .contact-image { width: 100%; border-radius: 16px; border: 1px solid var(--line); padding: 14px; background: #f7fbff; }
        .contact-image strong { display: block; margin-bottom: 8px; color: var(--brand-navy); }
        .contact-image p { margin: 4px 0; color: var(--muted); font-size: 14px; }
        .stats { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 16px; margin-bottom: 20px; }
        .stat-card { background: var(--surface); padding: 18px; border-radius: 18px; border: 1px solid var(--line); box-shadow: 0 12px 30px rgba(6, 52, 79, 0.06); }
        .stat-card h3 { margin: 0 0 8px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
        .stat-card .number { font-size: 30px; font-weight: 800; color: var(--brand-navy); }
        .layout { display: grid; grid-template-columns: 1.9fr 1fr; gap: 20px; }
        .toolbar { display: grid; grid-template-columns: minmax(220px, 1.6fr) repeat(3, minmax(140px, 1fr)); gap: 12px; align-items: end; margin-bottom: 16px; }
        .export-control { min-width: 0; }
        .export-help { margin-top: 6px; font-size: 12px; color: var(--muted); }
        .field { min-width: 0; }
        .field label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .field input, .field select { width: 100%; padding: 11px 12px; border-radius: 12px; border: 1px solid var(--line); }
        .btn { padding: 11px 15px; border-radius: 12px; border: 1px solid #fff; text-decoration: none; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; }
        .btn-primary { background: var(--brand-blue); color: white; }
        .btn-secondary { background: #dcecf6; color: var(--brand-navy); }
        .btn-accent { background: #fff7b0; color: #6a5a00; }
        .section-stack { display: grid; gap: 18px; }
        .announcement-panel { border-top: 4px solid #0097d9; }
        .announcement-head { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
        .announcement-head img { width: 18px; height: 18px; object-fit: contain; }
        .announce-alert { margin-bottom: 12px; border-radius: 10px; padding: 10px 12px; font-size: 13px; }
        .announce-success { background: #e7f9ec; color: #166534; border: 1px solid #b8e7c6; }
        .announce-error { background: #fff1f2; color: #b91c1c; border: 1px solid #fecdd3; }
        .announcement-form { display: grid; gap: 10px; margin-bottom: 14px; }
        .announcement-form input[type="text"], .announcement-form textarea { width: 100%; border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px; font: inherit; }
        .announcement-form input[type="file"] { width: 100%; border: 1px dashed var(--line); border-radius: 10px; padding: 10px 12px; font: inherit; background: #f9fcff; }
        .announcement-form textarea { min-height: 96px; resize: vertical; }
        .announce-image-preview { margin-top: 8px; }
        .announce-image-preview img { width: 100%; max-width: 220px; height: auto; border: 1px solid var(--line); border-radius: 10px; }
        .announcement-form { display: grid; gap: 10px; margin-bottom: 14px; }
        .announcement-form input[type="text"],
        .announcement-form textarea {
            width: 100%; border: 1px solid var(--line); border-radius: 10px;
            padding: 10px 12px; font: inherit; font-size: 13px;
            background: var(--surface-soft);
            transition: border-color var(--tr), box-shadow var(--tr);
        }
        .announcement-form input[type="text"]:focus,
        .announcement-form textarea:focus {
            outline: none;
            border-color: var(--brand-navy);
            box-shadow: 0 0 0 3px rgba(15,107,174,0.1);
        }
        .announcement-form input[type="file"] {
            width: 100%; border: 1px dashed var(--line); border-radius: 10px;
            padding: 10px 12px; font: inherit; background: var(--surface-soft);
        }
        .announcement-form textarea { min-height: 96px; resize: vertical; }
        .announcement-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .announcement-table td { font-size: 13px; }
        .icon-btn { width: 13px; height: 13px; object-fit: contain; }
        .table-card-header { display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 14px; }
        .section-title { margin: 0; font-size: 17px; color: var(--brand-navy); }
        .table-wrapper { overflow-x: auto; max-width: 100%; border: 1px solid var(--line); border-radius: 14px; }
        table { width: 100%; border-collapse: collapse; min-width: 700px; background: white; }
        th, td { padding: 11px 10px; border-bottom: 1px solid #e7eef4; text-align: left; vertical-align: top; }
        th { font-size: 12px; text-transform: uppercase; letter-spacing: 0.03em; color: #4f6776; background: #f6fbff; }
        td { font-size: 13px; }
        .table-check { width: 16px; height: 16px; cursor: pointer; }
        .subtle { color: #607989; font-size: 12px; line-height: 1.4; }
        .empty { text-align: center; color: #6e8492; padding: 18px; }
        .status-pill { display: inline-flex; align-items: center; justify-content: center; border-radius: 999px; font-size: 11px; font-weight: 700; padding: 4px 10px; }
        .status-new { background: #dbeafe; color: #1e40af; }
        .status-under_review { background: #e0f2fe; color: #0369a1; }
        .status-in_progress { background: #ede9fe; color: #7c3aed; }
        .status-approved { background: #dff5e7; color: #156b3c; }
        .status-rejected { background: #ffe1e4; color: #9f1f2b; }
        .status-suspended { background: #ececf2; color: #4a4a60; }
        .status-draft { background: #e8f0fb; color: #1b4f8f; }
        .status-archived { background: #eef1f4; color: #455867; }
        .bulk-toolbar { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin: 12px 0; }
        .bulk-count { margin-left: 6px; color: #5c7788; font-size: 13px; font-weight: 600; }
        .btn-danger { background: #fbe0e3; color: #9f1f2b; border-color: #f4c5cb; }
        .btn-archive { background: #eef3f7; color: #3f5461; border-color: #d1dce4; }
        .action-cell { display: flex; align-items: stretch; gap: 6px; flex-wrap: wrap; min-width: 0; }
        .action-cell .btn,
        .action-cell form { min-width: 104px; flex: 1 1 104px; }
        .action-cell .btn { width: 100%; min-height: 40px; white-space: nowrap; }
        .action-cell form { margin: 0; display: inline-flex; }
        .action-cell form .btn-archive {
            min-width: 40px;
            width: 40px;
            padding: 0;
            flex: 0 0 40px;
        }
        .action-cell form .btn-archive .icon-btn {
            width: 16px;
            height: 16px;
        }
        .archive-toast {
            position: fixed;
            right: 20px;
            bottom: 22px;
            z-index: 1500;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 14px;
            border-radius: 12px;
            background: #ffffff;
            border: 1px solid #d4e4ef;
            box-shadow: 0 14px 34px rgba(6, 52, 79, 0.20);
            transform: translateY(14px);
            opacity: 0;
            pointer-events: none;
            transition: opacity var(--tr), transform var(--tr);
        }
        .archive-toast.show {
            opacity: 1;
            transform: translateY(0);
        }
        .archive-toast img {
            width: 20px;
            height: 20px;
            object-fit: contain;
            animation: toastPulse 0.95s ease-in-out infinite;
        }
        .archive-toast span {
            font-size: 13px;
            font-weight: 700;
            color: #24495e;
        }
        @keyframes toastPulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.16); }
            100% { transform: scale(1); }
        }
        .export-summary { margin: 10px 0 14px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
        .export-metric { border: 1px solid var(--line); border-radius: 10px; background: #f9fcff; padding: 8px 10px; }
        .export-metric small { display: block; color: #617c8d; font-size: 11px; }
        .export-metric strong { display: block; color: #0a4a7b; font-size: 18px; margin-top: 2px; }
        .quick-actions { display: grid; grid-template-columns: 1fr; gap: 8px; }
        .notification-list, .activity-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }
        .notification-item, .activity-item { border: 1px solid var(--line); border-radius: 12px; padding: 10px; background: #f9fcff; }
        .notification-item strong, .activity-item strong { display: block; margin-bottom: 4px; font-size: 13px; color: #0d4f80; }
        .notification-item span, .activity-item span { color: #577082; font-size: 12px; }
        .notif-warning { border-left: 4px solid #f1b100; }
        .notif-recent { border-left: 4px solid #0f6bae; }
        .status-alert-panel { margin-bottom: 16px; border: 1px solid #ffe6a7; border-left: 5px solid #f4b400; background: #fff9e8; border-radius: 12px; padding: 12px 14px; }
        .status-alert-title { margin: 0 0 8px; color: #7d5500; font-size: 14px; }
        .status-alert-list { margin: 0; padding-left: 18px; color: #694d0f; font-size: 13px; }
        .title-wrap { display: flex; align-items: center; gap: 8px; min-width: 0; }
        .legend-label { display: inline-flex; align-items: center; gap: 8px; }
        .legend-value { font-weight: 700; color: #0f456f; }
        .legend-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
        .legend-dot.approved { background: #1b8f55; }
        .legend-dot.rejected { background: #cf4e4e; }
        .legend-dot.new { background: #3b82f6; }
        .jans-contact-section { margin-top: 10px; border: 1px solid #d6e5ef; border-radius: 14px; background: #f8fcff; padding: 12px; }
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; }
        .contact-line { display: flex; gap: 8px; align-items: flex-start; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; }
        .contact-icon { display: inline-block; width: 10px; height: 10px; background: #0f6bae; border-radius: 2px; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-address-link { color: #0f6bae; text-decoration: none; }
        .contact-address-link:hover { text-decoration: underline; }

        @media (max-width: 1200px) {
            .stats { grid-template-columns: repeat(3, minmax(0, 1fr)); }
            .layout { grid-template-columns: 1fr; }
            .toolbar { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .export-summary { grid-template-columns: 1fr; }
            .kpp-action-grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 860px) {
            .navbar { padding: 12px 14px; flex-direction: column; align-items: flex-start; }
            .navbar > div:last-child { justify-content: flex-start; }
            .container { padding: 0 10px 20px; }
            .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .toolbar { grid-template-columns: 1fr; }
            .panel { padding: 14px; border-radius: 14px; }
            .brand-logo { width: 42px; height: 42px; }
            .brand h1 { font-size: 16px; }
            table { min-width: 620px; }
            .action-cell { flex-direction: column; }
            body.popup-open .table-card.popup-active,
            body.popup-open #announcementPanel.popup-active {
                width: calc(100vw - 10px);
                max-height: calc(100vh - 12px);
                border-radius: 12px;
            }
        }

        /* ── Misc ────────────────────────────────────── */
        .announce-with-gif { display: flex; align-items: center; gap: 10px; }
        .announce-title  { font-weight: 700; color: var(--brand-navy); }
        .announce-content { color: var(--muted); margin-top: 4px; white-space: pre-wrap; }
        .announce-status { display: inline-block; border-radius: 999px; padding: 3px 10px; font-size: 11px; font-weight: 700; }
        .announce-active   { background: #d1fae5; color: #065f46; }
        .announce-inactive { background: #e9edf2; color: #374151; }
        .analytics-chart {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-top: 8px;
            flex-wrap: wrap;
        }
        .pie-chart {
            width: 128px;
            height: 128px;
            border-radius: 50%;
            position: relative;
            flex: 0 0 auto;
            box-shadow: inset 0 0 0 1px rgba(255,255,255,0.45), 0 6px 16px rgba(0,0,0,0.08);
        }
        .pie-chart[data-gradient] {
            background: var(--pie-gradient, conic-gradient(#1b8f55 0deg, #cf4e4e 120deg, #df8f1f 240deg));
        }
        .pie-chart::after {
            content: '';
            position: absolute;
            inset: 26%;
            border-radius: 50%;
            background: #ffffff;
            border: 1px solid #e4edf4;
        }
        .pie-center {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            z-index: 2;
            text-align: center;
        }
        .pie-center small {
            display: block;
            font-size: 11px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .pie-center strong {
            display: block;
            font-size: 16px;
            color: #0F6BAE;
            line-height: 1.1;
            font-weight: 800;
        }
        .analytics-legend {
            list-style: none;
            margin: 0;
            padding: 0;
            display: grid;
            gap: 8px;
            min-width: 0;
            flex: 1 1 180px;
        }
        .analytics-legend li {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 8px 10px;
            border-radius: 10px;
            background: #f7fbff;
            border: 1px solid #e2edf5;
            font-size: 13px;
        }
        .kpp-action-panel {
            border-top: 4px solid #0f6bae;
            background: linear-gradient(180deg, #ffffff 0%, #f6fbff 100%);
        }
        .kpp-action-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 14px;
            align-items: start;
        }
        .kpp-form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        .kpp-form-span {
            grid-column: 1 / -1;
        }
        .kpp-draft {
            border: 1px solid #d7e7f3;
            border-radius: 12px;
            background: #ffffff;
            padding: 10px;
            display: grid;
            gap: 8px;
        }
        .kpp-draft label {
            font-size: 12px;
            font-weight: 700;
            color: #5b7485;
        }
        .kpp-draft input,
        .kpp-draft textarea {
            width: 100%;
            border: 1px solid #d4e4ef;
            border-radius: 10px;
            background: #f9fcff;
            padding: 9px 10px;
            font: inherit;
            font-size: 13px;
            color: #28475c;
        }
        .kpp-draft textarea {
            min-height: 118px;
            resize: vertical;
            line-height: 1.45;
        }
        .kpp-help {
            margin: 0;
            color: #5f7787;
            font-size: 12px;
        }
        .kpp-submission-box {
            border: 1px solid #d7e7f3;
            border-radius: 12px;
            background: #ffffff;
            padding: 10px;
        }
        .kpp-submission-title {
            margin: 0 0 8px;
            font-size: 13px;
            color: #0f456f;
            font-weight: 800;
        }
        .kpp-submission-toolbar {
            display: flex;
            gap: 8px;
            align-items: center;
            margin-bottom: 10px;
            flex-wrap: wrap;
        }
        .kpp-search-wrap {
            flex: 1 1 260px;
            display: flex;
            align-items: center;
            gap: 8px;
            border: 1px solid #d4e6f3;
            border-radius: 10px;
            padding: 6px 8px;
            background: #f8fcff;
        }
        .kpp-search-wrap img {
            width: 16px;
            height: 16px;
            object-fit: contain;
            opacity: 0.85;
        }
        .kpp-search-wrap input {
            border: 0;
            outline: 0;
            background: transparent;
            width: 100%;
            font: inherit;
            font-size: 12px;
            color: #214459;
        }
        .kpp-toolbar-btn {
            border: 1px solid #bfd8ea;
            border-radius: 9px;
            padding: 7px 10px;
            background: #eaf5fc;
            color: #0f4f79;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .kpp-toolbar-btn:hover {
            background: #ddedf9;
        }
        .kpp-submission-actions {
            margin-top: 7px;
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
        }
        .kpp-action-btn {
            width: 30px;
            height: 30px;
            border: 1px solid #c8deec;
            border-radius: 8px;
            background: #ffffff;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0;
            cursor: pointer;
        }
        .kpp-action-btn img {
            width: 16px;
            height: 16px;
            object-fit: contain;
        }
        .kpp-action-btn:hover {
            background: #eef7fd;
        }
        .kpp-inline-form {
            margin: 0;
            display: inline-flex;
        }
        .kpp-submission-list {
            list-style: none;
            margin: 0;
            padding: 0;
            display: grid;
            gap: 8px;
        }
        .kpp-submission-item {
            border: 1px solid #d9e9f4;
            border-radius: 10px;
            background: #f8fcff;
            padding: 8px 10px;
        }
        .kpp-submission-item strong {
            display: block;
            color: #143f61;
            font-size: 13px;
            margin-bottom: 4px;
        }
        .kpp-submission-item span {
            display: block;
            color: #5a7485;
            font-size: 12px;
            line-height: 1.4;
        }
        .kpp-view-btn {
            margin-top: 6px;
            border: 1px solid #b7d5ea;
            background: #eaf5fc;
            color: #0f517e;
            border-radius: 8px;
            padding: 6px 10px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .kpp-view-btn:hover {
            background: #dff0fb;
        }
        .kpp-modal {
            position: fixed;
            inset: 0;
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1300;
            padding: 16px;
            background: rgba(2, 18, 31, 0.55);
        }
        .kpp-modal.show {
            display: flex;
        }
        .kpp-modal-card {
            width: min(940px, 100%);
            max-height: calc(100vh - 40px);
            overflow: auto;
            background: #ffffff;
            border: 1px solid #d5e5f1;
            border-radius: 14px;
            box-shadow: 0 22px 50px rgba(3, 23, 40, 0.28);
            padding: 14px;
        }
        .kpp-modal-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 10px;
        }
        .kpp-modal-head h4 {
            margin: 0;
            font-size: 16px;
            color: #103f63;
        }
        .kpp-modal-close {
            border: 1px solid #c9dcea;
            background: #f5faff;
            color: #375b73;
            border-radius: 8px;
            padding: 6px 10px;
            cursor: pointer;
            font-weight: 700;
        }
        .kpp-modal-meta {
            margin: 0 0 10px;
            color: #587083;
            font-size: 12px;
        }
        .kpp-modal-grid {
            display: grid;
            gap: 10px;
        }
        .kpp-modal-section {
            border: 1px solid #d8e8f4;
            border-radius: 9px;
            padding: 10px;
            background: #f9fcff;
        }
        .kpp-modal-borang-title {
            margin: 14px 0 6px;
            font-size: 13px;
            font-weight: 700;
            color: #0a3256;
            padding: 7px 12px;
            background: #ddeefa;
            border-left: 4px solid #1565a8;
            border-radius: 5px;
        }
        .kpp-modal-section h5 {
            margin: 0 0 8px;
            font-size: 13px;
            color: #0f456f;
        }
        .kpp-modal-fields {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 8px;
        }
        .kpp-modal-fields.kpp-single-column {
            grid-template-columns: 1fr;
        }
        .kpp-modal-row {
            border: 1px solid #e1edf6;
            border-radius: 8px;
            padding: 7px;
            background: #ffffff;
        }
        .kpp-modal-row b {
            display: block;
            color: #124164;
            font-size: 12px;
            margin-bottom: 3px;
        }
        .kpp-modal-row span {
            display: block;
            color: #2d4b5f;
            font-size: 12px;
            white-space: pre-wrap;
            line-height: 1.45;
        }
        .kpp-modal-row-syor b,
        .kpp-modal-row-syor span {
            font-weight: 800;
            color: #0f456f;
        }
        .kpp-modal-row-syor span.kpp-syor-accepted {
            color: #166534;
        }
        .kpp-modal-row-syor span.kpp-syor-rejected {
            color: #b91c1c;
        }
        @media (max-width: 860px) {
            .kpp-modal-fields {
                grid-template-columns: 1fr;
            }
        }
        .expand-overlay {
            position: fixed;
            inset: 0;
            background: rgba(3, 18, 32, 0.62);
            backdrop-filter: blur(2px);
            display: none;
            z-index: 1200;
        }
        body.popup-open { overflow: hidden; }
        body.popup-open .expand-overlay { display: block; }
        body.popup-open .table-card.popup-active,
        body.popup-open #announcementPanel.popup-active {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: min(1120px, calc(100vw - 24px));
            max-height: calc(100vh - 38px);
            overflow: auto;
            z-index: 1210;
            border-radius: 18px;
            box-shadow: 0 30px 90px rgba(2, 24, 43, 0.44);
            margin: 0;
        }
        .panel-expand-btn[aria-expanded="true"] img { transform: rotate(180deg); }
        .panel-expand-btn img { transition: transform var(--tr); }
        </style>
</head>
<body>
    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Dashboard Pentadbir</h1>
                <p>Pusat kawalan permohonan, produk, dan laporan SPPA</p>
            </div>
        </div>
        <div>
            <span>Selamat datang, <%= session.getAttribute("username") %></span>
            <a href="${pageContext.request.contextPath}/admin/users">Senarai Pengguna</a>
            <a href="${pageContext.request.contextPath}/products">Senarai Produk</a>
            <a href="${pageContext.request.contextPath}/profile">Kemaskini Profil</a>
            <a class="icon-link" href="${pageContext.request.contextPath}/" title="Laman Utama" aria-label="Laman Utama"><img src="${pageContext.request.contextPath}/assets/images/home.png" alt="Home"></a>
            <a class="icon-link" href="${pageContext.request.contextPath}/logout" title="Log Keluar" aria-label="Log Keluar"><img src="${pageContext.request.contextPath}/assets/images/Logout.png" alt="Log Keluar"></a>
        </div>
    </div>

    <div class="container">
        <div class="stats">
            <div class="stat-card main">
                <h3>Jumlah Permohonan</h3>
                <div class="number"><%= request.getAttribute("total_applications") != null ? request.getAttribute("total_applications") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Menunggu</h3>
                <div class="number"><%= request.getAttribute("pending_count") != null ? request.getAttribute("pending_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Diluluskan</h3>
                <div class="number"><%= request.getAttribute("approved_count") != null ? request.getAttribute("approved_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Ditolak</h3>
                <div class="number"><%= request.getAttribute("rejected_count") != null ? request.getAttribute("rejected_count") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Produk Berdaftar</h3>
                <div class="number"><%= request.getAttribute("total_products") != null ? request.getAttribute("total_products") : "0" %></div>
            </div>
            <div class="stat-card">
                <h3>Diarkib</h3>
                <div class="number"><%= request.getAttribute("archived_count") != null ? request.getAttribute("archived_count") : "0" %></div>
            </div>
        </div>

        <%
            int pendingCountAlert = request.getAttribute("pending_count") instanceof Number ? ((Number) request.getAttribute("pending_count")).intValue() : 0;
            int rejectedCountAlert = request.getAttribute("rejected_count") instanceof Number ? ((Number) request.getAttribute("rejected_count")).intValue() : 0;
            boolean showStatusAlert = pendingCountAlert > 7 || rejectedCountAlert > 10;
        %>
        <% if (showStatusAlert) { %>
        <div class="status-alert-panel">
            <h4 class="status-alert-title">Amaran Status Permohonan</h4>
            <ul class="status-alert-list">
                <% if (pendingCountAlert > 7) { %>
                <li>Jumlah permohonan menunggu semakan melebihi 7 rekod. Sila semak keutamaan proses.</li>
                <% } %>
                <% if (rejectedCountAlert > 10) { %>
                <li>Jumlah permohonan ditolak adalah tinggi. Sila semak punca utama penolakan.</li>
                <% } %>
            </ul>
        </div>
        <% } %>

        <%
            List<Map<String, Object>> applications = (List<Map<String, Object>>) request.getAttribute("pending_applications");
            List<Map<String, Object>> kppGuestSubmissions = (List<Map<String, Object>>) request.getAttribute("kpp_guest_submissions");
            boolean isAdminRole = "ADMIN".equals(String.valueOf(session.getAttribute("role")));
        %>

        <div class="layout">
            <div class="left-panel">
                <div class="panel table-card">
                    <div class="table-card-header">
                        <h3 class="section-title">Permohonan Terkini</h3>
                        <button type="button" class="panel-expand-btn" id="toggleLatestPanelBtn" aria-label="Besarkan panel permohonan" title="Expand / Collapse">
                            <img src="${pageContext.request.contextPath}/assets/images/expand.png" alt="Expand" onerror="this.style.display='none';">
                        </button>
                    </div>
                    <form method="get" action="${pageContext.request.contextPath}/dashboard" class="toolbar">
                    <div class="field">
                        <label for="q"><img src="${pageContext.request.contextPath}/assets/images/icon-search.png" class="icon-inline" alt="Ikon carian"> Carian</label>
                        <input id="q" name="q" type="text" value="<%= request.getAttribute("search_query") %>" placeholder="Cari syarikat, produk, pemohon atau email">
                    </div>
                    <div class="field">
                        <label for="status">Status</label>
                        <select id="status" name="status">
                            <option value="">Semua status</option>
                            <option value="NEW" <%= "NEW".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>NEW</option>
                            <option value="UNDER_REVIEW" <%= "UNDER_REVIEW".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>UNDER REVIEW</option>
                            <option value="IN_PROGRESS" <%= "IN_PROGRESS".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>IN PROGRESS</option>
                            <option value="APPROVED" <%= "APPROVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>APPROVED</option>
                            <option value="REJECTED" <%= "REJECTED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>REJECTED</option>
                            <option value="SUSPENDED" <%= "SUSPENDED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>SUSPENDED</option>
                            <option value="DRAFT" <%= "DRAFT".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DRAFT</option>
                            <option value="ARCHIVED" <%= "ARCHIVED".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>ARCHIVED</option>
                        </select>
                    </div>
                    <div class="field">
                        <label for="date_from">Tarikh Dari</label>
                        <input id="date_from" name="date_from" type="date" value="<%= request.getAttribute("date_from") != null ? request.getAttribute("date_from") : "" %>">
                    </div>
                    <div class="field">
                        <label for="date_to">Tarikh Hingga</label>
                        <input id="date_to" name="date_to" type="date" value="<%= request.getAttribute("date_to") != null ? request.getAttribute("date_to") : "" %>">
                    </div>
                    <button class="btn btn-primary" type="submit">Tapis</button>
                    <div class="field export-control">
                        <label for="exportOption">Eksport</label>
                        <select id="exportOption" name="exportOption">
                            <optgroup label="Ikut penapis semasa">
                                <option value="xlsx_current">Excel</option>
                                <option value="pdf_current">PDF</option>
                            </optgroup>
                            <optgroup label="Status khusus">
                                <option value="xlsx_approved">Excel - APPROVED</option>
                                <option value="xlsx_rejected">Excel - REJECTED</option>
                                <option value="pdf_approved">PDF - APPROVED</option>
                                <option value="pdf_rejected">PDF - REJECTED</option>
                            </optgroup>
                        </select>
                    </div>
                    <button class="btn btn-secondary" type="button" id="exportDownloadBtn" aria-label="Turun" title="Turun"><img src="${pageContext.request.contextPath}/assets/images/icon-download.png" class="icon-inline" alt="Ikon turun"></button>
                    </form>

                    <% if (isAdminRole) { %>
                    <form id="bulkActionForm" method="get" action="${pageContext.request.contextPath}/admin/application" data-announcement-action="true">
                        <input type="hidden" id="bulkActionType" name="bulk_action_type" value="">
                        <input type="hidden" id="bulkSelectedIds" name="selected_ids" value="">
                        <input type="hidden" id="bulkFirstId" name="id" value="">
                        <div class="bulk-toolbar">
                            <button class="btn btn-primary" id="bulkApproveBtn" type="button">Approve Selected</button>
                            <button class="btn btn-secondary" id="bulkRejectBtn" type="button">Reject Selected</button>
                            <button class="btn btn-accent" id="bulkExportBtn" type="button">Export Selected</button>
                            <span class="bulk-count" id="bulkSelectedCount">0 dipilih</span>
                        </div>
                    </form>
                    <% } %>

                    <div class="table-wrapper">
                    <table>
                    <thead>
                        <tr>
                            <% if (isAdminRole) { %>
                            <th style="width:42px;"></th>
                            <% } %>
                            <th>ID</th>
                            <th>Nama Syarikat</th>
                            <th>Status</th>
                            <th>Tarikh Penghantaran</th>
                            <th>Tindakan</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (applications == null || applications.isEmpty()) { %>
                        <tr>
                            <td colspan="<%= isAdminRole ? "6" : "5" %>" class="empty">Tiada permohonan ditemui untuk penapis ini.</td>
                        </tr>
                        <% } else {
                            for (Map<String, Object> applicationRow : applications) {
                                Timestamp submittedAt = (Timestamp) applicationRow.get("submitted_at");
                                Timestamp archivedAt = (Timestamp) applicationRow.get("archived_at");
                                String archiveNotes = applicationRow.get("archive_notes") == null ? "" : String.valueOf(applicationRow.get("archive_notes"));
                                String status = String.valueOf(applicationRow.get("status")).toLowerCase();
                                int appIdNumeric = applicationRow.get("id") instanceof Number ? ((Number) applicationRow.get("id")).intValue() : 0;
                                int appIdDisplayNumeric = Math.max(0, appIdNumeric - 1);
                                String appIdDisplay = String.format("PPP%03d", appIdDisplayNumeric);
                                boolean isArchivedRow = "archived".equals(status);
                                boolean canArchiveRow = "approved".equals(status) || "rejected".equals(status) || "suspended".equals(status);
                                String archiveConfirmText = isArchivedRow ? "Buka semula arkib permohonan ini?" : "Arkibkan permohonan ini?";
                                String archiveButtonText = isArchivedRow ? "Buka Arkib" : "Arkib";
                                String archiveActionValue = isArchivedRow ? "unarchive" : "archive";
                                String archiveIconPath = isArchivedRow
                                    ? (request.getContextPath() + "/assets/images/icon-unarchive.png")
                                    : (request.getContextPath() + "/assets/images/icon-archive.png");
                        %>
                        <tr>
                            <% if (isAdminRole) { %>
                            <td><input type="checkbox" class="app-row-check table-check" value="<%= applicationRow.get("id") %>" aria-label="Pilih permohonan"></td>
                            <% } %>
                            <td><strong><%= appIdDisplay %></strong></td>
                            <td>
                                <strong><%= applicationRow.get("company_name") %></strong><br>
                                <span class="subtle">Pemohon: <%= applicationRow.get("full_name") %><br>Email: <%= applicationRow.get("user_email") %>
                                <% if (isArchivedRow && archivedAt != null) { %><br>Arkib: <%= archivedAt %><% } %>
                                </span>
                            </td>
                            <td><span class="status-pill status-<%= status %>"><%= applicationRow.get("status") %></span></td>
                            <td><%= submittedAt != null ? submittedAt.toString() : "Belum dihantar" %></td>
                            <td>
                                <div class="action-cell">
                                <a
                                    class="btn btn-primary js-open-app-modal"
                                    href="${pageContext.request.contextPath}/admin/application?id=<%= applicationRow.get("id") %>"
                                    data-app-id="<%= applicationRow.get("id") %>"
                                    data-company="<%= escapeHtml(applicationRow.get("company_name") == null ? "" : String.valueOf(applicationRow.get("company_name")) ) %>"
                                    data-category="<%= escapeHtml(applicationRow.get("product_category") == null ? "" : String.valueOf(applicationRow.get("product_category")) ) %>"
                                    data-product="<%= escapeHtml(applicationRow.get("product_name") == null ? "" : String.valueOf(applicationRow.get("product_name")) ) %>"
                                    data-description="<%= escapeHtml(applicationRow.get("product_description") == null ? "" : String.valueOf(applicationRow.get("product_description")) ) %>"
                                    data-status="<%= escapeHtml(applicationRow.get("status") == null ? "" : String.valueOf(applicationRow.get("status")) ) %>"
                                    data-submitted="<%= escapeHtml(submittedAt != null ? submittedAt.toString() : "Belum dihantar") %>"
                                    data-user="<%= escapeHtml(applicationRow.get("full_name") == null ? "" : String.valueOf(applicationRow.get("full_name")) ) %>"
                                    data-email="<%= escapeHtml(applicationRow.get("user_email") == null ? "" : String.valueOf(applicationRow.get("user_email")) ) %>"
                                    data-attachment-image="<%= escapeHtml(applicationRow.get("attachment_image_url") == null ? "" : String.valueOf(applicationRow.get("attachment_image_url")) ) %>"
                                    data-attachment-pdf="<%= escapeHtml(applicationRow.get("attachment_pdf_url") == null ? "" : String.valueOf(applicationRow.get("attachment_pdf_url")) ) %>">
                                    Semak
                                </a>
                                <% if (isArchivedRow || canArchiveRow) { %>
                                <button
                                    class="btn btn-archive js-archive-btn"
                                    type="button"
                                    title="<%= archiveButtonText %>"
                                    aria-label="<%= archiveButtonText %>"
                                    data-app-id="<%= escapeHtml(String.valueOf(applicationRow.get("id"))) %>"
                                    data-action="<%= escapeHtml(archiveActionValue) %>"
                                    data-confirm="<%= escapeHtml(archiveConfirmText) %>"
                                    data-csrf="${csrf_token}"
                                    data-ctx="${pageContext.request.contextPath}">
                                    <img src="<%= archiveIconPath %>" class="icon-btn" alt="Arkib">
                                </button>
                                <% } %>
                                </div>
                            </td>
                        </tr>
                        <%      }
                           }
                        %>
                    </tbody>
                    </table>
                    </div><!-- /table-wrapper -->
                </div>

                <div class="panel kpp-action-panel">
                    <h3 class="section-title">Tindakan KPP</h3>
                    <div class="kpp-action-grid">
                        <div class="kpp-draft">
                            <div class="kpp-form-grid">
                                <div>
                                    <label for="kppRecipientName">Kepada (Nama Penerima)</label>
                                    <input id="kppRecipientName" type="text" placeholder="Contoh: KPP Bahagian Teknikal">
                                </div>
                                <div>
                                    <label for="kppEmailTo">Emel Penerima</label>
                                    <input id="kppEmailTo" type="email" placeholder="contoh@jans.sabah.gov.my">
                                </div>
                                <div class="kpp-form-span">
                                    <label for="kppActionType">Tindakan Diperlukan</label>
                                    <select id="kppActionType">
                                        <option value="KSPP">Isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (Pembaharuan)</option>
                                        <option value="UJPPP">Isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air</option>
                                        <option value="KSPP_UJPPP">Isi Kedua-dua Borang (KSPP dan UJPPP)</option>
                                    </select>
                                </div>
                            </div>
                            <div>
                                <label for="kppEmailSubject">Subjek Email</label>
                                <input id="kppEmailSubject" type="text" readonly>
                            </div>
                            <div>
                                <label for="kppEmailBody">Isi Email Auto-Generate</label>
                                <textarea id="kppEmailBody" readonly></textarea>
                            </div>
                            <div style="display:flex; gap:8px; flex-wrap:wrap;">
                                <button class="btn btn-primary" type="button" id="kppEmailSendBtn">Hantar Email</button>
                            </div>
                        </div>
                        <div class="kpp-submission-box" id="kpp-submissions">
                            <h4 class="kpp-submission-title">Senarai Tindakan KPP</h4>
                            <form class="kpp-submission-toolbar" method="get" action="${pageContext.request.contextPath}/dashboard#kpp-submissions">
                                <div class="kpp-search-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/images/kpp-search.png" alt="Carian">
                                    <input type="text" name="kpp_q" value="<%= escapeHtml(String.valueOf(request.getAttribute("kpp_search_query") == null ? "" : request.getAttribute("kpp_search_query"))) %>" placeholder="Cari KPP, emel, atau jenis borang">
                                </div>
                                <label style="display:inline-flex;align-items:center;gap:5px;font-size:12px;color:#4f6f83;">
                                    <input type="checkbox" name="kpp_show_archived" value="1" <%= Boolean.TRUE.equals(request.getAttribute("kpp_show_archived")) ? "checked" : "" %>>
                                    Papar arkib
                                </label>
                                <button class="kpp-toolbar-btn" type="submit">Cari</button>
                            </form>
                            <% if (kppGuestSubmissions == null || kppGuestSubmissions.isEmpty()) { %>
                                <p class="kpp-help">Belum ada borang dihantar oleh KPP.</p>
                            <% } else { %>
                                <ul class="kpp-submission-list">
                                    <% for (Map<String, Object> kppSubmission : kppGuestSubmissions) {
                                        Object submittedAt = kppSubmission.get("submitted_at");
                                        String kppSearchQuery = String.valueOf(request.getAttribute("kpp_search_query") == null ? "" : request.getAttribute("kpp_search_query"));
                                        boolean showArchived = Boolean.TRUE.equals(request.getAttribute("kpp_show_archived"));
                                        boolean kppArchived = Boolean.TRUE.equals(kppSubmission.get("archived"));
                                    %>
                                    <li class="kpp-submission-item">
                                        <strong><%= escapeHtml(String.valueOf(kppSubmission.get("kpp_display"))) %> - <%= escapeHtml(String.valueOf(kppSubmission.get("form_display"))) %></strong>
                                        <span>Tarikh Hantar: <%= submittedAt == null ? "-" : escapeHtml(String.valueOf(submittedAt)) %></span>
                                        <span>Emel Penerima: <%= escapeHtml(String.valueOf(kppSubmission.get("recipient_email"))) %></span>
                                        <div class="kpp-submission-actions">
                                            <button
                                                    class="kpp-action-btn js-kpp-view-btn"
                                                    type="button"
                                                    title="Lihat"
                                                    data-kpp="<%= escapeHtml(String.valueOf(kppSubmission.get("kpp_display"))) %>"
                                                    data-form="<%= escapeHtml(String.valueOf(kppSubmission.get("form_display"))) %>"
                                                    data-action="<%= escapeHtml(String.valueOf(kppSubmission.get("action_type"))) %>"
                                                    data-submitted="<%= submittedAt == null ? "-" : escapeHtml(String.valueOf(submittedAt)) %>"
                                                    data-payload="<%= escapeHtml(String.valueOf(kppSubmission.get("form_payload"))) %>">Lihat</button>

                                            <a class="kpp-action-btn" title="Download" href="${pageContext.request.contextPath}/dashboard?kpp_download_id=<%= kppSubmission.get("id") %><%= kppSearchQuery.isBlank() ? "" : "&kpp_q=" + java.net.URLEncoder.encode(kppSearchQuery, java.nio.charset.StandardCharsets.UTF_8) %><%= showArchived ? "&kpp_show_archived=1" : "" %>#kpp-submissions">
                                                <img src="${pageContext.request.contextPath}/assets/images/kpp-download.png" alt="Download">
                                            </a>

                                            <form class="kpp-inline-form" method="post" action="${pageContext.request.contextPath}/dashboard#kpp-submissions">
                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                <input type="hidden" name="kpp_submission_action" value="<%= kppArchived ? "unarchive" : "archive" %>">
                                                <input type="hidden" name="kpp_submission_id" value="<%= kppSubmission.get("id") %>">
                                                <input type="hidden" name="kpp_q" value="<%= escapeHtml(kppSearchQuery) %>">
                                                <% if (showArchived) { %><input type="hidden" name="kpp_show_archived" value="1"><% } %>
                                                <button class="kpp-action-btn" type="submit" title="<%= kppArchived ? "Keluarkan dari Arkib" : "Arkib" %>">
                                                    <img src="${pageContext.request.contextPath}/assets/images/kpp-archive.png" alt="<%= kppArchived ? "Keluarkan dari Arkib" : "Arkib" %>">
                                                </button>
                                            </form>

                                            <form class="kpp-inline-form" method="post" action="${pageContext.request.contextPath}/dashboard#kpp-submissions" onsubmit="return confirm('Padam borang ini?');">
                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                <input type="hidden" name="kpp_submission_action" value="delete">
                                                <input type="hidden" name="kpp_submission_id" value="<%= kppSubmission.get("id") %>">
                                                <input type="hidden" name="kpp_q" value="<%= escapeHtml(kppSearchQuery) %>">
                                                <% if (showArchived) { %><input type="hidden" name="kpp_show_archived" value="1"><% } %>
                                                <button class="kpp-action-btn" type="submit" title="Delete">
                                                    <img src="${pageContext.request.contextPath}/assets/images/kpp-delete.png" alt="Delete">
                                                </button>
                                            </form>
                                        </div>
                                    </li>
                                    <% } %>
                                </ul>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="panel">
                    <h3 class="section-title">Analitik Status Permohonan</h3>
                    <%
                        int approvedChart = request.getAttribute("approved_count") instanceof Number ? ((Number) request.getAttribute("approved_count")).intValue() : 0;
                        int rejectedChart = request.getAttribute("rejected_count") instanceof Number ? ((Number) request.getAttribute("rejected_count")).intValue() : 0;
                        int pendingChart = request.getAttribute("pending_count") instanceof Number ? ((Number) request.getAttribute("pending_count")).intValue() : 0;
                        int totalChart = Math.max(1, approvedChart + rejectedChart + pendingChart);
                        int approvedDeg = (int) Math.round((approvedChart * 360.0) / totalChart);
                        int rejectedDeg = (int) Math.round((rejectedChart * 360.0) / totalChart);
                        int pendingDeg = 360 - approvedDeg - rejectedDeg; // Pastikan total 360 darjah
                        int approvedEnd = approvedDeg;
                        int rejectedEnd = approvedDeg + rejectedDeg;
                        String pieGradient = "conic-gradient(#1b8f55 0deg " + approvedEnd + "deg, #cf4e4e " + approvedEnd + "deg " + rejectedEnd + "deg, #df8f1f " + rejectedEnd + "deg 360deg)";
                    %>
                    <div class="analytics-chart" aria-label="Carta status permohonan">
                        <div class="pie-chart" data-gradient="<%= pieGradient %>">
                            <div class="pie-center">
                                <small>Total</small>
                                <strong><%= approvedChart + rejectedChart + pendingChart %></strong>
                            </div>
                        </div>
                        <ul class="analytics-legend">
                            <li>
                                <span class="legend-label"><span class="legend-dot approved"></span>Diluluskan</span>
                                <span class="legend-value"><%= approvedChart %></span>
                            </li>
                            <li>
                                <span class="legend-label"><span class="legend-dot rejected"></span>Ditolak</span>
                                <span class="legend-value"><%= rejectedChart %></span>
                            </li>
                            <li>
                                <span class="legend-label"><span class="legend-dot new"></span>Baharu</span>
                                <span class="legend-value"><%= pendingChart %></span>
                            </li>
                        </ul>
                    </div>
                </div>

            </div>

            <div class="right-panel">
                <div class="panel">
                    <h3 class="section-title">Quick Actions</h3>
                    <div class="quick-actions">
                        <a class="btn btn-primary" href="#announcementPanel">Tambah Pengumuman</a>
                        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/admin/users">Urus Pengguna</a>
                        <a class="btn btn-archive" href="${pageContext.request.contextPath}/dashboard?status=ARCHIVED">Lihat Arkib</a>
                        <button class="btn btn-accent" type="button" id="quickExportBtn">Eksport</button>
                    </div>
                </div>

                <div class="panel">
                    <h3 class="section-title">Pemberitahuan</h3>
                    <ul class="notification-list">
                        <li class="notification-item notif-warning">
                            <strong>Permohonan Menunggu</strong>
                            <span><%= request.getAttribute("pending_count") != null ? request.getAttribute("pending_count") : "0" %> permohonan perlu semakan.</span>
                        </li>
                        <li class="notification-item notif-warning">
                            <strong>Permohonan Ditolak</strong>
                            <span><%= request.getAttribute("rejected_count") != null ? request.getAttribute("rejected_count") : "0" %> rekod memerlukan tindakan susulan.</span>
                        </li>
                        <% if (applications != null && !applications.isEmpty()) {
                            int noticeShown = 0;
                            for (Map<String, Object> appNotice : applications) {
                                if (noticeShown >= 3) { break; }
                                noticeShown++;
                        %>
                        <li class="notification-item notif-recent">
                            <strong><%= escapeHtml(String.valueOf(appNotice.get("company_name"))) %></strong>
                            <span>Status: <%= escapeHtml(String.valueOf(appNotice.get("status"))) %></span>
                        </li>
                        <%      }
                           } %>
                    </ul>
                </div>

                <div class="panel">
                    <h3 class="section-title">Aktiviti Terkini</h3>
                    <ul class="activity-list">
                        <% if (applications != null && !applications.isEmpty()) {
                            int activityShown = 0;
                            for (Map<String, Object> activityRow : applications) {
                                if (activityShown >= 5) { break; }
                                activityShown++;
                                Timestamp activityTime = (Timestamp) activityRow.get("submitted_at");
                        %>
                        <li class="activity-item">
                            <strong><%= escapeHtml(String.valueOf(activityRow.get("full_name"))) %></strong> mengemaskini permohonan
                            <span class="muted"><%= activityTime != null ? escapeHtml(activityTime.toString()) : "Masa tidak tersedia" %></span>
                        </li>
                        <%      }
                           } else { %>
                        <li class="activity-item">Tiada aktiviti terkini buat masa ini.</li>
                        <% } %>
                    </ul>
                </div>

                <div class="panel announcement-panel" id="announcementPanel">
                    <div class="announcement-head">
                        <div class="title-wrap">
                            <img src="${pageContext.request.contextPath}/assets/images/icon-announcement.png" alt="Pengumuman">
                            <h3 class="section-title" style="margin:0;">Pengurusan Pengumuman</h3>
                        </div>
                        <button type="button" class="panel-expand-btn" id="toggleAnnouncementPanelBtn" aria-label="Besarkan panel pengumuman" title="Expand / Collapse">
                            <img src="${pageContext.request.contextPath}/assets/images/expand.png" alt="Expand" onerror="this.style.display='none';">
                        </button>
                    </div>

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
                    <div style="overflow-x:auto; margin-bottom:18px;">
                        <table class="app-table announcement-table" style="width:100%;">
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
                                String annDate = annCreated == null ? "-" : String.valueOf(annCreated).substring(0, Math.min(10, String.valueOf(annCreated).length()));
                                String annStatusClass = annActive ? "announce-status announce-active" : "announce-status announce-inactive";
                                String annStatusText = annActive ? "Aktif" : "Tidak Aktif";
                            %>
                                <tr>
                                    <td><%= ai + 1 %></td>
                                    <td style="max-width:220px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<%= annTitle %>"><%= annTitle %></td>
                                    <td>
                                        <span class="<%= annStatusClass %>">
                                            <%= annStatusText %>
                                        </span>
                                    </td>
                                    <td style="font-size:12px; color:#666;"><%= annDate %></td>
                                    <td>
                                        <div style="display:flex; gap:6px; flex-wrap:wrap;">
                                            <a class="btn btn-secondary" style="padding:4px 10px; font-size:12px;"
                                               href="${pageContext.request.contextPath}/dashboard?announcement_id=<%= annId %>#announcementPanel">
                                                <img src="${pageContext.request.contextPath}/assets/images/icon-edit.png" class="icon-btn" alt="Edit" style="width:12px;height:12px;"> Edit
                                            </a>
                                            <% if (isAdminRole) { %>
                                            <form method="post" action="${pageContext.request.contextPath}/dashboard" style="margin:0;" onsubmit="return confirm('Padam pengumuman ini?');">
                                                <input type="hidden" name="_csrf" value="${csrf_token}">
                                                <input type="hidden" name="announcement_action" value="delete_announcement">
                                                <input type="hidden" name="announcement_id" value="<%= annId %>">
                                                <button type="submit" class="btn btn-danger" style="padding:4px 10px; font-size:12px;">
                                                    <img src="${pageContext.request.contextPath}/assets/images/icon-delete.png" class="icon-btn" alt="Padam" style="width:12px;height:12px;" onerror="this.style.display='none'"> Padam
                                                </button>
                                            </form>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                        <p style="color:#888; font-size:13px; margin-bottom:14px;">Tiada pengumuman lagi. Tambah pengumuman pertama di bawah.</p>
                    <% } %>

                    <h4 style="margin: 0 0 10px; font-size:14px; color:#0b5e8f;">
                        <%= (request.getAttribute("announcement_editing") != null && !((Map<?,?>)request.getAttribute("announcement_editing")).isEmpty()) ? "&#9998; Kemaskini Pengumuman" : "&#43; Tambah Pengumuman Baharu" %>
                    </h4>

                    <%
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

                    <form method="post" action="${pageContext.request.contextPath}/dashboard" class="announcement-form" enctype="multipart/form-data" data-announcement-action="true">
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
                        <label style="display:flex;align-items:center;gap:8px;">
                            <input type="checkbox" name="announcement_active" <%= formActive ? "checked" : "" %>>
                            Aktifkan paparan di halaman utama
                        </label>
                        <div class="announcement-actions">
                            <button class="btn btn-primary" type="submit">
                                <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                                    <img src="${pageContext.request.contextPath}/assets/images/icon-edit.png" class="icon-btn" alt="Edit"> Kemas Kini
                                <% } else { %>
                                    <img src="${pageContext.request.contextPath}/assets/images/icon-add.png" class="icon-btn" alt="Tambah"> Tambah
                                <% } %>
                            </button>
                            <% if (announcementEditing != null && !announcementEditing.isEmpty()) { %>
                                <a class="btn btn-secondary" href="${pageContext.request.contextPath}/dashboard#announcementPanel" data-announcement-action="true">Batal</a>
                            <% } %>
                        </div>
                    </form>
                </div>
                </div>
            </div>
        </div>

        <div class="container" style="padding-top:0;">
            <div class="jans-contact-section">
                <h3>Hubungi JANS</h3>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><span>Tel: +60-88-232364 (HQ) , Fax: +60-88-232396</span></p>
                <p class="contact-line"><span>Email: jans.hq@sabah.gov.my</span></p></div>
        </div>
    </div>
    <div class="expand-overlay" id="expandOverlay" aria-hidden="true"></div>
    <div class="kpp-modal" id="kppSubmissionModal" aria-hidden="true">
        <div class="kpp-modal-card" role="dialog" aria-modal="true" aria-labelledby="kppSubmissionModalTitle">
            <div class="kpp-modal-head">
                <h4 id="kppSubmissionModalTitle">Borang Dihantar KPP</h4>
                <button class="kpp-modal-close" type="button" id="kppSubmissionCloseBtn">Tutup</button>
            </div>
            <p class="kpp-modal-meta" id="kppSubmissionMeta"></p>
            <div class="kpp-modal-grid" id="kppSubmissionContent"></div>
        </div>
    </div>
    <div class="archive-toast" id="archiveToast" role="status" aria-live="polite">
        <img src="${pageContext.request.contextPath}/assets/images/icon-archive.png" alt="Notifikasi arkib" id="archiveToastIcon">
        <span id="archiveToastText">Berjaya.</span>
    </div>
<script>
    (function () {
        var pieChart = document.querySelector('.pie-chart[data-gradient]');
        if (pieChart && pieChart.dataset.gradient) {
            pieChart.style.background = pieChart.dataset.gradient;
        }
        
        var toolbarForm = document.querySelector('.toolbar');
        var exportButton = document.getElementById('exportDownloadBtn');
        var quickExportButton = document.getElementById('quickExportBtn');
        var exportOption = document.getElementById('exportOption');
        var searchInput = document.getElementById('q');
        var statusSelect = document.getElementById('status');
        var dateFromInput = document.getElementById('date_from');
        var dateToInput = document.getElementById('date_to');
        var selectAllApps = document.getElementById('selectAllApps');
        var appRowChecks = Array.prototype.slice.call(document.querySelectorAll('.app-row-check'));
        var bulkSelectedCount = document.getElementById('bulkSelectedCount');
        var bulkApproveBtn = document.getElementById('bulkApproveBtn');
        var bulkRejectBtn = document.getElementById('bulkRejectBtn');
        var bulkExportBtn = document.getElementById('bulkExportBtn');
        var bulkSelectedIds = document.getElementById('bulkSelectedIds');
        var bulkActionType = document.getElementById('bulkActionType');
        var bulkFirstId = document.getElementById('bulkFirstId');
        var bulkActionForm = document.getElementById('bulkActionForm');
        var layoutGrid = document.querySelector('.layout');
        var latestPanel = document.querySelector('.table-card');
        var toggleLatestPanelBtn = document.getElementById('toggleLatestPanelBtn');
        var announcementPanelCard = document.getElementById('announcementPanel');
        var toggleAnnouncementPanelBtn = document.getElementById('toggleAnnouncementPanelBtn');
        var expandOverlay = document.getElementById('expandOverlay');
        var archiveForms = Array.prototype.slice.call(document.querySelectorAll('.js-archive-form'));
        var archiveToast = document.getElementById('archiveToast');
        var archiveToastIcon = document.getElementById('archiveToastIcon');
        var archiveToastText = document.getElementById('archiveToastText');
        var toastTimer = null;
        var kppRecipientName = document.getElementById('kppRecipientName');
        var kppEmailTo = document.getElementById('kppEmailTo');
        var kppActionType = document.getElementById('kppActionType');
        var kppEmailSubject = document.getElementById('kppEmailSubject');
        var kppEmailBody = document.getElementById('kppEmailBody');
        var kppEmailSendBtn = document.getElementById('kppEmailSendBtn');
        var kppViewButtons = Array.prototype.slice.call(document.querySelectorAll('.js-kpp-view-btn'));
        var kppSubmissionModal = document.getElementById('kppSubmissionModal');
        var kppSubmissionCloseBtn = document.getElementById('kppSubmissionCloseBtn');
        var kppSubmissionMeta = document.getElementById('kppSubmissionMeta');
        var kppSubmissionContent = document.getElementById('kppSubmissionContent');
        var kppSubmissionsBox = document.getElementById('kpp-submissions');

        var appDetailModal = document.getElementById('appDetailModal');
        var appModalCloseBtn = document.getElementById('appModalCloseBtn');
        var modalReviewLink = document.getElementById('modalReviewLink');
        var modalAttachmentViewer = document.getElementById('modalAttachmentViewer');
        var userRoleClient = '<%= String.valueOf(session.getAttribute("role")) %>';
        var isAdminRoleClient = userRoleClient === 'ADMIN';

        var contextPath = '<%= request.getContextPath() %>';

        function keepKppPanelOnScreen() {
            try {
                sessionStorage.setItem('dashboardAnchor', 'kpp-submissions');
            } catch (error) {
                // Ignore storage errors and continue normal navigation.
            }
        }

        function restoreKppPanelOnScreen() {
            if (!kppSubmissionsBox) {
                return;
            }
            var shouldFocusByHash = window.location.hash === '#kpp-submissions';
            var shouldFocusByState = false;
            try {
                shouldFocusByState = sessionStorage.getItem('dashboardAnchor') === 'kpp-submissions';
                if (shouldFocusByState) {
                    sessionStorage.removeItem('dashboardAnchor');
                }
            } catch (error) {
                shouldFocusByState = false;
            }
            if (shouldFocusByHash || shouldFocusByState) {
                kppSubmissionsBox.scrollIntoView({ behavior: 'auto', block: 'start' });
            }
        }

        restoreKppPanelOnScreen();

        var kppForms = Array.prototype.slice.call(document.querySelectorAll('#kpp-submissions form'));
        kppForms.forEach(function (form) {
            form.addEventListener('submit', keepKppPanelOnScreen);
        });

        var kppLinks = Array.prototype.slice.call(document.querySelectorAll('#kpp-submissions a.kpp-action-btn'));
        kppLinks.forEach(function (link) {
            link.addEventListener('click', keepKppPanelOnScreen);
        });

        function statusForSelection(optionValue) {
            if (optionValue === 'xlsx_approved' || optionValue === 'pdf_approved') {
                return 'APPROVED';
            }
            if (optionValue === 'xlsx_rejected' || optionValue === 'pdf_rejected') {
                return 'REJECTED';
            }
            return statusSelect.value || '';
        }

        function formatForSelection(optionValue) {
            return optionValue.indexOf('pdf_') === 0 ? 'pdf' : 'xlsx';
        }

        function runExport() {
            var optionValue = exportOption.value;
            var format = formatForSelection(optionValue);
            var status = statusForSelection(optionValue);
            var q = searchInput.value || '';
            var dateFrom = dateFromInput ? (dateFromInput.value || '') : '';
            var dateTo = dateToInput ? (dateToInput.value || '') : '';
            var url = contextPath + '/admin/export?format=' + encodeURIComponent(format)
                + '&q=' + encodeURIComponent(q)
                + '&status=' + encodeURIComponent(status)
                + '&date_from=' + encodeURIComponent(dateFrom)
                + '&date_to=' + encodeURIComponent(dateTo);
            window.location.href = url;
        }

        function getKppActionLabel(actionType) {
            if (actionType === 'UJPPP') {
                return 'Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP)';
            }
            if (actionType === 'KSPP_UJPPP') {
                return 'Borang KSPP dan Borang UJPPP';
            }
            return 'Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP)';
        }

        function buildKppSubject(actionType) {
            return 'Tindakan KPP: ' + getKppActionLabel(actionType);
        }

        function buildKppBody(kppName, actionType, guestLink) {
            var actionLine = '';
            if (actionType === 'UJPPP') {
                actionLine = '1) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).';
            } else if (actionType === 'KSPP_UJPPP') {
                actionLine = '1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).\n'
                    + '2) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).';
            } else {
                actionLine = '1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).';
            }

            return 'Assalamualaikum dan salam sejahtera ' + kppName + ',\n\n'
                + 'Admin SPPA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.\n'
                + 'Tindakan diperlukan:\n'
                + actionLine + '\n\n'
                + 'Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:\n'
                + guestLink + '\n\n'
                + 'Terima kasih.';
        }

        function generateKppGuestLink(emailTo, actionType) {
            var url = contextPath + '/kpp/generate-link?recipient_email=' + encodeURIComponent(emailTo)
                + '&action_type=' + encodeURIComponent(actionType || 'KSPP');

            return fetch(url, {
                method: 'GET',
                credentials: 'same-origin',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            }).then(function(response) {
                if (!response.ok) {
                    throw new Error('HTTP ' + response.status);
                }
                return response.json();
            }).then(function(data) {
                if (!data || !data.link) {
                    throw new Error('Pautan khas tidak diterima.');
                }
                return data.link;
            });
        }

        function updateKppDraft() {
            if (!kppEmailSubject || !kppEmailBody) {
                return;
            }

            var kppName = kppRecipientName && kppRecipientName.value && kppRecipientName.value.trim()
                ? kppRecipientName.value.trim()
                : 'tuan/puan';
            var actionType = kppActionType ? (kppActionType.value || 'KSPP') : 'KSPP';
            kppEmailSubject.value = buildKppSubject(actionType);
            kppEmailBody.value = buildKppBody(kppName, actionType, '[Pautan khas akan dijana semasa Hantar Email]');
        }

        function setExpandState(button, expanded) {
            if (!button) {
                return;
            }
            button.setAttribute('aria-expanded', expanded ? 'true' : 'false');
            button.setAttribute('title', expanded ? 'Kecilkan panel' : 'Besarkan panel');
        }

        function showArchiveToast(message, iconUrl) {
            if (!archiveToast || !archiveToastText || !archiveToastIcon) {
                return;
            }
            archiveToastText.textContent = message;
            if (iconUrl) {
                archiveToastIcon.src = iconUrl;
            }
            archiveToast.classList.add('show');
            if (toastTimer) {
                clearTimeout(toastTimer);
            }
            toastTimer = setTimeout(function() {
                archiveToast.classList.remove('show');
            }, 2100);
        }

        function updateArchiveRowUi(form, actionValue) {
            if (!form) {
                return;
            }
            var row = form.closest('tr');
            if (!row) {
                return;
            }

            var statusCell = row.querySelector('.status-pill');
            var actionInput = form.querySelector('input[name="action"]');
            var button = form.querySelector('button.btn-archive');
            var icon = button ? button.querySelector('img') : null;

            if (actionValue === 'archive') {
                if (statusCell) {
                    statusCell.className = 'status-pill status-archived';
                    statusCell.textContent = 'ARCHIVED';
                }
                if (actionInput) {
                    actionInput.value = 'unarchive';
                }
                if (button) {
                    button.title = 'Buka Arkib';
                    button.setAttribute('aria-label', 'Buka Arkib');
                }
                if (icon) {
                    icon.src = contextPath + '/assets/images/icon-unarchive.png';
                }
                return;
            }

            // For unarchive, remove row from archived view (or fallback to reload if row cannot be removed safely)
            if (statusSelect && statusSelect.value === 'ARCHIVED') {
                row.remove();
                var remainingRows = toolbarForm ? document.querySelectorAll('tbody tr').length : 0;
                if (remainingRows === 0) {
                    window.location.reload();
                }
                return;
            }

            window.location.reload();
        }

        function closeExpandPopup() {
            if (latestPanel) {
                latestPanel.classList.remove('popup-active');
            }
            if (announcementPanelCard) {
                announcementPanelCard.classList.remove('popup-active');
            }
            document.body.classList.remove('popup-open');
            setExpandState(toggleLatestPanelBtn, false);
            setExpandState(toggleAnnouncementPanelBtn, false);
        }

        function closeKppSubmissionModal() {
            if (!kppSubmissionModal) {
                return;
            }
            kppSubmissionModal.classList.remove('show');
            kppSubmissionModal.setAttribute('aria-hidden', 'true');
            if (kppSubmissionContent) {
                kppSubmissionContent.innerHTML = '';
            }
        }

        function getValue(payload, key) {
            if (!payload || typeof payload !== 'object') {
                return '';
            }
            if (!Object.prototype.hasOwnProperty.call(payload, key)) {
                return '';
            }
            var value = payload[key];
            if (value === null || value === undefined) {
                return '';
            }
            return String(value);
        }

        function createFieldRow(label, value) {
            var row = document.createElement('div');
            row.className = 'kpp-modal-row';
            var isSyorField = String(label || '').indexOf('Syor (diterima/ditolak/digantung/dibatal)') === 0;
            if (isSyorField) {
                row.classList.add('kpp-modal-row-syor');
            }

            var title = document.createElement('b');
            title.textContent = label;

            var content = document.createElement('span');
            content.textContent = value && value.trim() ? value : '-';
            if (isSyorField) {
                var normalized = (value || '').toString().trim().toLowerCase();
                if (normalized === 'terima' || normalized === 'diterima') {
                    content.classList.add('kpp-syor-accepted');
                } else if (normalized === 'ditolak' || normalized === 'digantung' || normalized === 'dibatal') {
                    content.classList.add('kpp-syor-rejected');
                }
            }

            row.appendChild(title);
            row.appendChild(content);
            return row;
        }

        function createBorangTitle(text) {
            var div = document.createElement('div');
            div.className = 'kpp-modal-borang-title';
            div.textContent = text;
            return div;
        }

        function createSection(titleText, fields, options) {
            var section = document.createElement('div');
            section.className = 'kpp-modal-section';

            var title = document.createElement('h5');
            title.textContent = titleText;
            section.appendChild(title);

            var grid = document.createElement('div');
            grid.className = 'kpp-modal-fields';
            if (options && options.singleColumn) {
                grid.classList.add('kpp-single-column');
            }

            fields.forEach(function(item) {
                grid.appendChild(createFieldRow(item.label, item.value));
            });

            section.appendChild(grid);
            return section;
        }

        function buildRespondentSection(payload) {
            return createSection('Bahagian A: Maklumat Responden', [
                { label: 'Nama Penuh', value: getValue(payload, 'f_respondent_name') },
                { label: 'Cawangan / Jabatan Air Daerah', value: getValue(payload, 'f_respondent_branch') },
                { label: 'Jawatan Hakiki & Gred', value: getValue(payload, 'f_respondent_position_grade') },
                { label: 'Gelaran Jawatan', value: getValue(payload, 'f_respondent_title') },
                { label: 'No. Telefon', value: getValue(payload, 'f_phone') },
                { label: 'Emel Rasmi Kerajaan', value: getValue(payload, 'f_respondent_official_email') },
                { label: 'Tempoh Berkhidmat', value: getValue(payload, 'f_respondent_service_period') }
            ]);
        }

        var ksppQuestionLabels = [
            '1. Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?',
            '2. Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal/pemilik produk masih sah?',
            '3. Adakah dokumen jaminan produk masih sah?',
            '4. Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?',
            '5. Adakah mudah dihubungi pada bila-bila masa?',
            '6. Adakah jadual penghantaran produk ke lokasi dipatuhi?',
            '7. Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?',
            '8. Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?',
            '9. Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?',
            '10. Adakah amalan pelaksanaan kerja mengurangkan kesan/impak negatif terhadap alam sekitar dipatuhi?',
            '11. Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?',
            '12. Adakah pemasangan produk dieselia/dipantau sehingga selesai?',
            '13. Adakah pengujian dan pentauliahan produk diasakna sehingga selesai?',
            '14. Adakah produk yang rosak diganti ataupun dibaiki dengan segera?',
            '15. Adakah Manual Operasi diberikan?',
            '16. Adakah latihan operasi dan senggara produk diberikan?',
            '17. Adakah produk yang dibekalkan memenuhi spesifikasi yang dititikrafkan, berfungsi dengan baik dan tidak ada kecacatan?',
            '18. Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)',
            '19. Adakah produk mempunyai rekod prestasi yang tidak memuaskan/rosak dalam tempoh tanggungan kecacatan?',
            '20. Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan.'
        ];

        function buildKsppSections(payload) {
            var elements = [];

            elements.push(createBorangTitle('Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP)'));

            elements.push(createSection('Bahagian B: Maklumat Produk', [
                { label: 'Nama Produk', value: getValue(payload, 'f_kspp_product_name') },
                { label: 'Jenama', value: getValue(payload, 'f_kspp_brand') },
                { label: 'Perihal Produk (Model/Kelas/Saiz)', value: getValue(payload, 'f_kspp_product_desc') },
                { label: 'Tarikh Mula & Siap', value: getValue(payload, 'f_kspp_start_end_date') },
                { label: '% Siap', value: getValue(payload, 'f_kspp_completion_percent') }
            ]));

            elements.push(createSection('Bahagian C: Maklumat Pembekal dan Produk', [
                { label: 'Nama Pembekal', value: getValue(payload, 'f_kspp_supplier_name') },
                { label: 'Nama Produk', value: getValue(payload, 'f_kspp_supplier_product_name') },
                { label: 'Jenama', value: getValue(payload, 'f_kspp_supplier_brand') },
                { label: 'Perihal Produk (Model/Kelas/Saiz/dll)', value: getValue(payload, 'f_kspp_supplier_product_desc') }
            ]));

            var ksppChecks = [];
            for (var i = 1; i <= ksppQuestionLabels.length; i++) {
                ksppChecks.push({
                    label: ksppQuestionLabels[i - 1],
                    value: 'Jawapan: ' + (getValue(payload, 'f_kspp_q' + i) || '-') + '\nCatatan: ' + (getValue(payload, 'f_kspp_q' + i + '_note') || '-')
                });
            }
            elements.push(createSection(
                'Bahagian D: Prestasi Pembekal dan Produk',
                ksppChecks,
                { singleColumn: true }
            ));

            elements.push(createSection('Bahagian E: Ulasan Terhadap Pembaharuan Perakuan', [
                { label: 'Keputusan Ulasan', value: getValue(payload, 'f_kspp_review_decision') },
                { label: 'Tarikh', value: getValue(payload, 'f_kspp_review_date') },
                { label: 'Ulasan', value: getValue(payload, 'f_kspp_review_note') },
                { label: 'Nama', value: getValue(payload, 'f_kspp_sign_name') }
            ]));

            return elements;
        }

        function buildUjpppSections(payload) {
            var elements = [];
            elements.push(createBorangTitle('Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP)'));
            elements.push(createSection('Bahagian A: Maklumat Pembekal / Pembuat / Prinsipal', [
                { label: 'Jenis Permohonan (Baharu / Pembaharuan)', value: getValue(payload, 'f_ujppp_application_type') },
                { label: 'Nama Syarikat Pembekal, Alamat Pejabat & No. Telefon', value: getValue(payload, 'f_ujppp_supplier_company_info') },
                { label: 'Nama Syarikat Pembuat / Pengilang, Alamat Pejabat & No. Telefon', value: getValue(payload, 'f_ujppp_manufacturer_company_info') },
                { label: 'Nama Syarikat Prinsipal / Pemilik Produk, Alamat Pejabat & No. Telefon', value: getValue(payload, 'f_ujppp_principal_company_info') }
            ]));
            elements.push(createSection('Bahagian B: Maklumat Produk', [
                { label: 'Kategori', value: getValue(payload, 'f_ujppp_category') },
                { label: 'Nama Produk', value: getValue(payload, 'f_ujppp_product_name') },
                { label: 'Jenama', value: getValue(payload, 'f_ujppp_brand') },
                { label: 'Piawaian / Standard', value: getValue(payload, 'f_ujppp_standard') },
                { label: 'Badan Persijilan & No. Lesen Persijilan Barangan (Sah sehingga)', value: getValue(payload, 'f_ujppp_certification_body') },
                { label: 'Badan Persijilan & No. Laporan Pengujian (Tarikh dikeluarkan)', value: getValue(payload, 'f_ujppp_test_report') },
                { label: 'Perihal Produk (Model / Siri / Deskripsi)', value: getValue(payload, 'f_ujppp_product_desc') },
                { label: 'Tempoh Jaminan Produk (Tahun)', value: getValue(payload, 'f_ujppp_warranty_year') }
            ]));
            elements.push(createSection('Bahagian C: Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Selaku Pengguna Produk', [
                { label: 'Tarikh', value: getValue(payload, 'f_ujppp_review_date') },
                { label: 'Syor (diterima/ditolak/digantung/dibatal)', value: getValue(payload, 'f_ujppp_review_recommendation') }
            ]));
            return elements;
        }

        function openKppSubmissionModal(button) {
            if (!kppSubmissionModal || !kppSubmissionMeta || !kppSubmissionContent || !button) {
                return;
            }

            var kpp = button.getAttribute('data-kpp') || 'KPP';
            var form = button.getAttribute('data-form') || 'Borang';
            var actionType = button.getAttribute('data-action') || '';
            var submitted = button.getAttribute('data-submitted') || '-';
            var payloadText = button.getAttribute('data-payload') || '';

            kppSubmissionMeta.textContent = kpp + ' - ' + form + ' | Tarikh Hantar: ' + submitted;
            kppSubmissionContent.innerHTML = '';

            var parsed = null;
            try {
                parsed = JSON.parse(payloadText);
            } catch (error) {
                parsed = null;
            }

            if (!parsed || typeof parsed !== 'object') {
                var fallback = document.createElement('div');
                fallback.className = 'kpp-modal-section';
                fallback.innerHTML = '<h5>Maklumat</h5><div class="kpp-modal-fields"><div class="kpp-modal-row"><b>Data</b><span>Format data borang tidak dapat dibaca.</span></div></div>';
                kppSubmissionContent.appendChild(fallback);
            } else {
                kppSubmissionContent.appendChild(buildRespondentSection(parsed));

                var normalizedAction = String(actionType || '').toUpperCase();
                if (normalizedAction === 'KSPP' || normalizedAction === 'KSPP_UJPPP') {
                    buildKsppSections(parsed).forEach(function(el) {
                        kppSubmissionContent.appendChild(el);
                    });
                }
                if (normalizedAction === 'UJPPP' || normalizedAction === 'KSPP_UJPPP') {
                    buildUjpppSections(parsed).forEach(function(el) {
                        kppSubmissionContent.appendChild(el);
                    });
                }
            }

            kppSubmissionModal.classList.add('show');
            kppSubmissionModal.setAttribute('aria-hidden', 'false');
        }

        function openExpandPopup(panelElement) {
            if (!panelElement) {
                return;
            }
            if (latestPanel && panelElement !== latestPanel) {
                latestPanel.classList.remove('popup-active');
            }
            if (announcementPanelCard && panelElement !== announcementPanelCard) {
                announcementPanelCard.classList.remove('popup-active');
            }

            panelElement.classList.add('popup-active');
            document.body.classList.add('popup-open');
            setExpandState(toggleLatestPanelBtn, panelElement === latestPanel);
            setExpandState(toggleAnnouncementPanelBtn, panelElement === announcementPanelCard);
        }

        if (toggleLatestPanelBtn && layoutGrid && latestPanel) {
            setExpandState(toggleLatestPanelBtn, false);
            toggleLatestPanelBtn.addEventListener('click', function() {
                var isOpen = latestPanel.classList.contains('popup-active') && document.body.classList.contains('popup-open');
                if (isOpen) {
                    closeExpandPopup();
                    return;
                }
                openExpandPopup(latestPanel);
            });
        }

        if (toggleAnnouncementPanelBtn && layoutGrid && announcementPanelCard) {
            setExpandState(toggleAnnouncementPanelBtn, false);
            toggleAnnouncementPanelBtn.addEventListener('click', function() {
                var isOpen = announcementPanelCard.classList.contains('popup-active') && document.body.classList.contains('popup-open');
                if (isOpen) {
                    closeExpandPopup();
                    return;
                }
                openExpandPopup(announcementPanelCard);
            });
        }

        if (expandOverlay) {
            expandOverlay.addEventListener('click', function() {
                closeExpandPopup();
            });
        }

        if (kppSubmissionCloseBtn) {
            kppSubmissionCloseBtn.addEventListener('click', function() {
                closeKppSubmissionModal();
            });
        }

        if (kppSubmissionModal) {
            kppSubmissionModal.addEventListener('click', function(event) {
                if (event.target === kppSubmissionModal) {
                    closeKppSubmissionModal();
                }
            });
        }

        kppViewButtons.forEach(function(button) {
            button.addEventListener('click', function() {
                openKppSubmissionModal(button);
            });
        });

        document.addEventListener('click', function (event) {
            var archiveBtn = event.target.closest('.js-archive-btn');
            if (!archiveBtn) {
                return;
            }

            doArchive(
                archiveBtn.dataset.appId || '',
                archiveBtn.dataset.action || '',
                archiveBtn.dataset.confirm || 'Teruskan?',
                archiveBtn.dataset.csrf || '',
                archiveBtn.dataset.ctx || ''
            );
        });

        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape' && document.body.classList.contains('popup-open')) {
                closeExpandPopup();
                return;
            }
            if (event.key === 'Escape' && kppSubmissionModal && kppSubmissionModal.classList.contains('show')) {
                closeKppSubmissionModal();
            }
        });

        if (exportButton) {
            exportButton.addEventListener('click', function(e) {
                e.preventDefault();
                runExport();
            });
        }

        if (quickExportButton) {
            quickExportButton.addEventListener('click', function(e) {
                e.preventDefault();
                runExport();
            });
        }

        if (kppRecipientName) {
            kppRecipientName.addEventListener('input', function() {
                updateKppDraft();
            });
        }

        if (kppActionType) {
            kppActionType.addEventListener('change', function() {
                updateKppDraft();
            });
        }

        updateKppDraft();

        if (kppEmailSendBtn) {
            kppEmailSendBtn.addEventListener('click', function() {
                var to = kppEmailTo ? (kppEmailTo.value || '').trim() : '';
                var actionType = kppActionType ? (kppActionType.value || 'KSPP') : 'KSPP';

                if (!to) {
                    alert('Sila isi emel penerima dahulu.');
                    return;
                }

                var kppName = kppRecipientName && kppRecipientName.value && kppRecipientName.value.trim()
                    ? kppRecipientName.value.trim()
                    : 'tuan/puan';

                var previousLabel = kppEmailSendBtn.textContent;
                kppEmailSendBtn.disabled = true;
                kppEmailSendBtn.textContent = 'Menjana Pautan...';

                generateKppGuestLink(to, actionType)
                    .then(function(guestLink) {
                        var subject = buildKppSubject(actionType);
                        var body = buildKppBody(kppName, actionType, guestLink);

                        if (kppEmailSubject) {
                            kppEmailSubject.value = subject;
                        }
                        if (kppEmailBody) {
                            kppEmailBody.value = body;
                        }

                        var mailtoUrl = 'mailto:' + encodeURIComponent(to)
                            + '?subject=' + encodeURIComponent(subject)
                            + '&body=' + encodeURIComponent(body);
                        window.location.href = mailtoUrl;
                    })
                    .catch(function(error) {
                        alert('Gagal jana pautan khas. Sila cuba lagi. ' + (error && error.message ? error.message : ''));
                    })
                    .finally(function() {
                        kppEmailSendBtn.disabled = false;
                        kppEmailSendBtn.textContent = previousLabel;
                    });
            });
        }
    })();

    function doArchive(appId, actionValue, confirmText, csrfToken, ctxPath) {
        if (!window.confirm(confirmText)) { return; }
        var body = 'id=' + encodeURIComponent(appId) +
                   '&action=' + encodeURIComponent(actionValue) +
                   '&ajax=1' +
                   '&_csrf=' + encodeURIComponent(csrfToken);
        fetch(ctxPath + '/admin/application', {
            method: 'POST',
            credentials: 'same-origin',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-Token': csrfToken
            },
            body: body
        }).then(function(resp) {
            if (resp.ok) {
                window.location.reload();
            } else {
                resp.text().then(function(t) { alert('Gagal: ' + resp.status + ' ' + t.substring(0, 200)); });
            }
        }).catch(function(err) { alert('Ralat rangkaian: ' + err); });
    }
</script>
</body>
</html>
