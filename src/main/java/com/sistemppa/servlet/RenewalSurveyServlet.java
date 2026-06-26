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
import java.util.logging.Logger;

/**
 * Digital KSPP survey form for renewal applications.
 * URL: GET /renewal-form?id={applicationId}
 */
public class RenewalSurveyServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(RenewalSurveyServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String role = (String) session.getAttribute("role");
        boolean isPrivileged = "ADMIN".equalsIgnoreCase(role) || "KPP".equalsIgnoreCase(role);

        if (!isPrivileged) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Akses borang ini hanya untuk Admin/KPP");
            return;
        }

        Integer applicationId = parseInteger(request.getParameter("id"));
        if (applicationId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID permohonan tidak sah");
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            Map<String, Object> app = loadApplication(conn, applicationId);
            if (app == null || app.isEmpty()) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Permohonan tidak ditemui");
                return;
            }

            if (!"PEMBAHARUAN".equalsIgnoreCase(str(app.get("application_type")))) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND,
                        "Borang KSPP hanya untuk permohonan pembaharuan");
                return;
            }

            request.setAttribute("renewalApp", app);
            request.setAttribute("questions", buildQuestions());
            request.getRequestDispatcher("/renewal-survey.jsp").forward(request, response);

        } catch (SQLException e) {
            LOGGER.severe("Failed to load digital renewal form: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Gagal memuatkan borang KSPP digital");
        }
    }

    private Map<String, Object> loadApplication(Connection conn, int applicationId) throws SQLException {
        String sql = "SELECT a.id, a.user_id, a.product_name, a.product_description, a.company_name, "
                + "a.contact_number, a.email, "
                + "ad.application_type, ad.supplier_name, ad.supplier_phone, ad.standard_name, ad.certification_license "
                + "FROM applications a "
                + "LEFT JOIN application_details ad ON ad.application_id = a.id "
                + "WHERE a.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                String summary = str(rs.getString("product_description"));
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getInt("id"));
                row.put("user_id", rs.getInt("user_id"));
                row.put("application_type", rs.getString("application_type"));
                row.put("product_name", rs.getString("product_name"));
                row.put("product_description", extractFieldFromSummary(summary, "Perihal Produk:"));
                row.put("brand", extractFieldFromSummary(summary, "Jenama:"));
                row.put("company_name", rs.getString("company_name"));
                row.put("contact_number", rs.getString("contact_number"));
                row.put("email", rs.getString("email"));
                row.put("supplier_name", firstNonBlank(rs.getString("supplier_name"), rs.getString("company_name")));
                row.put("supplier_phone", firstNonBlank(rs.getString("supplier_phone"), rs.getString("contact_number")));
                row.put("standard_name", rs.getString("standard_name"));
                row.put("certification_license", rs.getString("certification_license"));
                return row;
            }
        }
    }

    private String extractFieldFromSummary(String summary, String fieldLabel) {
        if (summary == null || summary.isBlank() || fieldLabel == null || fieldLabel.isBlank()) {
            return "";
        }
        int idx = summary.indexOf(fieldLabel);
        if (idx < 0) {
            return "";
        }
        String tail = summary.substring(idx + fieldLabel.length()).trim();
        int pipeIdx = tail.indexOf('|');
        if (pipeIdx >= 0) {
            tail = tail.substring(0, pipeIdx);
        }
        int newlineIdx = tail.indexOf('\n');
        if (newlineIdx >= 0) {
            tail = tail.substring(0, newlineIdx);
        }
        return "-".equals(tail.trim()) ? "" : tail.trim();
    }

    private String firstNonBlank(String primary, String secondary) {
        return !str(primary).isBlank() ? str(primary) : str(secondary);
    }

    private Integer parseInteger(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private List<String> buildQuestions() {
        List<String> questions = new ArrayList<>();
        questions.add("Adakah Perakuan Pendaftaran Pembekal dan Produk JA Sabah masih sah?");
        questions.add("Adakah Surat Pelantikan Pembekal Produk dari syarikat prinsipal / pemilik produk masih sah?");
        questions.add("Adakah dokumen jaminan produk masih sah?");
        questions.add("Adakah sokongan teknikal (perkhidmatan selepas jualan) tersedia di Sabah?");
        questions.add("Adakah mudah dihubungi pada bila-bila masa?");
        questions.add("Adakah jadual penghantaran produk ke lokasi dipatuhi?");
        questions.add("Adakah Prosedur Operasi Standard (SOP) untuk penghantaran dan pengendalian produk dari kilang ke lokasi tapak bina dipatuhi?");
        questions.add("Adakah produk disimpan di lokasi yang sesuai dan tempat selamat seperti yang diarahkan?");
        questions.add("Adakah undang-undang dan peraturan yang terpakai, berkelakuan beretika dan berintegriti dipatuhi?");
        questions.add("Adakah amalan pelaksanaan kerja mengurangkan kesan / impak negatif terhadap alam sekitar dipatuhi?");
        questions.add("Adakah aspek keselamatan dan kesihatan pekerjaan dipatuhi?");
        questions.add("Adakah pemasangan produk diselia / dipantau sehingga selesai?");
        questions.add("Adakah pengujian dan pentauliahan produk disaksikan sehingga selesai?");
        questions.add("Adakah produk yang rosak diganti ataupun dibaiki dengan segera?");
        questions.add("Adakah Manual Operasi diberikan?");
        questions.add("Adakah latihan operasi dan senggara produk diberikan?");
        questions.add("Adakah produk yang dibekalkan memenuhi spesifikasi yang diiktirafkan, berfungsi dengan baik dan tidak ada kecacatan?");
        questions.add("Adakah Sijil Penentukuran (Calibration) masih sah? (jika berkenaan)");
        questions.add("Adakah produk mempunyai rekod prestasi yang tidak memuaskan / rosak dalam tempoh tanggungan kecacatan?");
        questions.add("Adakah produk mempunyai rekod prestasi dalam tempoh lima (5) tahun selepas dipasang? Jika ya, sila sertakan.");
        return questions;
    }

    private String str(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }
}
