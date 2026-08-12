package com.sistemppa.servlet;

/**
 * NOTA ALIRAN KOD:
 * Fail ini pegang logik utama untuk kelas StaffComplaintServlet.
 * Dipanggil melalui URL:  /staff/complaints (rujuk WEB-INF/web.xml).
 * Tujuan komen ini: bagi orang seterusnya cepat faham aliran tanpa perlu teka dari mana code ni masuk.
 */
import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Locale;
import java.util.logging.Logger;

public class StaffComplaintServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(StaffComplaintServlet.class.getName());

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String role = String.valueOf(session.getAttribute("role") == null ? "" : session.getAttribute("role"));
        String email = String.valueOf(session.getAttribute("email") == null ? "" : session.getAttribute("email"));

        boolean roleAllowed = "ADMIN".equals(role) || "STAFF".equals(role);
        if (!roleAllowed || !isGovernmentEmail(email)) {
            response.sendRedirect(request.getContextPath() + "/dashboard?staff_complaint=forbidden#aduan-digital");
            return;
        }

        String department = trim(request.getParameter("department"));
        String complaintCategory = trim(request.getParameter("complaint_category"));
        String complaintTitle = trim(request.getParameter("complaint_title"));
        String complaintDetails = trim(request.getParameter("complaint_details"));
        String incidentDateStr = trim(request.getParameter("incident_date"));
        String incidentLocation = trim(request.getParameter("incident_location"));
        String urgency = trim(request.getParameter("urgency"));
        String preferredContact = trim(request.getParameter("preferred_contact"));
        String sectionEQ1 = trim(request.getParameter("section_e_q1"));
        String sectionEQ2 = trim(request.getParameter("section_e_q2"));
        String sectionEQ3 = trim(request.getParameter("section_e_q3"));
        String sectionEQ4 = trim(request.getParameter("section_e_q4"));
        String sectionEQ5 = trim(request.getParameter("section_e_q5"));
        String sectionEQ6 = trim(request.getParameter("section_e_q6"));
        String sectionENote1 = trim(request.getParameter("section_e_note1"));
        String sectionENote2 = trim(request.getParameter("section_e_note2"));
        String sectionENote3 = trim(request.getParameter("section_e_note3"));
        String sectionENote4 = trim(request.getParameter("section_e_note4"));
        String sectionENote5 = trim(request.getParameter("section_e_note5"));
        String sectionENote6 = trim(request.getParameter("section_e_note6"));
        String renewalSatisfaction = trim(request.getParameter("renewal_satisfaction"));
        String renewalReview = trim(request.getParameter("renewal_review"));

        if (department.isBlank() || complaintCategory.isBlank() || complaintTitle.isBlank()
                || complaintDetails.isBlank() || urgency.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/dashboard?staff_complaint=invalid#aduan-digital");
            return;
        }

        if (sectionEQ1.isBlank() || sectionEQ2.isBlank() || sectionEQ3.isBlank()
                || sectionEQ4.isBlank() || sectionEQ5.isBlank() || renewalSatisfaction.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/dashboard?staff_complaint=invalid#aduan-digital");
            return;
        }

        if ("TIDAK_BERPUAS_HATI".equals(renewalSatisfaction) && renewalReview.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/dashboard?staff_complaint=invalid#aduan-digital");
            return;
        }

        String enrichedComplaintDetails = complaintDetails
                + "\n\n===== BAHAGIAN E ====="
                + "\nQ1: " + safe(sectionEQ1) + " | Catatan: " + safe(sectionENote1)
                + "\nQ2: " + safe(sectionEQ2) + " | Catatan: " + safe(sectionENote2)
                + "\nQ3: " + safe(sectionEQ3) + " | Catatan: " + safe(sectionENote3)
                + "\nQ4: " + safe(sectionEQ4) + " | Catatan: " + safe(sectionENote4)
                + "\nQ5: " + safe(sectionEQ5) + " | Catatan: " + safe(sectionENote5)
                + "\nQ6: " + safe(sectionEQ6) + " | Catatan: " + safe(sectionENote6)
                + "\nPenilaian Pembaharuan: " + safe(renewalSatisfaction)
                + "\nUlasan Pembaharuan: " + safe(renewalReview);

        Integer staffUserId = (Integer) session.getAttribute("user_id");
        String staffUsername = String.valueOf(session.getAttribute("username") == null ? "" : session.getAttribute("username"));

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureStaffComplaintTable(conn);

            String sql = "INSERT INTO staff_complaints "
                    + "(staff_user_id, staff_username, staff_email, department, complaint_category, complaint_title, "
                    + "complaint_details, incident_date, incident_location, urgency, preferred_contact, status) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'NEW')";

            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, staffUserId == null ? 0 : staffUserId);
                stmt.setString(2, staffUsername);
                stmt.setString(3, email);
                stmt.setString(4, department);
                stmt.setString(5, complaintCategory);
                stmt.setString(6, complaintTitle);
                stmt.setString(7, enrichedComplaintDetails);
                if (incidentDateStr.isBlank()) {
                    stmt.setNull(8, java.sql.Types.DATE);
                } else {
                    stmt.setDate(8, Date.valueOf(incidentDateStr));
                }
                stmt.setString(9, incidentLocation.isBlank() ? null : incidentLocation);
                stmt.setString(10, urgency);
                stmt.setString(11, preferredContact.isBlank() ? null : preferredContact);
                stmt.executeUpdate();
            }
        } catch (SQLException | IllegalArgumentException e) {
            LOGGER.severe("Failed to save staff complaint: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/dashboard?staff_complaint=error#aduan-digital");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/dashboard?staff_complaint=submitted#aduan-digital");
    }

    private void ensureStaffComplaintTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS staff_complaints ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "staff_user_id INT NOT NULL, "
                + "staff_username VARCHAR(100) NOT NULL, "
                + "staff_email VARCHAR(255) NOT NULL, "
                + "department VARCHAR(150) NOT NULL, "
                + "complaint_category VARCHAR(100) NOT NULL, "
                + "complaint_title VARCHAR(200) NOT NULL, "
                + "complaint_details TEXT NOT NULL, "
                + "incident_date DATE NULL, "
                + "incident_location VARCHAR(255) NULL, "
                + "urgency VARCHAR(30) NOT NULL, "
                + "preferred_contact VARCHAR(120) NULL, "
                + "status VARCHAR(20) NOT NULL DEFAULT 'NEW', "
                + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
                + ")";
        try (PreparedStatement stmt = conn.prepareStatement(ddl)) {
            stmt.execute();
        }
    }

    private boolean isGovernmentEmail(String value) {
        if (value == null) {
            return false;
        }
        String email = value.trim().toLowerCase(Locale.ROOT);
        return email.endsWith(".gov.my");
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String safe(String value) {
        return value == null || value.isBlank() ? "-" : value;
    }
}

