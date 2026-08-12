package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas DirectorApplicationServlet.
 * Dipanggil melalui URL:  /director/application (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
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
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;

public class DirectorApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(DirectorApplicationServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null || !"DIRECTOR".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Integer applicationId = parseInteger(request.getParameter("application_id"));
        if (applicationId == null) {
            response.sendRedirect(request.getContextPath() + "/dashboard?director_error=missing_application");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            DashboardDataService.ensureApplicationWorkflowSchema(conn);
            Map<String, Object> application = loadDirectorApplication(conn, applicationId);
            if (application == null) {
                response.sendRedirect(request.getContextPath() + "/dashboard?director_error=missing_application");
                return;
            }

            String status = String.valueOf(application.getOrDefault("status", "")).trim().toUpperCase(Locale.ROOT);
            if (!"MENUNGGU_TINDAKAN_PENGARAH".equals(status)) {
                response.sendRedirect(request.getContextPath() + "/dashboard?director_error=invalid_state");
                return;
            }

            request.setAttribute("application", application);
            request.setAttribute("director_review_type", application.getOrDefault("director_review_type", "INITIAL"));
            request.getRequestDispatcher("/director-application.jsp").forward(request, response);
        } catch (SQLException ex) {
            LOGGER.warning("Failed to load director application " + applicationId + ": " + ex.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Gagal memuatkan permohonan.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null || !"DIRECTOR".equals(session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String directorAction = trim(request.getParameter("director_action"));
        Integer applicationId = parseInteger(request.getParameter("application_id"));
        if (applicationId == null) {
            response.sendRedirect(request.getContextPath() + "/dashboard?director_error=missing_application");
            return;
        }

        DashboardServlet.processDirectorAction(request, response, session, directorAction,
                "/director/application?application_id=" + applicationId);
    }

    private Map<String, Object> loadDirectorApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, a.status, a.director_review_type, a.company_name, a.company_address, a.contact_number, a.email AS supplier_email, "
                + "a.product_name, a.product_category, a.product_description, a.submitted_at, a.reviewed_at, a.reviewed_by, a.admin_notes, "
                + "u.full_name AS user_full_name, u.email AS user_email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_address, ad.supplier_phone, "
                + "ad.manufacturer_name, ad.manufacturer_address, ad.manufacturer_phone, "
                + "ad.principal_name, ad.principal_address, ad.principal_phone, "
                + "ad.standard_name, ad.certification_license, ad.certification_valid_until, ad.test_report_reference, ad.test_report_date, ad.warranty_years, "
                + "ad.sabah_rep_name, ad.sabah_rep_address, ad.sabah_rep_phone, ad.declaration_name, ad.declaration_position "
                + "FROM applications a "
                + "LEFT JOIN users u ON u.id = a.user_id "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ? LIMIT 1";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> application = new HashMap<>();
                application.put("id", rs.getInt("id"));
                application.put("status", trim(rs.getString("status")));
                application.put("director_review_type", trim(rs.getString("director_review_type")));
                application.put("company_name", trim(rs.getString("company_name")));
                application.put("company_address", trim(rs.getString("company_address")));
                application.put("contact_number", trim(rs.getString("contact_number")));
                application.put("supplier_email", trim(rs.getString("supplier_email")));
                application.put("product_name", trim(rs.getString("product_name")));
                application.put("product_category", trim(rs.getString("product_category")));
                application.put("product_description", trim(rs.getString("product_description")));
                application.put("submitted_at", rs.getTimestamp("submitted_at"));
                application.put("reviewed_at", rs.getTimestamp("reviewed_at"));
                application.put("reviewed_by", rs.getObject("reviewed_by"));
                application.put("admin_notes", trim(rs.getString("admin_notes")));
                application.put("user_full_name", trim(rs.getString("user_full_name")));
                application.put("user_email", trim(rs.getString("user_email")));
                application.put("application_type", trim(rs.getString("application_type")));
                application.put("supplier_name", trim(rs.getString("supplier_name")));
                application.put("supplier_address", trim(rs.getString("supplier_address")));
                application.put("supplier_phone", trim(rs.getString("supplier_phone")));
                application.put("manufacturer_name", trim(rs.getString("manufacturer_name")));
                application.put("manufacturer_address", trim(rs.getString("manufacturer_address")));
                application.put("manufacturer_phone", trim(rs.getString("manufacturer_phone")));
                application.put("principal_name", trim(rs.getString("principal_name")));
                application.put("principal_address", trim(rs.getString("principal_address")));
                application.put("principal_phone", trim(rs.getString("principal_phone")));
                application.put("standard_name", trim(rs.getString("standard_name")));
                application.put("certification_license", trim(rs.getString("certification_license")));
                application.put("certification_valid_until", rs.getDate("certification_valid_until"));
                application.put("test_report_reference", trim(rs.getString("test_report_reference")));
                application.put("test_report_date", rs.getDate("test_report_date"));
                application.put("warranty_years", rs.getObject("warranty_years"));
                application.put("sabah_rep_name", trim(rs.getString("sabah_rep_name")));
                application.put("sabah_rep_address", trim(rs.getString("sabah_rep_address")));
                application.put("sabah_rep_phone", trim(rs.getString("sabah_rep_phone")));
                application.put("declaration_name", trim(rs.getString("declaration_name")));
                application.put("declaration_position", trim(rs.getString("declaration_position")));
                return application;
            }
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
        return value == null ? "" : value.trim();
    }
}

