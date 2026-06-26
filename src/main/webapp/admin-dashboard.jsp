<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.nio.file.Paths" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.LinkedHashMap" %>
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

    private List<String> parseCsvLine(String line) {
        List<String> columns = new ArrayList<>();
        if (line == null) {
            return columns;
        }

        StringBuilder current = new StringBuilder();
        boolean insideQuotes = false;
        for (int i = 0; i < line.length(); i++) {
            char ch = line.charAt(i);
            if (ch == '"') {
                insideQuotes = !insideQuotes;
                continue;
            }
            if (ch == ',' && !insideQuotes) {
                columns.add(current.toString().trim());
                current.setLength(0);
                continue;
            }
            current.append(ch);
        }
        columns.add(current.toString().trim());
        return columns;
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
        if ("SUSPENDED".equals(normalized) || "DIGANTUNG".equals(normalized)) {
            return "DIGANTUNG";
        }
        if ("DRAFT".equals(normalized) || "DRAF".equals(normalized)) {
            return "NEW";
        }
        if ("ARCHIVED".equals(normalized) || "DIARKIB".equals(normalized)) {
            return "DIARKIB";
        }
        if ("UNDER_REVIEW".equals(normalized) || "DALAM_SEMAKAN".equals(normalized) || "DALAM SEMAKAN".equals(normalized)) {
            return "DALAM SEMAKAN";
        }
        if ("IN_PROGRESS".equals(normalized) || "DALAM_PROSES".equals(normalized) || "DALAM PROSES".equals(normalized)) {
            return "DALAM PROSES";
        }
        return status;
    }
%>
<!DOCTYPE html>
<html lang="ms">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1">
    <title>Dashboard Pentadbir - SPPPA</title>
    <style>
/*A��─ Design tokensA��──────────────────────────── */
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
        body { margin: 0; font-family: inherit; background: linear-gradient(180deg, #f4fbff 0%, #f9fcfd 100%); color: var(--text); }
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
        .stats .stat-card:nth-child(6) { background: #eadcff; border-color: #cdb0f5; }
        .stats .stat-card:nth-child(6) h3, .stats .stat-card:nth-child(6) .number { color: #5b2491; }
        .layout { display: grid; grid-template-columns: 1.9fr 1fr; gap: 20px; }
        .toolbar { display: grid; grid-template-columns: minmax(220px, 1.6fr) repeat(3, minmax(140px, 1fr)); gap: 12px; align-items: end; margin-bottom: 16px; }
        .status-filter-compact .status-filter-controls {
            display: flex;
            align-items: center;
            gap: 0;
        }
        .status-filter-compact .status-filter-controls select {
            flex: 1 1 auto;
            min-width: 0;
        }
        .btn-archive-main {
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            white-space: nowrap;
            width: 40px;
            height: 40px;
            padding: 0;
            position: relative;
        }
        .archive-hover-label {
            display: none;
            position: absolute;
            top: calc(100% + 8px);
            right: 0;
            background: #163b56;
            color: #fff;
            font-size: 12px;
            font-weight: 700;
            line-height: 1;
            padding: 7px 10px;
            border-radius: 999px;
            white-space: nowrap;
            box-shadow: 0 10px 20px rgba(9, 36, 56, 0.24);
            z-index: 40;
            pointer-events: none;
        }
        .btn-archive-main:hover .archive-hover-label,
        .btn-archive-main:focus-visible .archive-hover-label {
            display: inline-flex;
        }
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
        .smtp-settings-panel { border-top: 4px solid #0f6bae; margin-bottom: 18px; }
        .smtp-form { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px 12px; }
        .smtp-form .smtp-span-2 { grid-column: span 2; }
        .smtp-form label { display: block; margin-bottom: 6px; font-size: 13px; font-weight: 700; color: var(--muted); }
        .smtp-form input, .smtp-form select {
            width: 100%;
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 10px 12px;
            font: inherit;
            font-size: 13px;
            background: var(--surface-soft);
        }
        .smtp-form-help { margin-top: 4px; font-size: 12px; color: #5c7485; }
        .smtp-form-actions { display: flex; gap: 8px; align-items: center; }
        .smtp-form-note { font-size: 12px; color: #6f8595; }
        @media (max-width: 860px) {
            .smtp-form { grid-template-columns: 1fr; }
            .smtp-form .smtp-span-2 { grid-column: span 1; }
        }
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
        .status-resolved { background: #dcfce7; color: #166534; }
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
        .sent-popup {
            position: fixed;
            inset: 0;
            background: rgba(6, 25, 40, 0.45);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1600;
            padding: 16px;
        }
        .sent-popup.show {
            display: flex;
        }
        .sent-popup-card {
            width: min(360px, 100%);
            background: #ffffff;
            border: 1px solid #d8e5ef;
            border-radius: 16px;
            box-shadow: 0 24px 54px rgba(3, 30, 54, 0.28);
            padding: 20px 18px 16px;
            text-align: center;
        }
        .sent-popup-icon {
            width: 78px;
            height: 78px;
            object-fit: contain;
            display: block;
            margin: 0 auto 10px;
        }
        .sent-popup-title {
            margin: 0;
            font-size: 22px;
            font-weight: 800;
            color: #0f3f61;
        }
        .sent-popup-ok {
            min-width: 130px;
            border: none;
            border-radius: 10px;
            background: #0a7fbf;
            color: #fff;
            font-weight: 700;
            font-size: 14px;
            padding: 10px 14px;
            cursor: pointer;
        }
        .sent-popup-ok:hover {
            background: #086da5;
        }
        .maintenance-popup {
            position: fixed;
            inset: 0;
            background: rgba(6, 25, 40, 0.45);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1650;
            padding: 16px;
        }
        .maintenance-popup.show {
            display: flex;
        }
        .maintenance-popup-card {
            width: min(400px, 100%);
            background: #ffffff;
            border: 1px solid #d8e5ef;
            border-radius: 16px;
            box-shadow: 0 24px 54px rgba(3, 30, 54, 0.28);
            padding: 20px 18px 16px;
            text-align: center;
        }
        .maintenance-popup-icon {
            width: 84px;
            height: 84px;
            object-fit: contain;
            display: block;
            margin: 0 auto 10px;
        }
        .maintenance-popup-title {
            margin: 0;
            font-size: 22px;
            font-weight: 800;
            color: #0f3f61;
        }
        .maintenance-popup-text {
            margin: 8px 0 14px;
            color: #3f6278;
            font-size: 14px;
        }
        .maintenance-popup-actions {
            display: flex;
            gap: 8px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .maintenance-popup-btn {
            min-width: 120px;
            border: none;
            border-radius: 10px;
            font-weight: 700;
            font-size: 14px;
            padding: 10px 14px;
            cursor: pointer;
        }
        .maintenance-popup-btn-confirm {
            background: #0a7fbf;
            color: #fff;
        }
        .maintenance-popup-btn-confirm:hover {
            background: #086da5;
        }
        .maintenance-popup-btn-cancel {
            background: #e8f1f8;
            color: #24506e;
        }
        .maintenance-popup-btn-cancel:hover {
            background: #d8e7f3;
        }
        .aduan-password-popup {
            position: fixed;
            inset: 0;
            background: rgba(6, 25, 40, 0.52);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1680;
            padding: 16px;
        }
        .aduan-password-popup.show {
            display: flex;
        }
        .aduan-password-popup-card {
            width: min(420px, 100%);
            background: #ffffff;
            border: 1px solid #d8e5ef;
            border-radius: 16px;
            box-shadow: 0 24px 54px rgba(3, 30, 54, 0.28);
            padding: 20px 18px 16px;
            text-align: center;
        }
        .aduan-password-popup-icon {
            width: 84px;
            height: 84px;
            object-fit: contain;
            display: block;
            margin: 0 auto 10px;
        }
        .aduan-password-popup-title {
            margin: 0;
            font-size: 21px;
            font-weight: 800;
            color: #0f3f61;
        }
        .aduan-password-popup-text {
            margin: 8px 0 12px;
            color: #3f6278;
            font-size: 14px;
        }
        .aduan-password-popup-input {
            width: 100%;
            border: 1px solid #cfe1ee;
            border-radius: 10px;
            background: #f9fcff;
            color: #214e69;
            padding: 10px 12px;
            font: inherit;
            font-size: 14px;
            margin-bottom: 12px;
        }
        .aduan-password-popup-actions {
            display: flex;
            gap: 8px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .aduan-password-popup-btn {
            min-width: 120px;
            border: none;
            border-radius: 10px;
            font-weight: 700;
            font-size: 14px;
            padding: 10px 14px;
            cursor: pointer;
        }
        .aduan-password-popup-btn-confirm {
            background: #0a7fbf;
            color: #fff;
        }
        .aduan-password-popup-btn-confirm:hover {
            background: #086da5;
        }
        .aduan-password-popup-btn-cancel {
            background: #e8f1f8;
            color: #24506e;
        }
        .aduan-password-popup-btn-cancel:hover {
            background: #d8e7f3;
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
        .quick-actions-sidebar {
            position: fixed;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            z-index: 1100;
            display: grid;
            gap: 10px;
        }
        .quick-actions {
            display: grid;
            gap: 10px;
            justify-items: start;
        }
        .quick-actions .btn {
            width: 50px;
            height: 50px;
            padding: 0;
            border-radius: 999px;
            box-shadow: 0 10px 24px rgba(6, 52, 79, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.9);
            flex: 0 0 auto;
            transition: transform 0.2s ease, box-shadow 0.2s ease, filter 0.2s ease;
            transform-origin: center;
            will-change: transform;
        }
        .quick-actions .btn:hover,
        .quick-actions .btn:focus-visible {
            transform: translateY(-2px) scale(1.12);
            box-shadow: 0 16px 28px rgba(6, 52, 79, 0.28);
            filter: saturate(1.05);
        }
        .quick-actions .btn:active {
            transform: translateY(0) scale(1.04);
        }
        .quick-action-icon { width: 22px; height: 22px; object-fit: contain; }
        .quick-btn-blue { background: #d9ecff; color: #0f4f8f; border-color: #afd3f8; }
        .quick-btn-green { background: #d9f7df; color: #125c2b; border-color: #aee5bb; }
        .quick-btn-white { background: #ffffff; color: #1f2937; border-color: #d7dee8; }
        .quick-btn-pink { background: #ffd9e8; color: #7b1f49; border-color: #f6b6d1; }
        .quick-btn-yellow { background: #fff3a3; color: #6a5700; border-color: #f7df6b; }
        .quick-btn-purple { background: #eadcff; color: #5b2491; border-color: #cdb0f5; }
        .quick-btn-red { background: #ffd9d9; color: #8f1d1d; border-color: #f0a9a9; }
        .quick-btn-brown { background: #ead7c4; color: #6f4a2a; border-color: #cfb08f; }
        .quick-btn-aduan { background: #ef4444; color: #ffffff; border-color: #d02f2f; }
        .quick-btn-aduan.is-locked { background: #f9c7c7; color: #8f1d1d; border-color: #eaa3a3; }
        .quick-btn-aduan.has-unread { position: relative; overflow: visible; }
        .quick-btn-aduan .unread-dot {
            position: absolute;
            top: -2px;
            right: -2px;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #ff1b1b;
            border: 2px solid #ffffff;
            box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.12);
        }
        .staff-complaint-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }
        .staff-complaint-item { border: 1px solid #dbe7ef; border-radius: 12px; background: #f9fcff; padding: 10px; }
        .staff-complaint-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; }
        .staff-complaint-title { margin: 0; color: #0d4f80; font-size: 14px; }
        .staff-complaint-meta { margin-top: 4px; color: #577082; font-size: 12px; line-height: 1.45; }
        .staff-complaint-actions { margin-top: 8px; display: flex; gap: 6px; flex-wrap: wrap; }
        .staff-complaint-actions form { margin: 0; }
        .staff-complaint-actions .btn { padding: 7px 10px; border-radius: 8px; font-size: 12px; }
        .staff-complaint-empty { color: #637d8d; font-size: 13px; margin: 0; }
        .staff-new-count { display: inline-flex; align-items: center; justify-content: center; min-width: 24px; height: 24px; border-radius: 999px; padding: 0 7px; background: #ffe4e4; color: #b91c1c; font-size: 12px; font-weight: 800; }
        .quick-actions form { margin: 0; }
        .quick-actions form .btn {
            cursor: pointer;
            background: #eadcff;
            color: #5b2491;
            border-color: #cdb0f5;
        }
        .quick-actions form .btn.quick-btn-maintenance-on {
            background: #d7bcff;
            color: #4a167f;
            border-color: #b590ef;
        }
        .notification-list, .activity-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }
        .notification-item, .activity-item { border: 1px solid var(--line); border-radius: 12px; padding: 10px; background: #f9fcff; }
        .notification-item strong, .activity-item strong { display: block; margin-bottom: 4px; font-size: 13px; color: #0d4f80; }
        .notification-item span, .activity-item span { color: #577082; font-size: 12px; }
        .audit-content {
            max-height: 420px;
            display: flex;
            flex-direction: column;
            min-height: 0;
        }
        .audit-list {
            list-style: none;
            margin: 0;
            padding: 0 4px 0 0;
            display: grid;
            gap: 8px;
            overflow-y: auto;
            min-height: 0;
            scrollbar-gutter: stable;
        }
        .audit-item { border: 1px solid #dbe7ef; border-radius: 10px; background: #fbfdff; padding: 10px; }
        .audit-item strong { display: block; color: #123f5a; font-size: 12px; margin-bottom: 3px; }
        .audit-item p { margin: 0; color: #486375; font-size: 12px; line-height: 1.4; }
        .audit-meta { display: flex; justify-content: space-between; gap: 10px; margin-top: 6px; color: #6d8595; font-size: 11px; }
        .audit-panel-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 8px; }
        .audit-toggle-btn { width: 34px; height: 34px; border: 1px solid #c9dcea; border-radius: 8px; background: #f7fbff; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; padding: 0; }
        .audit-toggle-btn img { width: 18px; height: 18px; object-fit: contain; }
        .audit-filter-bar { display: grid; grid-template-columns: 1fr; gap: 8px; margin-bottom: 10px; }
        .audit-filter-bar input {
            width: 100%;
            border: 1px solid #cfe1ee;
            border-radius: 10px;
            background: #f9fcff;
            color: #214e69;
            padding: 8px 10px;
            font-size: 12px;
        }
        .audit-filter-empty {
            margin-top: 8px;
            border: 1px dashed #c9dcea;
            border-radius: 10px;
            padding: 8px 10px;
            background: #f8fbfe;
            color: #5f7a8c;
            font-size: 12px;
            text-align: center;
        }
        .audit-content.is-hidden { display: none; }
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
        .jans-contact-section h3 { margin: 0 0 10px; color: #0f6bae; font-size: 16px; font-weight: 700; letter-spacing: 0; display: inline-flex; align-items: center; gap: 8px; }
        .contact-line { display: flex; gap: 8px; align-items: flex-start; margin: 7px 0; color: #4e6a7c; font-size: 13px; line-height: 1.45; }
        .contact-icon { width: 13px; height: 13px; object-fit: contain; flex-shrink: 0; margin-top: 2px; }
        .jans-contact-section .contact-line span { line-height: 1.45; }
        .contact-line-hanging { margin-left: 21px; }
        .contact-address-link { color: #0f6bae; text-decoration: none; }
        .contact-address-link:hover { text-decoration: underline; }
        body.popup-open {
            overflow: hidden;
        }
        body.popup-open .expand-overlay {
            display: block;
            background: rgba(4, 23, 39, 0.52);
            backdrop-filter: blur(1.5px);
        }
        body.popup-open .table-card.popup-active,
        body.popup-open #announcementPanel.popup-active {
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            width: min(1220px, calc(100vw - 34px));
            max-height: calc(100vh - 40px);
            overflow: auto;
            z-index: 1101;
            margin: 0;
            box-shadow: 0 26px 52px rgba(3, 22, 38, 0.35);
            border-radius: 16px;
        }

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
            .quick-actions-sidebar {
                left: auto;
                right: 10px;
                top: auto;
                bottom: 14px;
                transform: none;
            }
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
            .audit-content { max-height: 340px; }
        }

        /*A��─ MiscA��───────────────────────────────────── */
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
        .kpp-inline-help {
            margin-top: 6px;
            font-size: 12px;
            color: #5e798b;
        }
        .kpp-draft label {
            font-size: 12px;
            font-weight: 700;
            color: #5b7485;
        }
        .kpp-draft input,
        .kpp-draft select,
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
        .kpp-picker {
            position: relative;
        }
        .kpp-picker-btn {
            width: 100%;
            border: 1px solid #d4e4ef;
            border-radius: 10px;
            background: #f9fcff;
            padding: 9px 10px;
            font: inherit;
            font-size: 13px;
            color: #28475c;
            text-align: left;
            cursor: pointer;
        }
        .kpp-picker-btn:after {
            content: '▾';
            float: right;
            color: #4f6f83;
            font-size: 12px;
            line-height: 1.6;
        }
        .kpp-picker.open .kpp-picker-btn:after {
            content: '▴';
        }
        .kpp-picker-menu {
            display: none;
            position: absolute;
            top: calc(100% + 6px);
            left: 0;
            right: 0;
            z-index: 30;
            border: 1px solid #d4e4ef;
            border-radius: 10px;
            background: #ffffff;
            box-shadow: 0 12px 28px rgba(8, 49, 74, 0.14);
            max-height: 260px;
            overflow: auto;
            padding: 8px;
        }
        .kpp-picker.open .kpp-picker-menu {
            display: block;
        }
        .kpp-picker-item {
            display: flex;
            gap: 8px;
            align-items: flex-start;
            padding: 6px 6px;
            border-radius: 8px;
            cursor: pointer;
        }
        .kpp-picker-item:hover {
            background: #f2f8fd;
        }
        .kpp-picker-item input {
            width: auto;
            margin-top: 2px;
        }
        .kpp-picker-item span {
            color: #28475c;
            font-size: 12px;
            line-height: 1.4;
        }
        .kpp-picker-item[data-admin="true"] strong {
            color: #dc3545;
            font-weight: 700;
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
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 10px;
            flex-wrap: wrap;
        }
        .kpp-submission-main {
            flex: 1 1 270px;
            min-width: 220px;
        }
        .kpp-submission-status {
            flex: 0 0 auto;
            min-width: 180px;
            display: flex;
            justify-content: flex-end;
        }
        .kpp-status-badge-stack {
            display: grid;
            gap: 6px;
            justify-items: end;
        }
        .kpp-status-badge {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            padding: 4px 9px;
            font-size: 11px;
            font-weight: 700;
            line-height: 1.3;
            border: 1px solid #d4e4ef;
            background: #eef5fb;
            color: #355367;
            white-space: nowrap;
        }
        .kpp-status-good {
            background: #dff6e8;
            color: #196f40;
            border-color: #b7e3c8;
        }
        .kpp-status-bad {
            background: #ffe6e8;
            color: #9b1d2a;
            border-color: #f6c1c8;
        }
        .kpp-status-warn {
            background: #fff3d8;
            color: #8a5a00;
            border-color: #f0d5a2;
        }
        .kpp-status-neutral {
            background: #eef2f6;
            color: #4b6070;
            border-color: #d3dce3;
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
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 1099;
            display: none;
        }
        .panel-expand-btn[aria-expanded="true"] img { transform: rotate(180deg); }
        .panel-expand-btn img { transition: transform var(--tr); }
        </style>
</head>
<body>
    <%
        boolean maintenanceMode = Boolean.TRUE.equals(application.getAttribute("maintenanceMode"));
        String maintenanceConfirmText = maintenanceMode
            ? "Nyahaktifkan mod penyelenggaraan dan teruskan sistem?"
            : "Aktifkan mod penyelenggaraan sekarang?";
        String maintenanceButtonText = maintenanceMode
            ? "Nyahaktifkan mod Penyelenggaraan"
            : "Aktifkan mod Penyelenggaraan";
        String currentAdminDisplayId = request.getAttribute("current_admin_display_id") == null
            ? "-"
            : String.valueOf(request.getAttribute("current_admin_display_id"));
        String currentAdminUsername = session.getAttribute("username") == null ? "admin" : String.valueOf(session.getAttribute("username"));
        String aduanPasswordPromptLabel = currentAdminUsername + " (" + currentAdminDisplayId + ")";
        boolean canAccessSecureAduan = "ADMIN".equals(String.valueOf(session.getAttribute("role"))) && "ADM001".equals(currentAdminDisplayId);
        int staffComplaintNewCount = request.getAttribute("staff_complaint_new_count") instanceof Number
            ? ((Number) request.getAttribute("staff_complaint_new_count")).intValue() : 0;
    %>
    <div class="quick-actions-sidebar" aria-label="Tindakan Pantas">
        <div class="quick-actions">
            <a class="btn quick-btn-blue" href="#kpp-submissions" title="Tindakan Ketua Penolong Pengarah" aria-label="Tindakan Ketua Penolong Pengarah"><img src="${pageContext.request.contextPath}/icon/kpp.png" class="quick-action-icon" alt="Tindakan Ketua Penolong Pengarah"></a>
            <a class="btn quick-btn-green" href="${pageContext.request.contextPath}/products" title="Senarai Produk" aria-label="Senarai Produk"><img src="${pageContext.request.contextPath}/icon/senarai-produk.png" class="quick-action-icon" alt="Senarai Produk"></a>
            <a class="btn quick-btn-white" href="${pageContext.request.contextPath}/admin/users" title="Urus Pengguna" aria-label="Urus Pengguna"><img src="${pageContext.request.contextPath}/icon/urus-pengguna.png" class="quick-action-icon" alt="Urus Pengguna"></a>
            <a class="btn quick-btn-pink" href="#announcementPanel" title="Tambah Pengumuman" aria-label="Tambah Pengumuman"><img src="${pageContext.request.contextPath}/icon/tambah-pengumuman.png" class="quick-action-icon" alt="Tambah Pengumuman"></a>
            <a class="btn quick-btn-yellow" href="${pageContext.request.contextPath}/profile" title="Kemaskini Profil" aria-label="Kemaskini Profil"><img src="${pageContext.request.contextPath}/icon/kemaskini-profile.png" class="quick-action-icon" alt="Kemaskini Profil"></a>
            <form id="maintenanceActionForm" method="post" action="${pageContext.request.contextPath}/dashboard">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="maintenance_action" value="<%= maintenanceMode ? "disable" : "enable" %>">
                <button
                    id="maintenanceActionBtn"
                    class="btn quick-btn-purple <%= maintenanceMode ? "quick-btn-maintenance-on" : "quick-btn-maintenance-off" %>"
                    type="button"
                    title="<%= maintenanceButtonText %>"
                    aria-label="<%= maintenanceButtonText %>"
                    data-maintenance-confirm="<%= maintenanceConfirmText %>">
                    <img src="${pageContext.request.contextPath}/icon/penyelenggaraan.png" class="quick-action-icon" alt="Penyelenggaraan">
                </button>
            </form>
            <a class="btn quick-btn-red" href="${pageContext.request.contextPath}/admin-portal-guide.html" title="Panduan Admin Portal" aria-label="Panduan Admin Portal" target="_blank" rel="noopener"><img src="${pageContext.request.contextPath}/icon/panduan.png" class="quick-action-icon" alt="Panduan Admin Portal"></a>
            <a class="btn quick-btn-brown" href="${pageContext.request.contextPath}/dashboard?status=DIARKIB" title="Lihat Arkib" aria-label="Lihat Arkib"><img src="${pageContext.request.contextPath}/icon/lihat-arkib.png" class="quick-action-icon" alt="Lihat Arkib"></a>
            <form id="aduanSecureForm" method="post" action="${pageContext.request.contextPath}/dashboard">
                <input type="hidden" name="_csrf" value="${csrf_token}">
                <input type="hidden" name="secure_action" value="access_aduan">
                <input type="hidden" name="secure_password" id="aduanSecurePassword">
                <button
                    id="aduanSecureBtn"
                    class="btn quick-btn-aduan<%= canAccessSecureAduan ? "" : " is-locked" %><%= staffComplaintNewCount > 0 ? " has-unread" : "" %>"
                    type="button"
                    title="Aduan"
                    aria-label="Aduan"
                    data-allowed="<%= canAccessSecureAduan ? "1" : "0" %>">
                    <img src="${pageContext.request.contextPath}/icon/Aduan.png" class="quick-action-icon" alt="Aduan">
                    <% if (staffComplaintNewCount > 0) { %><span class="unread-dot" aria-hidden="true"></span><% } %>
                </button>
            </form>
        </div>
    </div>

    <div class="navbar">
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/images/logo-jabatan-air-sabah.png?v=4" class="brand-logo" alt="Logo Jabatan Air Sabah">
            <div>
                <h1>Dashboard Pentadbir</h1>
                <p>Pusat kawalan permohonan, produk, dan laporan SPPPA</p>
            </div>
        </div>
        <div>
            <span>Selamat datang, <%= session.getAttribute("username") %></span>
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
            List<Map<String, Object>> adminAuditLogs = (List<Map<String, Object>>) request.getAttribute("admin_audit_logs");
            List<Map<String, Object>> kppContacts = (List<Map<String, Object>>) request.getAttribute("kpp_contacts");
            boolean isAdminRole = "ADMIN".equals(String.valueOf(session.getAttribute("role")));
            List<Map<String, String>> kppRecipients = new ArrayList<>();

            if (kppContacts != null && !kppContacts.isEmpty()) {
                for (Map<String, Object> contact : kppContacts) {
                    String name = contact.get("name") == null ? "" : String.valueOf(contact.get("name")).trim();
                    String branch = contact.get("branch") == null ? "" : String.valueOf(contact.get("branch")).trim();
                    String email = contact.get("email") == null ? "" : String.valueOf(contact.get("email")).trim();
                    if (name.isEmpty() || email.isEmpty()) {
                        continue;
                    }

                    Map<String, String> entry = new LinkedHashMap<>();
                    entry.put("name", name);
                    entry.put("jawatan", branch);
                    entry.put("email", email);
                    kppRecipients.add(entry);
                }
            }

            if (kppRecipients.isEmpty()) {
                List<Path> csvCandidates = new ArrayList<>();
                String csvFromWebRoot = application.getRealPath("/data/Senarai KPP.csv");
                if (csvFromWebRoot != null && !csvFromWebRoot.isBlank()) {
                    csvCandidates.add(Paths.get(csvFromWebRoot));
                }
                csvCandidates.add(Paths.get(System.getProperty("user.dir"), "data", "Senarai KPP.csv"));
                csvCandidates.add(Paths.get("P:/ProjectLI/data/Senarai KPP.csv"));

                Path csvPath = null;
                for (Path candidate : csvCandidates) {
                    if (candidate != null && Files.exists(candidate)) {
                        csvPath = candidate;
                        break;
                    }
                }

                if (csvPath != null) {
                    try {
                        List<String> csvLines = Files.readAllLines(csvPath, StandardCharsets.UTF_8);
                        for (int i = 1; i < csvLines.size(); i++) {
                            String line = csvLines.get(i);
                            if (line == null || line.isBlank()) {
                                continue;
                            }

                            List<String> parts = parseCsvLine(line);
                            if (parts.size() < 3) {
                                continue;
                            }

                            String name = parts.get(0).trim();
                            String jawatan = parts.get(1).trim();
                            String email = parts.get(2).trim();
                            if (name.isEmpty() || email.isEmpty()) {
                                continue;
                            }

                            Map<String, String> entry = new LinkedHashMap<>();
                            entry.put("name", name);
                            entry.put("jawatan", jawatan);
                            entry.put("email", email);
                            kppRecipients.add(entry);
                        }
                    } catch (Exception ignore) {
                        // If CSV cannot be read, UI remains usable with manual fallback text.
                    }
                }
            }
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
                    <div class="field status-filter-compact">
                        <label for="status">Status</label>
                        <div class="status-filter-controls">
                            <select id="status" name="status">
                                <option value="">Semua status</option>
                                <option value="NEW" <%= "NEW".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>NEW</option>
                                <option value="DALAM_SEMAKAN" <%= "DALAM_SEMAKAN".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DALAM SEMAKAN</option>
                                <option value="DALAM_PROSES" <%= "DALAM_PROSES".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DALAM PROSES</option>
                                <option value="DILULUSKAN" <%= "DILULUSKAN".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DILULUSKAN</option>
                                <option value="DITOLAK" <%= "DITOLAK".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DITOLAK</option>
                                <option value="DIGANTUNG" <%= "DIGANTUNG".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DIGANTUNG</option>
                                <option value="DIARKIB" <%= "DIARKIB".equals(request.getAttribute("selected_status")) ? "selected" : "" %>>DIARKIB</option>
                            </select>
                        </div>
                    </div>
                    <div class="field">
                        <label for="date_from">Tarikh Dari</label>
                        <input id="date_from" name="date_from" type="date" value="<%= request.getAttribute("date_from") != null ? request.getAttribute("date_from") : "" %>">
                    </div>
                    <div class="field">
                        <label for="date_to">Tarikh Hingga</label>
                        <input id="date_to" name="date_to" type="date" value="<%= request.getAttribute("date_to") != null ? request.getAttribute("date_to") : "" %>">
                    </div>
                    <div class="field export-control">
                        <label for="exportOption">Eksport</label>
                        <select id="exportOption" name="exportOption">
                            <optgroup label="Ikut penapis semasa">
                                <option value="xlsx_current">Excel</option>
                                <option value="pdf_current">PDF</option>
                            </optgroup>
                            <optgroup label="Status khusus">
                                <option value="xlsx_approved">Excel - DILULUSKAN</option>
                                <option value="xlsx_rejected">Excel - DITOLAK</option>
                                <option value="pdf_approved">PDF - DILULUSKAN</option>
                                <option value="pdf_rejected">PDF - DITOLAK</option>
                            </optgroup>
                        </select>
                    </div>
                    <button class="btn btn-secondary" type="button" id="exportDownloadBtn" aria-label="Muat Turun" title="Muat Turun"><img src="${pageContext.request.contextPath}/assets/images/icon-download.png" class="icon-inline" alt="Ikon turun"></button>
                    <button class="btn btn-secondary btn-archive-main" type="button" id="latestArchiveBtn" aria-label="Arkib" title="Arkib"><img src="${pageContext.request.contextPath}/icon/archive.png" class="icon-inline" alt="Ikon arkib" onerror="this.onerror=null;this.src='${pageContext.request.contextPath}/assets/images/icon-archive.png';"><span id="latestArchiveBtnLabel" class="archive-hover-label">Arkib</span></button>
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
                                String statusRaw = applicationRow.get("status") == null ? "" : String.valueOf(applicationRow.get("status"));
                                String status = statusRaw.trim().toLowerCase(java.util.Locale.ROOT);
                                String statusDisplay = displayStatusLabel(statusRaw);
                                int appIdNumeric = applicationRow.get("id") instanceof Number ? ((Number) applicationRow.get("id")).intValue() : 0;
                                int appIdDisplayNumeric = Math.max(0, appIdNumeric);
                                String appIdDisplay = String.format("PPP%03d", appIdDisplayNumeric);
                                boolean isArchivedRow = archivedAt != null;
                                boolean canArchiveRow = !isArchivedRow;
                        %>
                        <tr>
                            <% if (isAdminRole) { %>
                            <td><input type="checkbox" class="app-row-check table-check" value="<%= applicationRow.get("id") %>" data-can-archive="<%= canArchiveRow ? "1" : "0" %>" data-is-archived="<%= isArchivedRow ? "1" : "0" %>" aria-label="Pilih permohonan"></td>
                            <% } %>
                            <td><strong><%= appIdDisplay %></strong></td>
                            <td>
                                <strong><%= applicationRow.get("company_name") %></strong><br>
                                <span class="subtle">Pemohon: <%= applicationRow.get("full_name") %><br>Email: <%= applicationRow.get("user_email") %>
                                <% if (isArchivedRow && archivedAt != null) { %><br>Arkib: <%= archivedAt %><% } %>
                                </span>
                            </td>
                            <td><span class="status-pill status-<%= status %>"><%= statusDisplay %></span></td>
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
                                    data-status="<%= escapeHtml(statusDisplay) %>"
                                    data-submitted="<%= escapeHtml(submittedAt != null ? submittedAt.toString() : "Belum dihantar") %>"
                                    data-user="<%= escapeHtml(applicationRow.get("full_name") == null ? "" : String.valueOf(applicationRow.get("full_name")) ) %>"
                                    data-email="<%= escapeHtml(applicationRow.get("user_email") == null ? "" : String.valueOf(applicationRow.get("user_email")) ) %>"
                                    data-attachment-image="<%= escapeHtml(applicationRow.get("attachment_image_url") == null ? "" : String.valueOf(applicationRow.get("attachment_image_url")) ) %>"
                                    data-attachment-pdf="<%= escapeHtml(applicationRow.get("attachment_pdf_url") == null ? "" : String.valueOf(applicationRow.get("attachment_pdf_url")) ) %>">
                                    Semak
                                </a>
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
                    <h3 class="section-title">Tindakan Ketua Penolong Pengarah</h3>
                    <div class="kpp-action-grid">
                        <div class="kpp-draft">
                            <div class="kpp-form-grid">
                                <div>
                                    <label for="kppRecipientPickerBtn">Kepada &amp; Emel Penerima (Checklist KPP)</label>
                                    <div class="kpp-picker" id="kppRecipientPicker">
                                        <button id="kppRecipientPickerBtn" class="kpp-picker-btn" type="button">Pilih KPP (boleh pilih lebih dari satu)</button>
                                        <div id="kppRecipientPickerMenu" class="kpp-picker-menu">
                                            <% if (kppRecipients.isEmpty()) { %>
                                                <p class="kpp-help">Senarai KPP tidak dijumpai. Semak fail data/Senarai KPP.csv.</p>
                                            <% } else { %>
                                                <% for (Map<String, String> recipient : kppRecipients) { %>
                                                    <% String recipientName = escapeHtml(recipient.get("name")); %>
                                                    <label class="kpp-picker-item" <%= "ADMIN".equals(recipient.get("name")) ? "data-admin=\"true\"" : "" %>>
                                                        <input
                                                            class="js-kpp-recipient-check"
                                                            type="checkbox"
                                                            value="<%= escapeHtml(recipient.get("email")) %>"
                                                            data-name="<%= escapeHtml(recipient.get("name")) %>"
                                                            data-title="<%= escapeHtml(recipient.get("jawatan")) %>"
                                                            data-email="<%= escapeHtml(recipient.get("email")) %>">
                                                        <span>
                                                            <strong><%= recipientName %></strong><br>
                                                            <%= escapeHtml(recipient.get("jawatan")) %><br>
                                                            <%= escapeHtml(recipient.get("email")) %>
                                                        </span>
                                                    </label>
                                                <% } %>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>
                                <div>
                                    <label for="kppRecipientName">Kepada (Nama Penerima)</label>
                                    <input id="kppRecipientName" type="text" readonly placeholder="Belum pilih penerima">
                                </div>
                                <div>
                                    <label for="kppEmailTo">Emel Penerima</label>
                                    <input id="kppEmailTo" type="text" readonly placeholder="Belum pilih emel">
                                </div>
                                <div class="kpp-form-span">
                                    <label for="kppActionType">Tindakan Diperlukan</label>
                                    <select id="kppActionType">
                                        <option value="KSPP">Isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (Pembaharuan)</option>
                                        <option value="UJPPP">Isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air</option>
                                        <option value="KSPP_UJPPP">Isi Kedua-dua Borang (KSPP dan UJPPP)</option>
                                    </select>
                                </div>
                                <div class="kpp-form-span">
                                    <label for="kppApplicationRef">Borang Permohonan (Dihantar Pemohon)</label>
                                    <input id="kppApplicationSearch" type="text" placeholder="Cari ikut kod borang, syarikat, atau produk">
                                    <select id="kppApplicationRef">
                                        <option value="">-- Pilih Borang Permohonan --</option>
                                        <% if (applications != null) {
                                            for (Map<String, Object> appOption : applications) {
                                                int appIdValue = appOption.get("id") instanceof Number ? ((Number) appOption.get("id")).intValue() : 0;
                                                int appIdDisplayValue = Math.max(0, appIdValue);
                                                String appCode = String.format("PPP%03d", appIdDisplayValue);
                                                String appCompany = appOption.get("company_name") == null ? "Syarikat tidak dinyatakan" : String.valueOf(appOption.get("company_name"));
                                                String appProduct = appOption.get("product_name") == null ? "Produk tidak dinyatakan" : String.valueOf(appOption.get("product_name"));
                                                String appLabel = appCode + " - " + appCompany + " (" + appProduct + ")";
                                        %>
                                        <option value="<%= escapeHtml(appCode) %>"><%= escapeHtml(appLabel) %></option>
                                        <%  }
                                           } %>
                                    </select>
                                    <div class="kpp-inline-help">Taip untuk tapis senarai borang mengikut kod, nama syarikat, atau nama produk.</div>
                                </div>
                            </div>
                            <div>
                                <label for="kppEmailSubject">Subjek Email</label>
                                <input id="kppEmailSubject" type="text" placeholder="Subjek boleh diedit sebelum hantar">
                            </div>
                            <div>
                                <label for="kppEmailBody">Isi Email</label>
                                <textarea id="kppEmailBody" placeholder="Isi email boleh diedit sebelum hantar"></textarea>
                                <div class="kpp-inline-help">Tip: kekalkan teks [Pautan khas akan dijana semasa Hantar Email] dalam isi email untuk gantian pautan automatik.</div>
                            </div>
                            <div style="display:flex; gap:8px; flex-wrap:wrap;">
                                <button class="btn btn-primary" type="button" id="kppEmailSendBtn">Hantar Email</button>
                            </div>
                        </div>
                        <div class="kpp-submission-box" id="kpp-submissions">
                            <h4 class="kpp-submission-title">Senarai Respon Ketua Penolong Pengarah</h4>
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
                                        <div class="kpp-submission-main">
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
                                        </div>
                                        <div class="kpp-submission-status">
                                            <div class="kpp-status-badge-stack js-kpp-status-badge"
                                                 data-action="<%= escapeHtml(String.valueOf(kppSubmission.get("action_type"))) %>"
                                                 data-payload="<%= escapeHtml(String.valueOf(kppSubmission.get("form_payload"))) %>">
                                            </div>
                                        </div>
                                    </li>
                                    <% } %>
                                </ul>
                            <% } %>
                        </div>
                    </div>
                </div>

            </div>

            <div class="right-panel">
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

                <div class="panel">
                    <div class="audit-panel-header">
                        <h3 class="section-title">Rekod Tindakan Admin</h3>
                        <button type="button" class="audit-toggle-btn" id="toggleAuditBtnDashboard" aria-expanded="true" aria-controls="adminAuditContentDashboard" title="Sembunyi rekod tindakan admin">
                            <img id="toggleAuditIconDashboard" src="${pageContext.request.contextPath}/icon/hide.png" alt="Sembunyikan rekod tindakan admin">
                        </button>
                    </div>
                    <div id="adminAuditContentDashboard" class="audit-content">
                    <% if (adminAuditLogs != null && !adminAuditLogs.isEmpty()) { %>
                    <div class="audit-filter-bar">
                        <input id="auditSearchFilterDashboard" type="text" placeholder="Cari nama admin, tindakan atau butiran" aria-label="Cari rekod tindakan admin">
                    </div>
                    <% } %>
                    <ul class="audit-list">
                        <% if (adminAuditLogs != null && !adminAuditLogs.isEmpty()) {
                            for (Map<String, Object> auditRow : adminAuditLogs) {
                                String actorName = auditRow.get("full_name") == null
                                        ? String.valueOf(auditRow.get("username") == null ? "Admin" : auditRow.get("username"))
                                        : String.valueOf(auditRow.get("full_name"));
                                String actorDisplayId = String.valueOf(auditRow.get("display_user_id") == null ? "-" : auditRow.get("display_user_id"));
                                String action = String.valueOf(auditRow.get("action") == null ? "-" : auditRow.get("action"));
                                String actionDisplay = action.replace('_', ' ').replaceAll("\\s+", " ").trim();
                                String details = String.valueOf(auditRow.get("details") == null ? "Tiada penerangan." : auditRow.get("details"));
                                Timestamp actionAt = (Timestamp) auditRow.get("created_at");
                                String actorFilterValue = actorName + " (" + actorDisplayId + ")";
                                String auditSearchValue = (action + " " + details + " " + actorName + " " + actorDisplayId).toLowerCase();
                        %>
                        <li class="audit-item" data-audit-text="<%= escapeHtml(auditSearchValue) %>">
                            <strong><%= escapeHtml(actorName) %> (<%= escapeHtml(actorDisplayId) %>) <%= escapeHtml(actionDisplay) %></strong>
                            <p><%= escapeHtml(details) %></p>
                            <div class="audit-meta">
                                <span><%= actionAt == null ? "Masa tidak direkod" : escapeHtml(String.valueOf(actionAt)) %></span>
                            </div>
                        </li>
                        <%      }
                           } else { %>
                        <li class="audit-item">
                            <strong>Belum ada rekod tindakan</strong>
                            <p>Sistem akan menyimpan tindakan pentadbir secara automatik selepas sebarang kemas kini dibuat.</p>
                        </li>
                        <% } %>
                    </ul>
                    <% if (adminAuditLogs != null && !adminAuditLogs.isEmpty()) { %>
                    <div class="audit-filter-empty" id="auditFilterEmptyDashboard" style="display:none;">Tiada rekod sepadan dengan penapis semasa.</div>
                    <% } %>
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

                <div class="panel smtp-settings-panel" id="smtpSettingsPanel">
                    <div class="announcement-head">
                        <div class="title-wrap">
                            <img src="${pageContext.request.contextPath}/icon/email.png" alt="Tetapan Email">
                            <h3 class="section-title" style="margin:0;">Tetapan Email Pengirim KPP</h3>
                        </div>
                    </div>

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
                            <input id="smtp_host" name="smtp_host" type="text" required
                                   value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_host") == null ? "" : request.getAttribute("smtp_setting_host"))) %>">
                        </div>

                        <div>
                            <label for="smtp_port">SMTP Port</label>
                            <input id="smtp_port" name="smtp_port" type="number" min="1" required
                                   value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_port") == null ? "587" : request.getAttribute("smtp_setting_port"))) %>">
                        </div>

                        <div>
                            <label for="smtp_username">SMTP Username</label>
                            <input id="smtp_username" name="smtp_username" type="text"
                                   value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_username") == null ? "" : request.getAttribute("smtp_setting_username"))) %>">
                        </div>

                        <div>
                            <label for="smtp_password">SMTP Password Baharu</label>
                            <input id="smtp_password" name="smtp_password" type="password" autocomplete="new-password" placeholder="Kosongkan jika tidak mahu ubah">
                            <div class="smtp-form-help">Biarkan kosong untuk kekalkan password semasa.</div>
                        </div>

                        <div>
                            <label for="smtp_from">From Address</label>
                            <input id="smtp_from" name="smtp_from" type="email"
                                   value="<%= escapeHtml(String.valueOf(request.getAttribute("smtp_setting_from") == null ? "" : request.getAttribute("smtp_setting_from"))) %>">
                        </div>

                        <div>
                            <label for="smtp_auth">SMTP Auth</label>
                            <select id="smtp_auth" name="smtp_auth">
                                <option value="true" <%= "true".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_auth") == null ? "true" : request.getAttribute("smtp_setting_auth"))) ? "selected" : "" %>>Aktif</option>
                                <option value="false" <%= "false".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_auth") == null ? "true" : request.getAttribute("smtp_setting_auth"))) ? "selected" : "" %>>Tidak Aktif</option>
                            </select>
                        </div>

                        <div>
                            <label for="smtp_tls">STARTTLS</label>
                            <select id="smtp_tls" name="smtp_tls">
                                <option value="true" <%= "true".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_tls") == null ? "true" : request.getAttribute("smtp_setting_tls"))) ? "selected" : "" %>>Aktif</option>
                                <option value="false" <%= "false".equalsIgnoreCase(String.valueOf(request.getAttribute("smtp_setting_tls") == null ? "true" : request.getAttribute("smtp_setting_tls"))) ? "selected" : "" %>>Tidak Aktif</option>
                            </select>
                        </div>

                        <div class="smtp-span-2 smtp-form-actions">
                            <button class="btn btn-primary" type="submit">Simpan Tetapan Email</button>
                            <span class="smtp-form-note">Perubahan akan terus digunakan untuk hantar email Tindakan KPP.</span>
                        </div>
                    </form>
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
                <h3><img class="contact-icon" src="${pageContext.request.contextPath}/icon/contact.png" alt="Hubungi JAS"> Hubungi JAS</h3>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/address.png" alt="Alamat"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">SABAH WATER DEPARTMENT</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Tingkat 6, Blok A, Wisma MUIS, Beg Berkunci No. 210, 88825</a></p>
                <p class="contact-line contact-line-hanging"><a class="contact-address-link" href="https://www.google.com/maps/place/Jabatan+Air+Negeri+Sabah/data=!4m7!3m6!1s0x323b69b770552161:0x46ddcd3e362b7115!8m2!3d5.9610727!4d116.0687216!16s%2Fg%2F1pzrm3yct!19sChIJYSFVcLdpOzIRFXErNj7N3UY?authuser=0&hl=en&rclk=1" target="_blank" rel="noopener noreferrer">Kota Kinabalu, Sabah, Malaysia</a></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/phone.png" alt="Tel"><span>Tel: +60-88-232364 (HQ)</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/fax.png" alt="Fax"><span>Fax: +60-88-232396</span></p>
                <p class="contact-line"><img class="contact-icon" src="${pageContext.request.contextPath}/icon/email.png" alt="Email"><span>Email: jans.hq@sabah.gov.my</span></p></div>
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
    <div class="sent-popup" id="sentPopup" aria-hidden="true">
        <div class="sent-popup-card" role="dialog" aria-modal="true" aria-labelledby="sentPopupTitle">
            <img src="${pageContext.request.contextPath}/assets/images/sent-mail.gif" alt="Berjaya dihantar" class="sent-popup-icon">
            <h4 class="sent-popup-title" id="sentPopupTitle">Berjaya Dihantar</h4>
            <button type="button" class="sent-popup-ok" id="sentPopupOkBtn">OK</button>
        </div>
    </div>
    <div class="maintenance-popup" id="maintenancePopup" aria-hidden="true">
        <div class="maintenance-popup-card" role="dialog" aria-modal="true" aria-labelledby="maintenancePopupTitle">
            <img src="${pageContext.request.contextPath}/icon/quiz.gif" alt="Pengesahan tindakan" class="maintenance-popup-icon">
            <h4 class="maintenance-popup-title" id="maintenancePopupTitle">Pengesahan Penyelenggaraan</h4>
            <p class="maintenance-popup-text" id="maintenancePopupText">Teruskan tindakan penyelenggaraan?</p>
            <div class="maintenance-popup-actions">
                <button type="button" class="maintenance-popup-btn maintenance-popup-btn-cancel" id="maintenancePopupCancelBtn">Batal</button>
                <button type="button" class="maintenance-popup-btn maintenance-popup-btn-confirm" id="maintenancePopupConfirmBtn">Teruskan</button>
            </div>
        </div>
    </div>
    <div class="aduan-password-popup" id="aduanPasswordPopup" aria-hidden="true">
        <div class="aduan-password-popup-card" role="dialog" aria-modal="true" aria-labelledby="aduanPasswordPopupTitle">
            <img src="${pageContext.request.contextPath}/icon/password.gif" alt="Masukkan kata laluan" class="aduan-password-popup-icon">
            <h4 class="aduan-password-popup-title" id="aduanPasswordPopupTitle">Penerimaan Borang Aduan</h4>
            <p class="aduan-password-popup-text">Sila masukkan kata laluan admin <%= escapeHtml(aduanPasswordPromptLabel) %> untuk akses modul penerimaan aduan.</p>
            <input type="password" id="aduanPasswordPopupInput" class="aduan-password-popup-input" autocomplete="current-password" placeholder="Masukkan kata laluan">
            <div class="aduan-password-popup-actions">
                <button type="button" class="aduan-password-popup-btn aduan-password-popup-btn-cancel" id="aduanPasswordPopupCancelBtn">Batal</button>
                <button type="button" class="aduan-password-popup-btn aduan-password-popup-btn-confirm" id="aduanPasswordPopupConfirmBtn">Teruskan</button>
            </div>
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
        var latestArchiveBtn = document.getElementById('latestArchiveBtn');
        var latestArchiveBtnLabel = document.getElementById('latestArchiveBtnLabel');
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
        var sentPopup = document.getElementById('sentPopup');
        var sentPopupOkBtn = document.getElementById('sentPopupOkBtn');
        var toastTimer = null;
        var kppRecipientName = document.getElementById('kppRecipientName');
        var kppEmailTo = document.getElementById('kppEmailTo');
        var kppRecipientPicker = document.getElementById('kppRecipientPicker');
        var kppRecipientPickerBtn = document.getElementById('kppRecipientPickerBtn');
        var kppRecipientChecks = Array.prototype.slice.call(document.querySelectorAll('.js-kpp-recipient-check'));
        var kppActionType = document.getElementById('kppActionType');
        var kppApplicationSearch = document.getElementById('kppApplicationSearch');
        var kppApplicationRef = document.getElementById('kppApplicationRef');
        var kppEmailSubject = document.getElementById('kppEmailSubject');
        var kppEmailBody = document.getElementById('kppEmailBody');
        var kppEmailSendBtn = document.getElementById('kppEmailSendBtn');
        var kppStatusBadgeBoxes = Array.prototype.slice.call(document.querySelectorAll('.js-kpp-status-badge'));
        var kppViewButtons = Array.prototype.slice.call(document.querySelectorAll('.js-kpp-view-btn'));
        var kppSubmissionModal = document.getElementById('kppSubmissionModal');
        var kppSubmissionCloseBtn = document.getElementById('kppSubmissionCloseBtn');
        var kppSubmissionMeta = document.getElementById('kppSubmissionMeta');
        var kppSubmissionContent = document.getElementById('kppSubmissionContent');
        var kppSubmissionsBox = document.getElementById('kpp-submissions');
        var aduanSecureForm = document.getElementById('aduanSecureForm');
        var aduanSecureBtn = document.getElementById('aduanSecureBtn');
        var aduanSecurePassword = document.getElementById('aduanSecurePassword');
        var aduanPasswordPopup = document.getElementById('aduanPasswordPopup');
        var aduanPasswordPopupInput = document.getElementById('aduanPasswordPopupInput');
        var aduanPasswordPopupCancelBtn = document.getElementById('aduanPasswordPopupCancelBtn');
        var aduanPasswordPopupConfirmBtn = document.getElementById('aduanPasswordPopupConfirmBtn');

        var appDetailModal = document.getElementById('appDetailModal');
        var appModalCloseBtn = document.getElementById('appModalCloseBtn');
        var modalReviewLink = document.getElementById('modalReviewLink');
        var modalAttachmentViewer = document.getElementById('modalAttachmentViewer');
        var userRoleClient = '<%= String.valueOf(session.getAttribute("role")) %>';
        var isAdminRoleClient = userRoleClient === 'ADMIN';

        var contextPath = '<%= request.getContextPath() %>';

        function closeAduanPasswordPopup() {
            if (!aduanPasswordPopup) {
                return;
            }
            aduanPasswordPopup.classList.remove('show');
            aduanPasswordPopup.setAttribute('aria-hidden', 'true');
            if (aduanPasswordPopupInput) {
                aduanPasswordPopupInput.value = '';
            }
        }

        if (aduanSecureForm && aduanSecureBtn && aduanSecurePassword) {
            aduanSecureBtn.addEventListener('click', function () {
                var isAllowed = aduanSecureBtn.getAttribute('data-allowed') === '1';
                if (!isAllowed) {
                    window.alert('Akses modul Aduan hanya untuk admin ID ADM001.');
                    return;
                }

                if (!aduanPasswordPopup || !aduanPasswordPopupInput) {
                    window.alert('Paparan kata laluan tidak tersedia. Sila muat semula halaman.');
                    return;
                }

                aduanPasswordPopup.classList.add('show');
                aduanPasswordPopup.setAttribute('aria-hidden', 'false');
                aduanPasswordPopupInput.focus();
            });
        }

        if (aduanPasswordPopupCancelBtn) {
            aduanPasswordPopupCancelBtn.addEventListener('click', closeAduanPasswordPopup);
        }

        if (aduanPasswordPopup) {
            aduanPasswordPopup.addEventListener('click', function (event) {
                if (event.target === aduanPasswordPopup) {
                    closeAduanPasswordPopup();
                }
            });
        }

        if (aduanPasswordPopupConfirmBtn && aduanPasswordPopupInput && aduanSecurePassword && aduanSecureForm) {
            aduanPasswordPopupConfirmBtn.addEventListener('click', function () {
                var passwordInput = aduanPasswordPopupInput.value || '';

                if (!passwordInput.trim()) {
                    window.alert('Kata laluan diperlukan untuk meneruskan akses modul Aduan.');
                    aduanPasswordPopupInput.focus();
                    return;
                }

                aduanSecurePassword.value = passwordInput;
                closeAduanPasswordPopup();
                aduanSecureForm.submit();
            });
        }

        if (aduanPasswordPopupInput && aduanPasswordPopupConfirmBtn) {
            aduanPasswordPopupInput.addEventListener('keydown', function (event) {
                if (event.key === 'Enter') {
                    event.preventDefault();
                    aduanPasswordPopupConfirmBtn.click();
                }
                if (event.key === 'Escape') {
                    event.preventDefault();
                    closeAduanPasswordPopup();
                }
            });
        }

        function keepKppPanelOnScreen() {
            try {
                sessionStorage.setItem('dashboardAnchor', 'kpp-submissions');
            } catch (error) {
                
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

        function resolveLatestArchiveMode() {
            var selectedRows = appRowChecks.filter(function(row) {
                return row && row.checked;
            });

            if (selectedRows.length > 0) {
                var archivedCount = selectedRows.filter(function(row) {
                    return row.getAttribute('data-is-archived') === '1';
                }).length;

                if (archivedCount === selectedRows.length) {
                    return 'unarchive';
                }
                if (archivedCount === 0) {
                    return 'archive';
                }
            }

            var statusValue = statusSelect ? String(statusSelect.value || '').toUpperCase() : '';
            if (statusValue === 'DIARKIB') {
                return 'unarchive';
            }
            return 'archive';
        }

        function updateLatestArchiveButtonUi() {
            if (!latestArchiveBtn) {
                return;
            }
            var mode = resolveLatestArchiveMode();
            var label = mode === 'unarchive' ? 'Keluarkan Dari Arkib' : 'Arkib';
            latestArchiveBtn.setAttribute('title', label);
            latestArchiveBtn.setAttribute('aria-label', label);
            if (latestArchiveBtnLabel) {
                latestArchiveBtnLabel.textContent = label;
            }
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

        function getSelectedKppApplicationLabel() {
            if (!kppApplicationRef || !kppApplicationRef.options || kppApplicationRef.selectedIndex < 0) {
                return '';
            }
            var option = kppApplicationRef.options[kppApplicationRef.selectedIndex];
            if (!option) {
                return '';
            }
            var value = option.value || '';
            if (!value) {
                return '';
            }
            return (option.textContent || option.innerText || '').trim();
        }

        function syncKppApplicationOptions(filterValue) {
            if (!kppApplicationRef) {
                return;
            }

            var previousValue = kppApplicationRef.value || '';
            var normalizedFilter = String(filterValue || '').toLowerCase().trim();
            var allOptions = Array.prototype.slice.call(kppApplicationRef.querySelectorAll('option[data-kpp-app-option="1"]'));

            allOptions.forEach(function(option) {
                option.hidden = false;
                option.disabled = false;
            });

            var emptyOption = kppApplicationRef.querySelector('option[value=""]');
            if (emptyOption) {
                emptyOption.textContent = '-- Pilih Borang Permohonan --';
                emptyOption.hidden = false;
                emptyOption.disabled = false;
            }

            var visibleCount = 0;
            allOptions.forEach(function(option) {
                var optionLabel = (option.textContent || option.innerText || '').toLowerCase();
                var shouldShow = !normalizedFilter || optionLabel.indexOf(normalizedFilter) >= 0;
                option.hidden = !shouldShow;
                option.disabled = !shouldShow;
                if (shouldShow) {
                    visibleCount += 1;
                }
            });

            if (emptyOption && normalizedFilter && visibleCount === 0) {
                emptyOption.textContent = '-- Tiada borang dijumpai --';
            }

            var hasPreviousVisible = previousValue && allOptions.some(function(option) {
                return option.value === previousValue && !option.hidden;
            });

            if (hasPreviousVisible) {
                kppApplicationRef.value = previousValue;
                return;
            }

            if (kppApplicationRef.value && kppApplicationRef.value !== '') {
                kppApplicationRef.value = '';
                updateKppDraft();
            }
        }

        function buildKppSubject(actionType, applicationLabel) {
            var base = 'Tindakan Ketua Penolong Pengarah: ' + getKppActionLabel(actionType);
            if (applicationLabel) {
                return base + ' | Borang: ' + applicationLabel;
            }
            return base;
        }

        var KPP_LINK_PLACEHOLDER = '[Pautan khas akan dijana semasa Hantar Email]';

        function buildKppBody(recipientLabel, actionType, guestLinkBlock, applicationLabel) {
            var actionLine = '';
            if (actionType === 'UJPPP') {
                actionLine = '1) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).';
            } else if (actionType === 'KSPP_UJPPP') {
                actionLine = '1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).\n'
                    + '2) Sila isi Borang Ulasan Jawatankuasa Pendaftaran Pembekal dan Produk Bekalan Air (UJPPP).';
            } else {
                actionLine = '1) Sila isi Borang Kaji Selidik Prestasi Pembekal dan Produk Bekalan Air (KSPP).';
            }

            var applicationLine = applicationLabel
                ? ('Borang permohonan dirujuk: ' + applicationLabel + '\n\n')
                : '';

            return 'Assalamualaikum dan salam sejahtera ' + recipientLabel + ',\n\n'
                + 'Admin SPPPA memaklumkan bahawa terdapat tindakan tuan/puan berkenaan proses Pendaftaran Produk Air.\n'
                + applicationLine
                + 'Tindakan diperlukan:\n'
                + actionLine + '\n\n'
                + 'Sila tekan pautan khas di bawah untuk semakan dan tindakan lanjut:\n'
                + guestLinkBlock + '\n\n'
                + 'Terima kasih.';
        }

        function generateKppGuestLink(emailTo, actionType, applicationRef, recipientName, recipientTitle) {
            var url = contextPath + '/kpp/generate-link?recipient_email=' + encodeURIComponent(emailTo)
                + '&action_type=' + encodeURIComponent(actionType || 'KSPP')
                + '&app_ref=' + encodeURIComponent(applicationRef || '')
                + '&recipient_name=' + encodeURIComponent(recipientName || '')
                + '&recipient_title=' + encodeURIComponent(recipientTitle || '');

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

        function sendKppEmails(emailRequests) {
            return fetch(contextPath + '/dashboard', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/json;charset=UTF-8',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-Token': '${csrf_token}'
                },
                body: JSON.stringify({
                    action: 'send_kpp_emails',
                    emails: emailRequests
                })
            }).then(function(response) {
                return response.json().catch(function() {
                    return {};
                }).then(function(data) {
                    if (!response.ok || !data || !data.success) {
                        throw new Error(data && data.message ? data.message : ('HTTP ' + response.status));
                    }
                    return data;
                });
            });
        }

        function openKppDraftPicker(emailRequests) {
            if (!Array.isArray(emailRequests) || emailRequests.length === 0) {
                return;
            }

            var popup = window.open('', '_blank');
            if (!popup) {
                alert('Popup disekat oleh pelayar. Sila benarkan popup untuk buka draf email KPP.');
                return;
            }

            var itemHtml = emailRequests.map(function(item, index) {
                var safeTo = String(item && item.to ? item.to : '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                var mailtoUrl = 'mailto:' + encodeURIComponent(item.to || '')
                    + '?subject=' + encodeURIComponent(item.subject || '')
                    + '&body=' + encodeURIComponent(item.body || '');
                return '<li style="margin:10px 0;">'
                    + '<div style="font-weight:600;color:#183244;">' + (index + 1) + ') ' + safeTo + '</div>'
                    + '<a href="' + mailtoUrl + '" style="display:inline-block;margin-top:6px;padding:8px 12px;background:#0a7fbf;color:#fff;text-decoration:none;border-radius:6px;">Buka Draf Email</a>'
                    + '</li>';
            }).join('');

            popup.document.open();
            popup.document.write('<!doctype html><html><head><meta charset="utf-8"><title>Draf Email KPP</title><link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/global-typography.css?v=1"></head><body style="padding:16px;background:#f6fbff;color:#173042;">'
                + '<h2 style="margin:0 0 10px;">Draf Email KPP</h2>'
                + '<p style="margin:0 0 14px;">SMTP belum dikonfigurasi. Klik setiap butang di bawah untuk buka draf email khusus bagi setiap KPP.</p>'
                + '<ol style="padding-left:20px;">' + itemHtml + '</ol>'
                + '</body></html>');
            popup.document.close();
        }

        function getSelectedKppRecipients() {
            return kppRecipientChecks
                .filter(function(input) {
                    return !!input.checked;
                })
                .map(function(input) {
                    return {
                        name: (input.getAttribute('data-name') || '').trim(),
                        title: (input.getAttribute('data-title') || '').trim(),
                        email: (input.getAttribute('data-email') || '').trim()
                    };
                })
                .filter(function(recipient) {
                    return !!recipient.email;
                });
        }

        function updateKppPickerSummary() {
            var selected = getSelectedKppRecipients();
            var names = selected.map(function(recipient) {
                return recipient.name;
            });
            var emails = selected.map(function(recipient) {
                return recipient.email;
            });

            if (kppRecipientName) {
                kppRecipientName.value = names.join(', ');
            }
            if (kppEmailTo) {
                kppEmailTo.value = emails.join(', ');
            }
            if (kppRecipientPickerBtn) {
                kppRecipientPickerBtn.textContent = selected.length > 0
                    ? ('Dipilih: ' + selected.length + ' KPP')
                    : 'Pilih KPP (boleh pilih lebih dari satu)';
            }
        }

        function updateKppDraft() {
            if (!kppEmailSubject || !kppEmailBody) {
                return;
            }

            var kppName = kppRecipientName && kppRecipientName.value && kppRecipientName.value.trim()
                ? kppRecipientName.value.trim()
                : 'tuan/puan';
            var actionType = kppActionType ? (kppActionType.value || 'KSPP') : 'KSPP';
            var applicationLabel = getSelectedKppApplicationLabel();
            kppEmailSubject.value = buildKppSubject(actionType, applicationLabel);
            kppEmailBody.value = buildKppBody(kppName, actionType, KPP_LINK_PLACEHOLDER, applicationLabel);
        }

        function escapeRegExpText(value) {
            return String(value || '').replace(/[.*+?^$(){}|[\]\\]/g, '\\$&');
        }

        function replaceAllLiteralSafe(text, findValue, replaceValue) {
            var source = String(text || '');
            var findText = String(findValue || '');
            if (!findText) {
                return source;
            }
            return source.split(findText).join(String(replaceValue || ''));
        }

        function replaceRegexSafe(text, pattern, replaceValue) {
            return String(text || '').replace(pattern, function() {
                return String(replaceValue || '');
            });
        }

        function buildEditableKppEmailDraft(subjectTemplate, bodyTemplate, recipient, guestLink, actionType, applicationLabel) {
            var recipientName = (recipient && recipient.name ? recipient.name : '').trim() || 'tuan/puan';
            var guestLinkText = String(guestLink || '').trim();
            var finalSubjectTemplate = String(subjectTemplate || '').trim();
            var finalBodyTemplate = String(bodyTemplate || '').trim();

            if (!finalSubjectTemplate) {
                finalSubjectTemplate = buildKppSubject(actionType, applicationLabel);
            }
            if (!finalBodyTemplate) {
                finalBodyTemplate = buildKppBody(recipientName, actionType, KPP_LINK_PLACEHOLDER, applicationLabel);
            }

            var finalSubject = replaceRegexSafe(finalSubjectTemplate, /\{recipient_name\}|\{\{recipient_name\}\}/gi, recipientName);
            finalSubject = replaceRegexSafe(finalSubject, /\{application\}|\{\{application\}\}/gi, applicationLabel || '');

            var finalBody = replaceRegexSafe(finalBodyTemplate, /\{recipient_name\}|\{\{recipient_name\}\}/gi, recipientName);
            finalBody = replaceAllLiteralSafe(finalBody, KPP_LINK_PLACEHOLDER, guestLinkText);
            finalBody = replaceRegexSafe(finalBody, /\{link\}|\{\{link\}\}/gi, guestLinkText);
            finalBody = replaceRegexSafe(finalBody, /\{application\}|\{\{application\}\}/gi, applicationLabel || '');

            if (guestLinkText && finalBody.indexOf(guestLinkText) < 0) {
                finalBody += '\n\nPautan khas:\n' + guestLinkText;
            }

            return {
                subject: finalSubject,
                body: finalBody
            };
        }

        function parseKppPayloadText(payloadText) {
            if (!payloadText) {
                return null;
            }
            try {
                return JSON.parse(payloadText);
            } catch (error) {
                return null;
            }
        }

        function normalizeKsppDecision(value) {
            var normalized = String(value || '').toLowerCase().trim();
            if (!normalized) {
                return { text: 'KSPP: -', css: 'kpp-status-neutral' };
            }
            if (normalized.indexOf('setuju') >= 0 && normalized.indexOf('tidak') < 0) {
                return { text: 'KSPP: Bersetuju', css: 'kpp-status-good' };
            }
            return { text: 'KSPP: Tidak Bersetuju', css: 'kpp-status-bad' };
        }

        (function initAdminAuditToggleDashboard() {
            var button = document.getElementById('toggleAuditBtnDashboard');
            var content = document.getElementById('adminAuditContentDashboard');
            var icon = document.getElementById('toggleAuditIconDashboard');
            if (!button || !content || !icon) {
                return;
            }

            function setState(hidden) {
                content.classList.toggle('is-hidden', hidden);
                button.setAttribute('aria-expanded', hidden ? 'false' : 'true');
                button.setAttribute('title', hidden ? 'Paparkan rekod tindakan admin' : 'Sembunyi rekod tindakan admin');
                icon.src = hidden ? '${pageContext.request.contextPath}/icon/unhide.png' : '${pageContext.request.contextPath}/icon/hide.png';
                icon.alt = hidden ? 'Paparkan rekod tindakan admin' : 'Sembunyikan rekod tindakan admin';
            }

            button.addEventListener('click', function() {
                setState(!content.classList.contains('is-hidden'));
            });

            setState(false);
        })();

        (function initAdminAuditFilterDashboard() {
            var textFilter = document.getElementById('auditSearchFilterDashboard');
            var emptyMessage = document.getElementById('auditFilterEmptyDashboard');
            var auditItems = Array.prototype.slice.call(document.querySelectorAll('#adminAuditContentDashboard .audit-item[data-audit-text]'));

            if (!textFilter || auditItems.length === 0) {
                return;
            }

            function applyAuditFilter() {
                var searchKeyword = String(textFilter.value || '').toLowerCase().trim();
                var visibleCount = 0;

                auditItems.forEach(function(item) {
                    var itemText = String(item.getAttribute('data-audit-text') || '').toLowerCase();
                    var matchesText = !searchKeyword || itemText.indexOf(searchKeyword) >= 0;
                    var isVisible = matchesText;
                    item.style.display = isVisible ? '' : 'none';
                    if (isVisible) {
                        visibleCount++;
                    }
                });

                if (emptyMessage) {
                    emptyMessage.style.display = visibleCount > 0 ? 'none' : 'block';
                }
            }

            textFilter.addEventListener('input', applyAuditFilter);
            applyAuditFilter();
        })();

        function normalizeUjpppDecision(value) {
            var normalized = String(value || '').toLowerCase().trim();
            if (!normalized) {
                return { text: 'UJPP: -', css: 'kpp-status-neutral' };
            }
            if (normalized.indexOf('terima') >= 0) {
                return { text: 'UJPP: Diterima', css: 'kpp-status-good' };
            }
            if (normalized.indexOf('tolak') >= 0) {
                return { text: 'UJPP: Ditolak', css: 'kpp-status-bad' };
            }
            if (normalized.indexOf('gantung') >= 0 || normalized.indexOf('batal') >= 0) {
                return { text: 'UJPP: Digantung/Dibatal', css: 'kpp-status-warn' };
            }
            return { text: 'UJPP: ' + String(value || '-'), css: 'kpp-status-neutral' };
        }

        function createKppStatusBadge(text, cssClass) {
            var badge = document.createElement('span');
            badge.className = 'kpp-status-badge ' + cssClass;
            badge.textContent = text;
            return badge;
        }

        function pickSingleKppSubmissionStatus(actionType, ksppDecision, ujpppDecision) {
            var action = String(actionType || '').toUpperCase();
            var kspp = normalizeKsppDecision(ksppDecision);
            var ujppp = normalizeUjpppDecision(ujpppDecision);

            if (action === 'KSPP') {
                return kspp;
            }
            if (action === 'UJPPP') {
                return ujppp;
            }
            if (action === 'KSPP_UJPPP') {
                if (ujppp.css === 'kpp-status-warn') {
                    return ujppp;
                }
                if (ujppp.text !== 'UJPP: -') {
                    return ujppp;
                }
                if (kspp.text !== 'KSPP: -') {
                    return kspp;
                }
            }

            return { text: 'Status: -', css: 'kpp-status-neutral' };
        }

        function renderKppSubmissionStatuses() {
            kppStatusBadgeBoxes.forEach(function(box) {
                if (!box) {
                    return;
                }
                var actionType = String(box.getAttribute('data-action') || '').toUpperCase();
                var payload = parseKppPayloadText(box.getAttribute('data-payload') || '');
                var ksppDecision = payload ? (payload.f_kspp_review_decision || '') : '';
                var ujpppDecision = payload ? (payload.f_ujppp_review_recommendation || '') : '';
                var selectedStatus = pickSingleKppSubmissionStatus(actionType, ksppDecision, ujpppDecision);

                box.innerHTML = '';
                box.appendChild(createKppStatusBadge(selectedStatus.text, selectedStatus.css));
            });
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
                    statusCell.textContent = 'DIARKIB';
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
            if (statusSelect && statusSelect.value === 'DIARKIB') {
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

        function showSentPopup() {
            if (!sentPopup) {
                alert('Berjaya Dihantar');
                return;
            }
            sentPopup.classList.add('show');
            sentPopup.setAttribute('aria-hidden', 'false');
        }

        function hideSentPopup() {
            if (!sentPopup) {
                return;
            }
            sentPopup.classList.remove('show');
            sentPopup.setAttribute('aria-hidden', 'true');
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
                { label: 'Borang Permohonan Dirujuk', value: getValue(payload, 'f_application_ref') },
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

        if (sentPopupOkBtn) {
            sentPopupOkBtn.addEventListener('click', function() {
                hideSentPopup();
            });
        }

        if (sentPopup) {
            sentPopup.addEventListener('click', function(event) {
                if (event.target === sentPopup) {
                    hideSentPopup();
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

        if (latestArchiveBtn) {
            latestArchiveBtn.addEventListener('click', function(e) {
                e.preventDefault();

                var selectedRows = appRowChecks.filter(function(row) {
                    return row && row.checked;
                });

                if (selectedRows.length === 0) { return; }

                var mode = resolveLatestArchiveMode();
                var archivableRows = selectedRows.filter(function(row) {
                    if (mode === 'unarchive') {
                        return row.getAttribute('data-is-archived') === '1';
                    }
                    return row.getAttribute('data-can-archive') === '1' && row.getAttribute('data-is-archived') !== '1';
                });

                if (archivableRows.length === 0) { return; }

                latestArchiveBtn.disabled = true;
                var previousLabel = latestArchiveBtn.title;
                latestArchiveBtn.title = mode === 'unarchive' ? 'Mengeluarkan dari arkib...' : 'Mengarkibkan...';

                Promise.all(archivableRows.map(function(row) {
                    return doArchiveRequest(
                        row.value || '',
                        mode === 'unarchive' ? 'unarchive' : 'archive',
                        '${csrf_token}',
                        contextPath
                    );
                }))
                    .then(function() {
                        window.location.reload();
                    })
                    .catch(function() {})
                    .finally(function() {
                        latestArchiveBtn.disabled = false;
                        latestArchiveBtn.title = previousLabel;
                        updateLatestArchiveButtonUi();
                    });
            });
        }

        if (statusSelect) {
            statusSelect.addEventListener('change', function() {
                if (toolbarForm) {
                    toolbarForm.submit();
                }
            });
            statusSelect.addEventListener('change', updateLatestArchiveButtonUi);
        }

        appRowChecks.forEach(function(row) {
            row.addEventListener('change', updateLatestArchiveButtonUi);
        });

        updateLatestArchiveButtonUi();

        if (kppRecipientPickerBtn && kppRecipientPicker) {
            kppRecipientPickerBtn.addEventListener('click', function() {
                var isOpen = kppRecipientPicker.classList.contains('open');
                if (isOpen) {
                    kppRecipientPicker.classList.remove('open');
                } else {
                    kppRecipientPicker.classList.add('open');
                }
            });

            document.addEventListener('click', function(event) {
                if (kppRecipientPicker && !kppRecipientPicker.contains(event.target)) {
                    kppRecipientPicker.classList.remove('open');
                }
            });
        }

        kppRecipientChecks.forEach(function(input) {
            input.addEventListener('change', function() {
                updateKppPickerSummary();
                updateKppDraft();
            });
        });

        if (kppActionType) {
            kppActionType.addEventListener('change', function() {
                updateKppDraft();
            });
        }

        if (kppApplicationRef) {
            kppApplicationRef.addEventListener('change', function() {
                updateKppDraft();
            });
        }

        if (kppApplicationSearch) {
            kppApplicationSearch.addEventListener('input', function() {
                syncKppApplicationOptions(kppApplicationSearch.value || '');
            });
        }

        updateKppPickerSummary();
        if (kppApplicationRef) {
            Array.prototype.slice.call(kppApplicationRef.querySelectorAll('option')).forEach(function(option) {
                if (option.value) {
                    option.setAttribute('data-kpp-app-option', '1');
                }
            });
        }
        syncKppApplicationOptions(kppApplicationSearch ? (kppApplicationSearch.value || '') : '');
        updateKppDraft();
        renderKppSubmissionStatuses();

        if (kppEmailSendBtn) {
            kppEmailSendBtn.addEventListener('click', function() {
                var selectedRecipients = getSelectedKppRecipients();
                var actionType = kppActionType ? (kppActionType.value || 'KSPP') : 'KSPP';
                var applicationRef = kppApplicationRef ? (kppApplicationRef.value || '') : '';
                var applicationLabel = getSelectedKppApplicationLabel();
                var subjectTemplate = kppEmailSubject ? String(kppEmailSubject.value || '').trim() : '';
                var bodyTemplate = kppEmailBody ? String(kppEmailBody.value || '').trim() : '';
                var preparedEmailRequests = [];

                if (selectedRecipients.length === 0) {
                    alert('Sila pilih sekurang-kurangnya satu KPP dahulu.');
                    return;
                }

                if (!applicationRef) {
                    alert('Sila pilih Borang Permohonan yang hendak diambil tindakan.');
                    return;
                }

                if (!subjectTemplate) {
                    alert('Sila isi Subjek Email dahulu.');
                    return;
                }

                if (!bodyTemplate) {
                    alert('Sila isi kandungan Isi Email dahulu.');
                    return;
                }

                var previousLabel = kppEmailSendBtn.textContent;
                kppEmailSendBtn.disabled = true;
                kppEmailSendBtn.textContent = 'Menjana Pautan...';

                Promise.all(selectedRecipients.map(function(recipient) {
                    return generateKppGuestLink(
                        recipient.email,
                        actionType,
                        applicationRef,
                        recipient.name,
                        recipient.title
                    ).then(function(guestLink) {
                        return {
                            recipient: recipient,
                            link: guestLink
                        };
                    });
                }))
                    .then(function(results) {
                        var firstDraft = null;
                        var emailRequests = results.map(function(item) {
                            var editableDraft = buildEditableKppEmailDraft(
                                subjectTemplate,
                                bodyTemplate,
                                item.recipient,
                                item.link,
                                actionType,
                                applicationLabel
                            );
                            var subject = editableDraft.subject;
                            var body = editableDraft.body;

                            if (!firstDraft) {
                                firstDraft = {
                                    subject: subject,
                                    body: body
                                };
                            }

                            return {
                                to: item.recipient.email,
                                subject: subject,
                                body: body,
                                actionType: actionType,
                                applicationRef: applicationRef
                            };
                        });
                        preparedEmailRequests = emailRequests;

                        if (firstDraft && kppEmailSubject) {
                            kppEmailSubject.value = firstDraft.subject;
                        }
                        if (firstDraft && kppEmailBody) {
                            kppEmailBody.value = firstDraft.body;
                        }

                        kppEmailSendBtn.textContent = 'Menghantar Email...';
                        return sendKppEmails(emailRequests);
                    })
                    .then(function(result) {
                        showSentPopup();
                    })
                    .catch(function(error) {
                        var messageText = error && error.message ? String(error.message) : '';
                        var normalizedMessage = messageText.toLowerCase();
                        var isSmtpNotConfigured = normalizedMessage.indexOf('smtp belum dikonfigurasi') >= 0;
                        var isAllSendFailed = normalizedMessage.indexOf('semua email kpp gagal dihantar') >= 0;
                        if (isSmtpNotConfigured) {
                            alert('SMTP belum dikonfigurasi dengan betul. Sila semak tetapan smtp di web.xml dan cuba semula.');
                            return;
                        }
                        if (isAllSendFailed) {
                            alert(messageText || 'Semua email KPP gagal dihantar.');
                            return;
                        }
                        alert('Gagal menghantar email KPP. ' + (error && error.message ? error.message : ''));
                    })
                    .finally(function() {
                        kppEmailSendBtn.disabled = false;
                        kppEmailSendBtn.textContent = previousLabel;
                    });
            });
        }
    })();

    function doArchiveRequest(appId, actionValue, csrfToken, ctxPath) {
        var body = 'id=' + encodeURIComponent(appId) +
                   '&action=' + encodeURIComponent(actionValue) +
                   '&ajax=1' +
                   '&_csrf=' + encodeURIComponent(csrfToken);

        return fetch(ctxPath + '/admin/application', {
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
                return;
            }
            return resp.text().then(function(t) {
                throw new Error(resp.status + ' ' + t.substring(0, 200));
            });
        });
    }

    function doArchive(appId, actionValue, confirmText, csrfToken, ctxPath) {
        if (!window.confirm(confirmText)) { return; }
        doArchiveRequest(appId, actionValue, csrfToken, ctxPath).then(function() {
            window.location.reload();
        }).catch(function(err) {
            alert('Ralat rangkaian: ' + err);
        });
    }
</script>
<script>
    (function () {
        var maintenanceActionForm = document.getElementById('maintenanceActionForm');
        var maintenanceActionBtn = document.getElementById('maintenanceActionBtn');
        var maintenancePopup = document.getElementById('maintenancePopup');
        var maintenancePopupText = document.getElementById('maintenancePopupText');
        var maintenancePopupCancelBtn = document.getElementById('maintenancePopupCancelBtn');
        var maintenancePopupConfirmBtn = document.getElementById('maintenancePopupConfirmBtn');

        if (!maintenanceActionForm || !maintenanceActionBtn || !maintenancePopup || !maintenancePopupText
            || !maintenancePopupCancelBtn || !maintenancePopupConfirmBtn) {
            return;
        }

        function closeMaintenancePopup() {
            maintenancePopup.classList.remove('show');
            maintenancePopup.setAttribute('aria-hidden', 'true');
        }

        maintenanceActionBtn.addEventListener('click', function () {
            var confirmText = maintenanceActionBtn.getAttribute('data-maintenance-confirm') || 'Teruskan tindakan penyelenggaraan?';
            maintenancePopupText.textContent = confirmText;
            maintenancePopup.classList.add('show');
            maintenancePopup.setAttribute('aria-hidden', 'false');
        });

        maintenancePopupCancelBtn.addEventListener('click', closeMaintenancePopup);
        maintenancePopup.addEventListener('click', function (event) {
            if (event.target === maintenancePopup) {
                closeMaintenancePopup();
            }
        });

        maintenancePopupConfirmBtn.addEventListener('click', function () {
            closeMaintenancePopup();
            maintenanceActionForm.submit();
        });
    })();
</script>
</body>
</html>

