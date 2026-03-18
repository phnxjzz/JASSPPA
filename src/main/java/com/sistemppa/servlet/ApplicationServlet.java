package com.sistemppa.servlet;

import com.sistemppa.config.DatabaseConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Logger;

@MultipartConfig(maxFileSize = 15 * 1024 * 1024, maxRequestSize = 120 * 1024 * 1024)
public class ApplicationServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(ApplicationServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = requireUserSession(request, response);
        if (session == null) {
            return;
        }

        request.setAttribute("requiredDocuments", buildRequiredDocuments());
        request.getRequestDispatcher("/application-form.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = requireUserSession(request, response);
        if (session == null) {
            return;
        }

        request.setCharacterEncoding("UTF-8");
        Integer userId = (Integer) session.getAttribute("user_id");
        String applicationType = trim(request.getParameter("application_type"));
        String supplierName = trim(request.getParameter("supplier_name"));
        String productName = trim(request.getParameter("product_name"));
        String productCategory = trim(request.getParameter("product_category"));

        if (supplierName.isEmpty() || productName.isEmpty() || productCategory.isEmpty() || applicationType.isEmpty()) {
            request.setAttribute("error", "Sila lengkapkan medan wajib borang PPP1.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DatabaseConfig.getConnection()) {
            ensureOnlineApplicationSchema(conn);
            conn.setAutoCommit(false);

            int applicationId = insertApplication(conn, userId, request);
            insertApplicationDetails(conn, applicationId, request);
            saveUploadedDocuments(conn, applicationId, request);
            insertAuditLog(conn, userId, request.getRemoteAddr(), applicationId);

            conn.commit();
            response.sendRedirect(request.getContextPath() + "/applications/new?success=1&id=" + applicationId);
        } catch (SQLException e) {
            LOGGER.severe("Failed to save application: " + e.getMessage());
            request.setAttribute("error", "Permohonan tidak berjaya disimpan. Sila cuba lagi.");
            request.setAttribute("requiredDocuments", buildRequiredDocuments());
            request.getRequestDispatcher("/application-form.jsp").forward(request, response);
        }
    }

    private HttpSession requireUserSession(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return null;
        }
        return session;
    }

    private int insertApplication(Connection conn, Integer userId, HttpServletRequest request) throws SQLException {
        String sql = "INSERT INTO applications (user_id, product_name, product_category, product_description, company_name, company_address, contact_number, email, status, submitted_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, userId);
            stmt.setString(2, trim(request.getParameter("product_name")));
            stmt.setString(3, trim(request.getParameter("product_category")));
            stmt.setString(4, buildApplicationSummary(request));
            stmt.setString(5, trim(request.getParameter("supplier_name")));
            stmt.setString(6, trim(request.getParameter("supplier_address")));
            stmt.setString(7, trim(request.getParameter("supplier_phone")));
            stmt.setString(8, trim(request.getParameter("supplier_email")));
            stmt.setTimestamp(9, Timestamp.valueOf(LocalDateTime.now()));
            stmt.executeUpdate();

            try (ResultSet keys = stmt.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
        }

        throw new SQLException("Application ID not generated.");
    }

    private void insertApplicationDetails(Connection conn, int applicationId, HttpServletRequest request) throws SQLException {
        String sql = "INSERT INTO application_details (application_id, application_type, supplier_name, supplier_address, supplier_phone, manufacturer_name, manufacturer_address, manufacturer_phone, principal_name, principal_address, principal_phone, standard_name, certification_license, certification_valid_until, test_report_reference, test_report_date, warranty_years, sabah_rep_name, sabah_rep_address, sabah_rep_phone, declaration_name, declaration_position) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, applicationId);
            stmt.setString(2, trim(request.getParameter("application_type")));
            stmt.setString(3, trim(request.getParameter("supplier_name")));
            stmt.setString(4, trim(request.getParameter("supplier_address")));
            stmt.setString(5, trim(request.getParameter("supplier_phone")));
            stmt.setString(6, trim(request.getParameter("manufacturer_name")));
            stmt.setString(7, trim(request.getParameter("manufacturer_address")));
            stmt.setString(8, trim(request.getParameter("manufacturer_phone")));
            stmt.setString(9, trim(request.getParameter("principal_name")));
            stmt.setString(10, trim(request.getParameter("principal_address")));
            stmt.setString(11, trim(request.getParameter("principal_phone")));
            stmt.setString(12, trim(request.getParameter("standard_name")));
            stmt.setString(13, trim(request.getParameter("certification_license")));
            stmt.setDate(14, parseDate(request.getParameter("certification_valid_until")));
            stmt.setString(15, trim(request.getParameter("test_report_reference")));
            stmt.setDate(16, parseDate(request.getParameter("test_report_date")));
            stmt.setBigDecimal(17, parseDecimal(request.getParameter("warranty_years")));
            stmt.setString(18, trim(request.getParameter("sabah_rep_name")));
            stmt.setString(19, trim(request.getParameter("sabah_rep_address")));
            stmt.setString(20, trim(request.getParameter("sabah_rep_phone")));
            stmt.setString(21, trim(request.getParameter("declaration_name")));
            stmt.setString(22, trim(request.getParameter("declaration_position")));
            stmt.executeUpdate();
        }
    }

    private void saveUploadedDocuments(Connection conn, int applicationId, HttpServletRequest request) throws SQLException, IOException, ServletException {
        Path baseDir = Path.of(System.getProperty("catalina.base", System.getProperty("user.dir")), "uploads", "sistemppa", String.valueOf(applicationId));
        Files.createDirectories(baseDir);

        String sql = "INSERT INTO application_documents (application_id, document_type, original_filename, stored_filename, stored_path, content_type, file_size) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (Map.Entry<String, String> entry : buildRequiredDocuments().entrySet()) {
                Part part = request.getPart(entry.getKey());
                if (part == null || part.getSize() == 0) {
                    continue;
                }

                String originalName = extractSubmittedFileName(part);
                String safeName = UUID.randomUUID() + "-" + originalName.replaceAll("[^a-zA-Z0-9._-]", "_");
                Path storedFile = baseDir.resolve(safeName);
                Files.copy(part.getInputStream(), storedFile, StandardCopyOption.REPLACE_EXISTING);

                stmt.setInt(1, applicationId);
                stmt.setString(2, entry.getKey());
                stmt.setString(3, originalName);
                stmt.setString(4, safeName);
                stmt.setString(5, storedFile.toString());
                stmt.setString(6, part.getContentType());
                stmt.setLong(7, part.getSize());
                stmt.addBatch();
            }
            stmt.executeBatch();
        }
    }

    private void insertAuditLog(Connection conn, Integer userId, String ipAddress, int applicationId) throws SQLException {
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, "CREATE_APPLICATION");
            stmt.setString(3, "Permohonan online PPP1 dihantar. ID: " + applicationId);
            stmt.setString(4, ipAddress);
            stmt.executeUpdate();
        }
    }

    private void ensureOnlineApplicationSchema(Connection conn) throws SQLException {
        try (Statement stmt = conn.createStatement()) {
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS application_details ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY,"
                    + "application_id INT NOT NULL,"
                    + "application_type ENUM('BAHARU','PEMBAHARUAN') NOT NULL,"
                    + "supplier_name VARCHAR(255) NOT NULL,"
                    + "supplier_address TEXT NOT NULL,"
                    + "supplier_phone VARCHAR(50),"
                    + "manufacturer_name VARCHAR(255),"
                    + "manufacturer_address TEXT,"
                    + "manufacturer_phone VARCHAR(50),"
                    + "principal_name VARCHAR(255),"
                    + "principal_address TEXT,"
                    + "principal_phone VARCHAR(50),"
                    + "standard_name VARCHAR(255),"
                    + "certification_license VARCHAR(255),"
                    + "certification_valid_until DATE,"
                    + "test_report_reference VARCHAR(255),"
                    + "test_report_date DATE,"
                    + "warranty_years DECIMAL(5,2),"
                    + "sabah_rep_name VARCHAR(255),"
                    + "sabah_rep_address TEXT,"
                    + "sabah_rep_phone VARCHAR(50),"
                    + "declaration_name VARCHAR(255),"
                    + "declaration_position VARCHAR(255),"
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                    + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,"
                    + "UNIQUE KEY uniq_application_detail (application_id),"
                    + "FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE)"
            );
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS application_documents ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY,"
                    + "application_id INT NOT NULL,"
                    + "document_type VARCHAR(100) NOT NULL,"
                    + "original_filename VARCHAR(255) NOT NULL,"
                    + "stored_filename VARCHAR(255) NOT NULL,"
                    + "stored_path TEXT NOT NULL,"
                    + "content_type VARCHAR(100),"
                    + "file_size BIGINT NOT NULL DEFAULT 0,"
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                    + "INDEX idx_application_id (application_id),"
                    + "INDEX idx_document_type (document_type),"
                    + "FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE)"
            );
        }
    }

    private Map<String, String> buildRequiredDocuments() {
        Map<String, String> docs = new LinkedHashMap<>();
        docs.put("official_application_letter", "Surat permohonan rasmi kepada Pengarah JANS");
        docs.put("principal_appointment_letter", "Surat pelantikan pembekal dari prinsipal/pemilik produk");
        docs.put("renewal_certificate", "Salinan sijil/perakuan lama bagi pembaharuan");
        docs.put("certification_license_file", "Lesen persijilan produk (SIRIM/IKRAM/dll)");
        docs.put("test_report_file", "Laporan pengujian yang masih sah");
        docs.put("brochure_catalogue", "Brosur atau katalog produk");
        docs.put("price_list", "Senarai harga semasa");
        docs.put("product_benefit_summary", "Penerangan fungsi, faedah dan kelebihan produk");
        docs.put("project_reference", "Senarai rujukan projek / rekod prestasi produk");
        docs.put("recommendation_letter", "Surat pengesahan atau rekomendasi pengguna, jika ada");
        docs.put("sop_document", "SOP pengendalian dan penyimpanan produk");
        docs.put("performance_monitoring_program", "Program pemantauan prestasi produk / track record 5 tahun");
        return docs;
    }

    private String buildApplicationSummary(HttpServletRequest request) {
        return "Jenis Permohonan: " + trim(request.getParameter("application_type"))
                + "\nJenama: " + trim(request.getParameter("brand"))
                + "\nStandard: " + trim(request.getParameter("standard_name"))
                + "\nNo. Lesen Persijilan: " + trim(request.getParameter("certification_license"))
                + "\nNo. Laporan Ujian: " + trim(request.getParameter("test_report_reference"))
                + "\nPerihal Produk: " + trim(request.getParameter("product_description"));
    }

    private String extractSubmittedFileName(Part part) {
        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.isBlank()) {
            return "document.pdf";
        }
        return Path.of(submitted).getFileName().toString();
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private Date parseDate(String value) {
        String trimmed = trim(value);
        if (trimmed.isEmpty()) {
            return null;
        }
        return Date.valueOf(trimmed);
    }

    private java.math.BigDecimal parseDecimal(String value) {
        String trimmed = trim(value);
        if (trimmed.isEmpty()) {
            return null;
        }
        return new java.math.BigDecimal(trimmed);
    }
}