package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
import com.sistemppa.util.EmailUtil;
import com.sistemppa.util.UserDisplayIdUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

public class AdminApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(AdminApplicationServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        String applicationId = request.getParameter("id");
        if (applicationId == null || applicationId.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureApplicationArchiveTable(conn);
            DashboardDataService.ensureCertificateColumns(conn);
            renderApplicationPage(conn, request, response, Integer.parseInt(applicationId), null);
        } catch (SQLException e) {
            LOGGER.severe("Failed to load admin application review page: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan permohonan");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        boolean ajaxRequest = isAjaxRequest(request);
        String action = request.getParameter("action");
        boolean archiveFlow = "archive".equals(action) || "unarchive".equals(action);
        boolean shouldReturnJson = ajaxRequest || archiveFlow || "1".equals(request.getParameter("ajax"));

        Integer applicationIdValue = firstValidInteger(
            request.getParameter("id"),
            request.getParameter("application_id"),
            request.getParameter("applicationId"));
        if (applicationIdValue == null) {
            if (shouldReturnJson) {
                writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, "ID permohonan tidak sah", null);
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard?error=invalid_application_id");
            }
            return;
        }

        int applicationId = applicationIdValue;
        String adminNotes = trim(request.getParameter("admin_notes"));
        String validUntilStr = trim(request.getParameter("valid_until"));
        String presentationDate = trim(request.getParameter("presentation_date"));
        String presentationTime = trim(request.getParameter("presentation_time"));
        String presentationVenue = trim(request.getParameter("presentation_venue"));
        String presentationMessage = trim(request.getParameter("presentation_message"));
        Integer adminUserId = (Integer) request.getSession(false).getAttribute("user_id");

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureApplicationArchiveTable(conn);
            DashboardDataService.ensureCertificateColumns(conn);

            if ("reject".equals(action) && (adminNotes == null || adminNotes.isBlank())) {
                if (ajaxRequest) {
                    writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                            "Sebab penolakan wajib diisi sebelum permohonan ditolak.", action);
                } else {
                    request.setAttribute("error", "Sebab penolakan wajib diisi sebelum permohonan ditolak.");
                    renderApplicationPage(conn, request, response, applicationId, "");
                }
                return;
            }

            if ("approve".equals(action)) {
                updateApplicationStatus(conn, applicationId, "APPROVED", adminNotes, adminUserId, validUntilStr);
                insertAdminAuditLog(conn, adminUserId, "APPROVE_APPLICATION",
                    "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " luluskan permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
                sendStatusEmail(request, conn, applicationId, "APPROVED", adminNotes);
            } else if ("reject".equals(action)) {
                updateApplicationStatus(conn, applicationId, "REJECTED", adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "REJECT_APPLICATION",
                    "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " tolak permohonan PPP" + String.format("%03d", applicationId) + ". Sebab: " + adminNotes, request.getRemoteAddr());
                sendStatusEmail(request, conn, applicationId, "REJECTED", adminNotes);
            } else if ("under_review".equals(action) || "dalam_semakan".equals(action)) {
                updateApplicationStatus(conn, applicationId, "UNDER_REVIEW", adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "UNDER_REVIEW_APPLICATION",
                    "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " set permohonan PPP" + String.format("%03d", applicationId) + " ke Dalam Semakan", request.getRemoteAddr());
            } else if ("in_progress".equals(action) || "dalam_proses".equals(action)) {
                if (presentationDate == null || presentationDate.isBlank()
                        || presentationTime == null || presentationTime.isBlank()
                        || presentationVenue == null || presentationVenue.isBlank()) {
                    String message = "Sila isi tarikh, masa, dan tempat pembentangan sebelum set status Dalam Proses.";
                    if (ajaxRequest) {
                        writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false, message, action);
                    } else {
                        request.setAttribute("error", message);
                        renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    }
                    return;
                }
                updateApplicationStatus(conn, applicationId, "IN_PROGRESS", adminNotes, adminUserId, null);
                insertInProgressPresentationNotification(conn, applicationId, adminNotes,
                        presentationDate, presentationTime, presentationVenue, presentationMessage);
                sendInProgressPresentationEmail(request, conn, applicationId,
                    presentationDate, presentationTime, presentationVenue, presentationMessage);
                insertAdminAuditLog(conn, adminUserId, "IN_PROGRESS_APPLICATION",
                        "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " set permohonan PPP" + String.format("%03d", applicationId) + " ke Dalam Proses", request.getRemoteAddr());
            } else if ("suspend_application".equals(action)) {
                updateApplicationStatus(conn, applicationId, "SUSPENDED", adminNotes, adminUserId, null);
                insertAdminAuditLog(conn, adminUserId, "SUSPEND_APPLICATION",
                        "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " gantung permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("suspend_user".equals(action)) {
                suspendUserByApplication(conn, applicationId, adminNotes);
                insertAdminAuditLog(conn, adminUserId, "SUSPEND_USER_BY_APPLICATION",
                        "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " gantung pengguna melalui permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("archive".equals(action)) {
                if (!canArchiveApplication(conn, applicationId)) {
                    if (ajaxRequest) {
                        writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                                "Permohonan hanya boleh diarkib selepas diambil tindakan (APPROVED/REJECTED/SUSPENDED).", action);
                    } else {
                        request.setAttribute("error", "Permohonan hanya boleh diarkib selepas diambil tindakan (APPROVED/REJECTED/SUSPENDED). ");
                        renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    }
                    return;
                }
                archiveApplication(conn, applicationId, adminNotes, adminUserId);
                insertAdminAuditLog(conn, adminUserId, "ARCHIVE_APPLICATION",
                    "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " arkib permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else if ("unarchive".equals(action)) {
                if (!isArchived(conn, applicationId)) {
                    if (ajaxRequest) {
                        writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                                "Permohonan ini belum diarkib.", action);
                    } else {
                        request.setAttribute("error", "Permohonan ini belum diarkib.");
                        renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    }
                    return;
                }
                unarchiveApplication(conn, applicationId);
                insertAdminAuditLog(conn, adminUserId, "UNARCHIVE_APPLICATION",
                    "Admin " + UserDisplayIdUtil.format(adminUserId, "ADMIN") + " buka arkib permohonan PPP" + String.format("%03d", applicationId), request.getRemoteAddr());
            } else {
                if (ajaxRequest) {
                    writeJson(response, HttpServletResponse.SC_BAD_REQUEST, false,
                            "Tindakan pentadbir tidak sah.", action);
                } else {
                    request.setAttribute("error", "Tindakan pentadbir tidak sah.");
                    renderApplicationPage(conn, request, response, applicationId, adminNotes);
                }
                return;
            }
            if (ajaxRequest) {
                String message = "Kemas kini berjaya.";
                if ("archive".equals(action)) {
                    message = "Berjaya arkib.";
                } else if ("unarchive".equals(action)) {
                    message = "Berjaya dikeluarkan dari arkib.";
                }
                writeJson(response, HttpServletResponse.SC_OK, true, message, action);
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/application?id=" + applicationId + "&updated=1");
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to update admin application review: " + e.getMessage());
            if (ajaxRequest) {
                writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, false,
                        "Gagal mengemas kini permohonan", action);
            } else {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal mengemas kini permohonan");
            }
        }
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String requestedWith = request.getHeader("X-Requested-With");
        String accept = request.getHeader("Accept");
        String ajaxParam = request.getParameter("ajax");
        return "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || "1".equals(ajaxParam)
                || (accept != null && accept.toLowerCase().contains("application/json"));
    }

    private Integer firstValidInteger(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            Integer parsed = parseInteger(value);
            if (parsed != null) {
                return parsed;
            }
        }
        return null;
    }

    private void writeJson(HttpServletResponse response, int statusCode,
            boolean ok, String message, String action) throws IOException {
        response.setStatus(statusCode);
        response.setContentType("application/json;charset=UTF-8");
        String safeMessage = message == null ? "" : message.replace("\\", "\\\\").replace("\"", "\\\"");
        String safeAction = action == null ? "" : action.replace("\\", "\\\\").replace("\"", "\\\"");
        response.getWriter().write("{\"ok\":" + ok
                + ",\"message\":\"" + safeMessage + "\""
                + ",\"action\":\"" + safeAction + "\"}");
    }

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }
        return true;
    }

    private void renderApplicationPage(Connection conn, HttpServletRequest request, HttpServletResponse response,
            int applicationId, String adminNotesOverride) throws SQLException, ServletException, IOException {
        Map<String, Object> application = new HashMap<>(loadApplication(conn, applicationId));
        if (application.isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Permohonan tidak ditemui");
            return;
        }

        if (adminNotesOverride != null) {
            application.put("admin_notes", adminNotesOverride);
        }

        request.setAttribute("application", application);
        request.setAttribute("applicationDetail", loadApplicationDetail(conn, applicationId));
        request.setAttribute("documents", loadDocuments(conn, applicationId));
        request.setAttribute("admin_audit_logs",
            DashboardDataService.loadRecentAdminAuditLogsByKeyword(
                conn,
                "PPP" + String.format("%03d", applicationId),
                20));
        request.getRequestDispatcher("/admin-application.jsp").forward(request, response);
    }

    private Map<String, Object> loadApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.*, u.full_name, u.email AS user_email, u.status AS user_status, "
                + "aa.archived_at, aa.archive_notes, aa.archived_by "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return Map.of();
                }
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("user_id", rs.getInt("user_id"));
                row.put("product_name", rs.getString("product_name"));
                row.put("product_category", rs.getString("product_category"));
                row.put("product_description", rs.getString("product_description"));
                row.put("company_name", rs.getString("company_name"));
                row.put("company_address", rs.getString("company_address"));
                row.put("contact_number", rs.getString("contact_number"));
                row.put("email", rs.getString("email"));
                row.put("status", rs.getString("status"));
                row.put("admin_notes", rs.getString("admin_notes"));
                row.put("submitted_at", rs.getTimestamp("submitted_at"));
                row.put("full_name", rs.getString("full_name"));
                row.put("user_email", rs.getString("user_email"));
                row.put("user_status", rs.getString("user_status"));
                row.put("archived_at", rs.getTimestamp("archived_at"));
                row.put("archive_notes", rs.getString("archive_notes"));
                row.put("archived_by", rs.getObject("archived_by"));
                row.put("certificate_number", rs.getString("certificate_number"));
                row.put("issued_at", rs.getDate("issued_at"));
                row.put("valid_until", rs.getDate("valid_until"));
                return row;
            }
        }
    }

    private Map<String, Object> loadApplicationDetail(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT * FROM application_details WHERE application_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return Map.of();
                }
                Map<String, Object> row = new HashMap<>();
                row.put("application_type", rs.getString("application_type"));
                row.put("supplier_name", rs.getString("supplier_name"));
                row.put("supplier_address", rs.getString("supplier_address"));
                row.put("supplier_phone", rs.getString("supplier_phone"));
                row.put("manufacturer_name", rs.getString("manufacturer_name"));
                row.put("manufacturer_address", rs.getString("manufacturer_address"));
                row.put("manufacturer_phone", rs.getString("manufacturer_phone"));
                row.put("principal_name", rs.getString("principal_name"));
                row.put("principal_address", rs.getString("principal_address"));
                row.put("principal_phone", rs.getString("principal_phone"));
                row.put("standard_name", rs.getString("standard_name"));
                row.put("certification_license", rs.getString("certification_license"));
                row.put("certification_valid_until", rs.getDate("certification_valid_until"));
                row.put("test_report_reference", rs.getString("test_report_reference"));
                row.put("test_report_date", rs.getDate("test_report_date"));
                row.put("warranty_years", rs.getBigDecimal("warranty_years"));
                row.put("sabah_rep_name", rs.getString("sabah_rep_name"));
                row.put("sabah_rep_address", rs.getString("sabah_rep_address"));
                row.put("sabah_rep_phone", rs.getString("sabah_rep_phone"));
                row.put("declaration_name", rs.getString("declaration_name"));
                row.put("declaration_position", rs.getString("declaration_position"));
                return row;
            }
        }
    }

    private List<Map<String, Object>> loadDocuments(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT id, document_type, original_filename, content_type, file_size, created_at FROM application_documents WHERE application_id = ? ORDER BY id ASC";
        List<Map<String, Object>> documents = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("document_type", rs.getString("document_type"));
                    row.put("original_filename", rs.getString("original_filename"));
                    row.put("content_type", rs.getString("content_type"));
                    row.put("file_size", rs.getLong("file_size"));
                    row.put("created_at", rs.getTimestamp("created_at"));
                    documents.add(row);
                }
            }
        }
        return documents;
    }

    private void updateApplicationStatus(Connection conn, int applicationId, String status,
            String adminNotes, Integer changedBy, String validUntilStr) throws SQLException {
        // Fetch previous status for history
        String oldStatus = null;
        try (PreparedStatement stmt = conn.prepareStatement(
                "SELECT status FROM applications WHERE id = ? LIMIT 1")) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    oldStatus = rs.getString("status");
                }
            }
        }

        String sql = "UPDATE applications SET status = ?, admin_notes = ?, reviewed_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setString(2, adminNotes);
            stmt.setInt(3, applicationId);
            stmt.executeUpdate();
        }

        // Generate and store Perakuan Pendaftaran when approved
        if ("APPROVED".equals(status)) {
            String certNumber = String.format("JANS/PPP/%d/%04d",
                    java.time.Year.now().getValue(), applicationId);
            LocalDate validUntil;
            if (validUntilStr != null && !validUntilStr.isBlank()) {
                try {
                    validUntil = LocalDate.parse(validUntilStr);
                } catch (Exception e) {
                    validUntil = LocalDate.now().plusYears(2);
                }
            } else {
                validUntil = LocalDate.now().plusYears(2);
            }
            String certSql = "UPDATE applications SET certificate_number = ?, issued_at = CURRENT_DATE, valid_until = ? WHERE id = ?";
            try (PreparedStatement ps = conn.prepareStatement(certSql)) {
                ps.setString(1, certNumber);
                ps.setDate(2, Date.valueOf(validUntil));
                ps.setInt(3, applicationId);
                ps.executeUpdate();
            }
        }

        // Record status change in history
        DashboardDataService.recordStatusHistory(conn, applicationId, oldStatus, status, changedBy, adminNotes);

        // Notify the applicant
        int userId = getApplicationUserId(conn, applicationId);
        if (userId > 0) {
            String message;
            String type;
            if ("APPROVED".equals(status)) {
                String certRef = String.format("JANS/PPP/%d/%04d",
                        java.time.Year.now().getValue(), applicationId);
                message = "Permohonan PPP" + String.format("%03d", applicationId) + " anda telah DILULUSKAN. Perakuan Pendaftaran " + certRef + " telah dikeluarkan.";
                type = "SUCCESS";
            } else if ("REJECTED".equals(status)) {
                message = "Permohonan PPP" + String.format("%03d", applicationId) + " anda telah DITOLAK."
                        + (adminNotes != null && !adminNotes.isBlank() ? " Sebab: " + adminNotes : "");
                type = "ERROR";
            } else if ("SUSPENDED".equals(status)) {
                message = "Permohonan PPP" + String.format("%03d", applicationId) + " anda telah DIGANTUNG.";
                type = "WARNING";
            } else {
                message = "Status permohonan PPP" + String.format("%03d", applicationId) + " telah dikemas kini kepada " + status + ".";
                type = "INFO";
            }
            DashboardDataService.insertNotification(conn, userId, message, type);
        }
    }

    private int getApplicationUserId(Connection conn, int applicationId) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement("SELECT user_id FROM applications WHERE id = ?")) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("user_id") : 0;
            }
        }
    }

    private void insertInProgressPresentationNotification(Connection conn, int applicationId,
            String adminNotes, String presentationDate, String presentationTime,
            String presentationVenue, String presentationMessage) throws SQLException {
        int userId = getApplicationUserId(conn, applicationId);
        if (userId <= 0) {
            return;
        }

        String generatedMessage = "Pemohon dimaklumkan untuk bersedia dan menghadiri sesi Pembentangan Produk Air yang didaftarkan."
            + "\nTarikh: " + presentationDate
            + "\nMasa: " + presentationTime
            + "\nTempat: " + presentationVenue;

        String finalMessage = (presentationMessage == null || presentationMessage.isBlank())
                ? generatedMessage
                : presentationMessage;

        finalMessage = finalMessage
            .replace("<", "")
            .replace(">", "")
            .trim();

        DashboardDataService.insertNotification(conn, userId, finalMessage, "PRESENTATION");
    }

    private void suspendUserByApplication(Connection conn, int applicationId, String adminNotes) throws SQLException {
        String sql = "UPDATE users u JOIN applications a ON a.user_id = u.id "
                + "SET u.status = 'SUSPENDED', a.status = 'SUSPENDED', a.admin_notes = ?, a.reviewed_at = CURRENT_TIMESTAMP "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, adminNotes);
            stmt.setInt(2, applicationId);
            stmt.executeUpdate();
        }
    }

    private void archiveApplication(Connection conn, int applicationId, String adminNotes, Integer adminUserId) throws SQLException {
        String sql = "INSERT INTO application_archives (application_id, archived_by, archive_notes, archived_at) "
                + "VALUES (?, ?, ?, CURRENT_TIMESTAMP) "
                + "ON DUPLICATE KEY UPDATE archived_by = VALUES(archived_by), archive_notes = VALUES(archive_notes), archived_at = CURRENT_TIMESTAMP";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            if (adminUserId == null) {
                stmt.setNull(2, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(2, adminUserId);
            }
            stmt.setString(3, adminNotes);
            stmt.executeUpdate();
        }
    }

    private void unarchiveApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "DELETE FROM application_archives WHERE application_id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.executeUpdate();
        }
    }

    private boolean isArchived(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT 1 FROM application_archives WHERE application_id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private boolean canArchiveApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.status, a.reviewed_at, aa.application_id AS archived_ref "
                + "FROM applications a "
                + "LEFT JOIN application_archives aa ON aa.application_id = a.id "
                + "WHERE a.id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                if (rs.getObject("archived_ref") != null) {
                    return false;
                }
                String status = rs.getString("status");
                boolean hasReviewedAt = rs.getTimestamp("reviewed_at") != null;
                boolean allowedStatus = "APPROVED".equals(status) || "REJECTED".equals(status) || "SUSPENDED".equals(status);
                return hasReviewedAt && allowedStatus;
            }
        }
    }

    private void ensureApplicationArchiveTable(Connection conn) throws SQLException {
        String sql = "CREATE TABLE IF NOT EXISTS application_archives ("
                + "application_id INT NOT NULL PRIMARY KEY, "
                + "archived_by INT NULL, "
                + "archive_notes VARCHAR(500) NULL, "
                + "archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "CONSTRAINT fk_application_archives_application FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE, "
                + "CONSTRAINT fk_application_archives_archived_by FOREIGN KEY (archived_by) REFERENCES users(id) ON DELETE SET NULL, "
                + "INDEX idx_application_archives_archived_at (archived_at)"
                + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.execute();
        }
    }

    private Integer parseInteger(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String trim(String value) {
        return value != null ? value.trim() : null;
    }

    // -------------------------------------------------------------------------
    // Audit logging
    // -------------------------------------------------------------------------

    private void insertAdminAuditLog(Connection conn, Integer adminId, String action,
            String details, String ip) {
        if (adminId == null) return;
        try {
            String sql = "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, adminId);
                ps.setString(2, action);
                ps.setString(3, details);
                ps.setString(4, ip);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            LOGGER.warning("Failed to write audit log [" + action + "]: " + e.getMessage());
        }
    }

    // -------------------------------------------------------------------------
    // Email notifications to applicant on status change
    // -------------------------------------------------------------------------

    private void sendStatusEmail(HttpServletRequest request, Connection conn,
            int applicationId, String newStatus, String adminNotes) {
        String smtpHost = getContextParam(request, "smtp.host", "");
        if (smtpHost.isBlank()) return; // SMTP not configured

        try {
            // Fetch applicant email, name, and product name
            String emailAddr = null;
            String fullName  = null;
            String product   = null;
            String certRef   = null;
            String sql = "SELECT u.email, u.full_name, a.product_name, a.certificate_number "
                    + "FROM applications a JOIN users u ON u.id = a.user_id WHERE a.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, applicationId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        emailAddr = rs.getString("email");
                        fullName  = rs.getString("full_name");
                        product   = rs.getString("product_name");
                        certRef   = rs.getString("certificate_number");
                    }
                }
            }

            if (emailAddr == null || emailAddr.isBlank()) return;

            int    smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
            boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
            boolean smtpTls  = Boolean.parseBoolean(getContextParam(request, "smtp.tls",  "true"));
            String smtpUser  = getContextParam(request, "smtp.username", "");
            String smtpPass  = getContextParam(request, "smtp.password", "");
            String smtpFrom  = getContextParam(request, "smtp.from", smtpUser);

            String subject;
            String bodyContent;
            if ("APPROVED".equals(newStatus)) {
                subject = "Permohonan PPP" + String.format("%03d", applicationId) + " DILULUSKAN \u2013 SPPA";
                bodyContent = "<p>Salam " + escapeHtml(fullName) + ",</p>"
                        + "<p>Kami dengan sukacitanya memaklumkan bahawa permohonan anda untuk produk <strong>"
                        + escapeHtml(product) + "</strong> (No. Rujukan: PPP" + String.format("%03d", applicationId) + ") telah <strong>DILULUSKAN</strong>.</p>"
                        + (certRef != null ? "<p>No. Perakuan Pendaftaran: <strong>" + escapeHtml(certRef) + "</strong></p>" : "")
                        + "<p>Anda boleh log masuk ke sistem untuk melihat dan mencetak perakuan anda.</p>"
                        + "<p>Terima kasih.</p>";
            } else if ("REJECTED".equals(newStatus)) {
                subject = "Permohonan PPP" + String.format("%03d", applicationId) + " DITOLAK \u2013 SPPA";
                bodyContent = "<p>Salam " + escapeHtml(fullName) + ",</p>"
                        + "<p>Kami memaklumkan bahawa permohonan anda untuk produk <strong>"
                        + escapeHtml(product) + "</strong> (No. Rujukan: PPP" + String.format("%03d", applicationId) + ") telah <strong>DITOLAK</strong>.</p>"
                        + (adminNotes != null && !adminNotes.isBlank()
                            ? "<p>Sebab penolakan: " + escapeHtml(adminNotes) + "</p>" : "")
                        + "<p>Sila hubungi pentadbir jika anda memerlukan maklumat lanjut.</p>"
                        + "<p>Terima kasih.</p>";
            } else {
                return; // No email for other statuses
            }

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            boolean sent = emailUtil.sendHtml(emailAddr, subject, bodyContent);
            if (sent) {
                LOGGER.info("Status email sent to " + emailAddr + " for application PPP" + String.format("%03d", applicationId));
            }
        } catch (Exception e) {
            // Email failure should not block the admin action
            LOGGER.warning("Failed to send status email for application PPP" + String.format("%03d", applicationId) + ": " + e.getMessage());
        }
    }

    private void sendInProgressPresentationEmail(HttpServletRequest request, Connection conn,
            int applicationId, String presentationDate, String presentationTime,
            String presentationVenue, String presentationMessage) {
        String smtpHost = getContextParam(request, "smtp.host", "");
        if (smtpHost.isBlank()) return; // SMTP not configured

        try {
            String emailAddr = null;
            String fullName = null;
            String product = null;
            String sql = "SELECT u.email, u.full_name, a.product_name "
                    + "FROM applications a JOIN users u ON u.id = a.user_id WHERE a.id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, applicationId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        emailAddr = rs.getString("email");
                        fullName = rs.getString("full_name");
                        product = rs.getString("product_name");
                    }
                }
            }

            if (emailAddr == null || emailAddr.isBlank()) return;

            int smtpPort = Integer.parseInt(getContextParam(request, "smtp.port", "587"));
            boolean smtpAuth = Boolean.parseBoolean(getContextParam(request, "smtp.auth", "true"));
            boolean smtpTls = Boolean.parseBoolean(getContextParam(request, "smtp.tls", "true"));
            String smtpUser = getContextParam(request, "smtp.username", "");
            String smtpPass = getContextParam(request, "smtp.password", "");
            String smtpFrom = getContextParam(request, "smtp.from", smtpUser);

            String generatedMessage = "Pemohon dimaklumkan untuk bersedia dan menghadiri sesi Pembentangan Produk Air yang didaftarkan."
                    + "\nTarikh: " + presentationDate
                    + "\nMasa: " + presentationTime
                    + "\nTempat: " + presentationVenue;
            String finalMessage = (presentationMessage == null || presentationMessage.isBlank())
                    ? generatedMessage
                    : presentationMessage;

            String subject = "Makluman Pembentangan Permohonan PPP"
                    + String.format("%03d", applicationId) + " - SPPA";
            String bodyContent = "<p>Salam " + escapeHtml(fullName) + ",</p>"
                    + "<p>Permohonan anda untuk produk <strong>" + escapeHtml(product)
                    + "</strong> (No. Rujukan: PPP" + String.format("%03d", applicationId)
                    + ") kini dalam status <strong>DALAM PROSES</strong>.</p>"
                    + "<p>Berikut adalah makluman pembentangan:</p>"
                    + "<pre style=\"font-family:Arial,Helvetica,sans-serif;white-space:pre-wrap;margin:0;padding:12px;border:1px solid #d7dbe0;border-radius:8px;background:#f8fafc;\">"
                    + escapeHtml(finalMessage)
                    + "</pre>"
                    + "<p>Sila pastikan kehadiran mengikut maklumat di atas.</p>"
                    + "<p>Terima kasih.</p>";

            EmailUtil emailUtil = new EmailUtil(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom, smtpAuth, smtpTls);
            boolean sent = emailUtil.sendHtml(emailAddr, subject, bodyContent);
            if (sent) {
                LOGGER.info("In-progress presentation email sent to " + emailAddr
                        + " for application PPP" + String.format("%03d", applicationId));
            }
        } catch (Exception e) {
            // Email failure should not block admin action
            LOGGER.warning("Failed to send in-progress email for application PPP"
                    + String.format("%03d", applicationId) + ": " + e.getMessage());
        }
    }

    private String getContextParam(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getServletContext().getInitParameter(name);
        return (value == null || value.isBlank()) ? defaultValue : value.trim();
    }

    private String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}
