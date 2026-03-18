package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AdminApplicationServlet extends HttpServlet {
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
            request.setAttribute("application", loadApplication(conn, Integer.parseInt(applicationId)));
            request.setAttribute("applicationDetail", loadApplicationDetail(conn, Integer.parseInt(applicationId)));
            request.setAttribute("documents", loadDocuments(conn, Integer.parseInt(applicationId)));
            request.getRequestDispatcher("/admin-application.jsp").forward(request, response);
        } catch (SQLException e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan permohonan");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        int applicationId = Integer.parseInt(request.getParameter("id"));
        String action = request.getParameter("action");
        String adminNotes = request.getParameter("admin_notes");

        try (Connection conn = DatabaseConfig.getConnection()) {
            if ("approve".equals(action)) {
                updateApplicationStatus(conn, applicationId, "APPROVED", adminNotes);
            } else if ("reject".equals(action)) {
                updateApplicationStatus(conn, applicationId, "REJECTED", adminNotes);
            } else if ("suspend_application".equals(action)) {
                updateApplicationStatus(conn, applicationId, "SUSPENDED", adminNotes);
            } else if ("suspend_user".equals(action)) {
                suspendUserByApplication(conn, applicationId, adminNotes);
            }
            response.sendRedirect(request.getContextPath() + "/admin/application?id=" + applicationId + "&updated=1");
        } catch (SQLException e) {
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

    private Map<String, Object> loadApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.*, u.full_name, u.email AS user_email, u.status AS user_status FROM applications a JOIN users u ON u.id = a.user_id WHERE a.id = ?";
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

    private void updateApplicationStatus(Connection conn, int applicationId, String status, String adminNotes) throws SQLException {
        String sql = "UPDATE applications SET status = ?, admin_notes = ?, reviewed_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setString(2, adminNotes);
            stmt.setInt(3, applicationId);
            stmt.executeUpdate();
        }
    }

    private void suspendUserByApplication(Connection conn, int applicationId, String adminNotes) throws SQLException {
        String sql = "UPDATE users u JOIN applications a ON a.user_id = u.id SET u.status = 'SUSPENDED', a.admin_notes = ?, a.reviewed_at = CURRENT_TIMESTAMP WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, adminNotes);
            stmt.setInt(2, applicationId);
            stmt.executeUpdate();
        }
    }
}