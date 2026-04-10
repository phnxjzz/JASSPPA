package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import com.sistemppa.service.DashboardDataService;
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

        Integer applicationIdValue = parseInteger(request.getParameter("id"));
        if (applicationIdValue == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID permohonan tidak sah");
            return;
        }

        int applicationId = applicationIdValue;
        String action = request.getParameter("action");
        String adminNotes = trim(request.getParameter("admin_notes"));
        String validUntilStr = trim(request.getParameter("valid_until"));
        Integer adminUserId = (Integer) request.getSession(false).getAttribute("user_id");

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureApplicationArchiveTable(conn);
            DashboardDataService.ensureCertificateColumns(conn);

            if ("reject".equals(action) && (adminNotes == null || adminNotes.isBlank())) {
                request.setAttribute("error", "Sebab penolakan wajib diisi sebelum permohonan ditolak.");
                renderApplicationPage(conn, request, response, applicationId, "");
                return;
            }

            if ("approve".equals(action)) {
                updateApplicationStatus(conn, applicationId, "APPROVED", adminNotes, adminUserId, validUntilStr);
            } else if ("reject".equals(action)) {
                updateApplicationStatus(conn, applicationId, "REJECTED", adminNotes, adminUserId, null);
            } else if ("suspend_application".equals(action)) {
                updateApplicationStatus(conn, applicationId, "SUSPENDED", adminNotes, adminUserId, null);
            } else if ("suspend_user".equals(action)) {
                suspendUserByApplication(conn, applicationId, adminNotes);
            } else if ("archive".equals(action)) {
                if (!canArchiveApplication(conn, applicationId)) {
                    request.setAttribute("error", "Permohonan hanya boleh diarkib selepas diambil tindakan (APPROVED/REJECTED/SUSPENDED). ");
                    renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    return;
                }
                archiveApplication(conn, applicationId, adminNotes, adminUserId);
            } else if ("unarchive".equals(action)) {
                if (!isArchived(conn, applicationId)) {
                    request.setAttribute("error", "Permohonan ini belum diarkib.");
                    renderApplicationPage(conn, request, response, applicationId, adminNotes);
                    return;
                }
                unarchiveApplication(conn, applicationId);
            } else {
                request.setAttribute("error", "Tindakan pentadbir tidak sah.");
                renderApplicationPage(conn, request, response, applicationId, adminNotes);
                return;
            }
            response.sendRedirect(request.getContextPath() + "/admin/application?id=" + applicationId + "&updated=1");
        } catch (SQLException e) {
            LOGGER.severe("Failed to update admin application review: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal mengemas kini permohonan");
        }
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
                message = "Permohonan #" + applicationId + " anda telah DILULUSKAN. Perakuan Pendaftaran " + certRef + " telah dikeluarkan.";
                type = "SUCCESS";
            } else if ("REJECTED".equals(status)) {
                message = "Permohonan #" + applicationId + " anda telah DITOLAK."
                        + (adminNotes != null && !adminNotes.isBlank() ? " Sebab: " + adminNotes : "");
                type = "ERROR";
            } else if ("SUSPENDED".equals(status)) {
                message = "Permohonan #" + applicationId + " anda telah DIGANTUNG.";
                type = "WARNING";
            } else {
                message = "Status permohonan #" + applicationId + " telah dikemas kini kepada " + status + ".";
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
        return value !=null ? value.trim() : null;
    
    }
}
