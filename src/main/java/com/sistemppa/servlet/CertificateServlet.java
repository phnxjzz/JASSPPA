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
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Serves the printable Perakuan Pendaftaran (Registration Certificate) page.
 * Accessible by: ADMIN (any), USER (own applications only).
 */
public class CertificateServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(CertificateServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer sessionUserId = (Integer) session.getAttribute("user_id");
        String role = (String) session.getAttribute("role");
        boolean isAdmin = "ADMIN".equals(role);

        String idParam = request.getParameter("id");
        Integer applicationId = parseInteger(idParam);
        if (applicationId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID permohonan tidak sah");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.ensureCertificateColumns(conn);
            Map<String, Object> app = loadCertificateData(conn, applicationId);
            if (app == null || app.isEmpty()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Perakuan tidak ditemui");
                return;
            }

            // Access control: only admin or the application owner
            int appUserId = ((Number) app.get("user_id")).intValue();
            if (!isAdmin && sessionUserId != appUserId) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses ditolak");
                return;
            }

            // Must be APPROVED with certificate_number
            if (!"APPROVED".equals(app.get("status")) || app.get("certificate_number") == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Perakuan belum dikeluarkan untuk permohonan ini");
                return;
            }

            request.setAttribute("certApp", app);
            request.getRequestDispatcher("/certificate.jsp").forward(request, response);

        } catch (SQLException e) {
            LOGGER.severe("Failed to load certificate: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan perakuan");
        }
    }

    private Map<String, Object> loadCertificateData(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, a.user_id, a.product_name, a.product_category, a.company_name, "
                + "a.company_address, a.contact_number, a.email, a.status, "
                + "a.certificate_number, a.issued_at, a.valid_until, a.reviewed_at, "
                + "u.full_name AS applicant_name, u.email AS user_email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_address, "
                + "ad.standard_name, ad.certification_license "
                + "FROM applications a "
                + "JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("user_id", rs.getInt("user_id"));
                row.put("product_name", rs.getString("product_name"));
                row.put("product_category", rs.getString("product_category"));
                row.put("company_name", rs.getString("company_name"));
                row.put("company_address", rs.getString("company_address"));
                row.put("contact_number", rs.getString("contact_number"));
                row.put("email", rs.getString("email"));
                row.put("status", rs.getString("status"));
                row.put("certificate_number", rs.getString("certificate_number"));
                row.put("issued_at", rs.getDate("issued_at"));
                row.put("valid_until", rs.getDate("valid_until"));
                row.put("reviewed_at", rs.getTimestamp("reviewed_at"));
                row.put("applicant_name", rs.getString("applicant_name"));
                row.put("user_email", rs.getString("user_email"));
                row.put("application_type", rs.getString("application_type"));
                row.put("supplier_name", rs.getString("supplier_name"));
                row.put("supplier_address", rs.getString("supplier_address"));
                row.put("standard_name", rs.getString("standard_name"));
                row.put("certification_license", rs.getString("certification_license"));
                return row;
            }
        }
    }

    private Integer parseInteger(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
